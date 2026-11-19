import { useCallback, useEffect, useRef, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AuthChangeEvent, Session, SupabaseClient } from '@supabase/supabase-js';
import { UserProfile } from '../types';
import { authService, AuthServiceInitResult } from '../services/authService';
import { initSupabaseClient } from '../services/supabaseClient';
import { storageService, StoredAuthSession } from '../services/storageService';
import {
  normalizeSupabaseAuthUser,
  NormalizedSupabaseUser,
} from '../services/supabaseCallbackParser';
import {
  CachedSupabaseProfileEntry,
  getSupabaseProfileCacheKey,
  hydrateUserProfileFromSupabaseRow,
  parseCachedSupabaseProfile,
  ReconciledPendingIdentity,
  reconcileProfileForSupabaseSession,
  serializeCachedSupabaseProfile,
  shouldClearProfileOnSupabaseSignOut,
  SupabaseProfileRow,
} from '../services/profileAuthReconciler';

export interface UseSupabaseSyncOptions {
  /** Enable listener once local AsyncStorage hydration has finished. */
  enabled: boolean;
  onInitialized: (init: AuthServiceInitResult) => void;
  onSessionChange: (session: StoredAuthSession | null) => void;
  onProfileChange: (profile: UserProfile | null) => void;
  onPendingIdentityChange: (identity: ReconciledPendingIdentity | null) => void;
  onMetadataSynced?: (syncedAt: string) => void;
  onAuthError?: (message: string) => void;
  onSignedOut: () => void;
  onBootstrapComplete: () => void;
}

export interface UseSupabaseSyncReturn {
  isProfileSyncing: boolean;
  isUsingCachedProfile: boolean;
  cachedBasicUserInfo: NormalizedSupabaseUser | null;
  lastAuthEvent: AuthChangeEvent | null;
  syncSupabaseSession: (sbSession: Session) => Promise<void>;
  refreshProfileFromAuth: () => Promise<void>;
}

interface RemoteProfileFetchResult {
  ok: boolean;
  profile: UserProfile | null;
}

async function readCachedProfileFromAsyncStorage(
  userId: string
): Promise<CachedSupabaseProfileEntry | null> {
  if (!userId) return null;
  try {
    const raw = await AsyncStorage.getItem(getSupabaseProfileCacheKey(userId));
    return parseCachedSupabaseProfile(raw, userId);
  } catch {
    return null;
  }
}

async function writeCachedProfileToAsyncStorage(
  entry: CachedSupabaseProfileEntry
): Promise<void> {
  try {
    await AsyncStorage.setItem(
      getSupabaseProfileCacheKey(entry.userId),
      serializeCachedSupabaseProfile(entry)
    );
  } catch {
    // ignore local AsyncStorage write failures
  }
}

async function removeCachedProfileFromAsyncStorage(
  userId: string
): Promise<void> {
  if (!userId) return;
  try {
    await AsyncStorage.removeItem(getSupabaseProfileCacheKey(userId));
  } catch {
    // ignore local AsyncStorage remove failures
  }
}

async function fetchPublicProfileRow(
  supabase: SupabaseClient | null,
  userId: string
): Promise<RemoteProfileFetchResult> {
  if (!supabase || !userId) {
    return { ok: false, profile: null };
  }
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (error) {
      return { ok: false, profile: null };
    }
    if (!data) {
      return { ok: true, profile: null };
    }
    return {
      ok: true,
      profile: hydrateUserProfileFromSupabaseRow(data as SupabaseProfileRow),
    };
  } catch {
    return { ok: false, profile: null };
  }
}

/**
 * Listens for Supabase authentication changes via `supabase.auth.onAuthStateChange`
 * (`INITIAL_SESSION`, `SIGNED_IN`, `TOKEN_REFRESHED`, `USER_UPDATED`, `SIGNED_OUT`)
 * and Android/iOS OAuth redirect deep links.
 *
 * Uses `@react-native-async-storage/async-storage` as an immediate per-user local
 * cache fallback so the app displays cached profile/basic user info instantly
 * while syncing the authoritative `profiles` row from Supabase (and stays usable offline).
 */
export function useSupabaseSync(
  options: UseSupabaseSyncOptions
): UseSupabaseSyncReturn {
  const {
    enabled,
    onInitialized,
    onSessionChange,
    onProfileChange,
    onPendingIdentityChange,
    onMetadataSynced,
    onAuthError,
    onSignedOut,
    onBootstrapComplete,
  } = options;

  const [isProfileSyncing, setIsProfileSyncing] = useState(false);
  const [isUsingCachedProfile, setIsUsingCachedProfile] = useState(false);
  const [cachedBasicUserInfo, setCachedBasicUserInfo] =
    useState<NormalizedSupabaseUser | null>(null);
  const [lastAuthEvent, setLastAuthEvent] = useState<AuthChangeEvent | null>(
    null
  );

  // Monotonic sequence guard prevents an older slow remote `profiles` fetch
  // from overwriting a newer SIGNED_OUT or account-switch auth event.
  const syncSeqRef = useRef(0);
  const mountedRef = useRef(true);
  const clientRef = useRef<SupabaseClient | null>(null);

  const callbacksRef = useRef({
    onInitialized,
    onSessionChange,
    onProfileChange,
    onPendingIdentityChange,
    onMetadataSynced,
    onAuthError,
    onSignedOut,
    onBootstrapComplete,
  });
  callbacksRef.current = {
    onInitialized,
    onSessionChange,
    onProfileChange,
    onPendingIdentityChange,
    onMetadataSynced,
    onAuthError,
    onSignedOut,
    onBootstrapComplete,
  };

  const syncSupabaseSession = useCallback(async (sbSession: Session) => {
    const seq = ++syncSeqRef.current;
    const normalized = normalizeSupabaseAuthUser(sbSession.user);
    const nextSession: StoredAuthSession = {
      token: sbSession.access_token,
      isGuest: false,
      userId: normalized.id,
      provider: 'google',
      email: normalized.email,
    };

    storageService.setSession(nextSession);
    if (!mountedRef.current || seq !== syncSeqRef.current) return;
    callbacksRef.current.onSessionChange(nextSession);
    setCachedBasicUserInfo(normalized);

    // 1. Hydrate immediately from AsyncStorage cache (per-user key) or local storage
    //    so the app displays basic user info & cached profile while Supabase syncs.
    const asyncCachedEntry = await readCachedProfileFromAsyncStorage(
      normalized.id
    );
    if (!mountedRef.current || seq !== syncSeqRef.current) return;

    const storageLocalProfile = storageService.getProfile();
    const cachedProfileCandidate =
      asyncCachedEntry?.profile ||
      (storageLocalProfile && storageLocalProfile.id === normalized.id
        ? storageLocalProfile
        : null);

    if (cachedProfileCandidate) {
      const optimistic = reconcileProfileForSupabaseSession({
        user: normalized,
        localProfile: cachedProfileCandidate,
        remoteProfile: null,
      });
      if (optimistic.profile) {
        storageService.setProfile(optimistic.profile);
        callbacksRef.current.onProfileChange(optimistic.profile);
        callbacksRef.current.onPendingIdentityChange(null);
        setIsUsingCachedProfile(true);
      }
    } else {
      // Cache basic auth identity immediately so basic user info is persisted offline too
      await writeCachedProfileToAsyncStorage({
        version: 1,
        userId: normalized.id,
        cachedAt: new Date().toISOString(),
        basicUserInfo: normalized,
        profile: null,
      });
      if (!mountedRef.current || seq !== syncSeqRef.current) return;
      setIsUsingCachedProfile(false);
    }

    // 2. Fetch authoritative `profiles` row from Supabase in background/foreground
    setIsProfileSyncing(true);
    try {
      const supabase =
        clientRef.current || (await initSupabaseClient()).client;
      const remoteResult = await fetchPublicProfileRow(supabase, normalized.id);
      if (!mountedRef.current || seq !== syncSeqRef.current) return;

      // Offline / network fallback: retain AsyncStorage cached profile cleanly
      if (!remoteResult.ok && cachedProfileCandidate) {
        setIsUsingCachedProfile(true);
        return;
      }

      const freshLocal =
        storageService.getProfile() || asyncCachedEntry?.profile || null;
      const reconciled = reconcileProfileForSupabaseSession({
        user: normalized,
        localProfile: freshLocal,
        remoteProfile: remoteResult.profile,
      });

      storageService.setProfile(reconciled.profile);
      callbacksRef.current.onProfileChange(reconciled.profile);
      callbacksRef.current.onPendingIdentityChange(reconciled.pendingIdentity);
      setIsUsingCachedProfile(false);

      const nowIso = new Date().toISOString();
      await writeCachedProfileToAsyncStorage({
        version: 1,
        userId: normalized.id,
        cachedAt: nowIso,
        basicUserInfo: normalized,
        profile: reconciled.profile,
      });

      if (!mountedRef.current || seq !== syncSeqRef.current) return;

      if (reconciled.profile) {
        if (reconciled.shouldSyncBackToSupabase) {
          const syncedAt = await authService.syncProfile(reconciled.profile);
          if (mountedRef.current && seq === syncSeqRef.current && syncedAt) {
            callbacksRef.current.onMetadataSynced?.(syncedAt);
          }
        } else {
          callbacksRef.current.onMetadataSynced?.(
            reconciled.profile.updatedAt || nowIso
          );
        }
      }
    } finally {
      if (mountedRef.current && seq === syncSeqRef.current) {
        setIsProfileSyncing(false);
      }
    }
  }, []);

  const handleSupabaseSignOutEvent = useCallback(() => {
    // Invalidate any in-flight `profiles` fetch so it cannot resurrect signed-out state
    syncSeqRef.current += 1;
    setIsProfileSyncing(false);
    setIsUsingCachedProfile(false);
    setCachedBasicUserInfo(null);

    const curSession = storageService.getSession();
    const curProfile = storageService.getProfile();

    if (shouldClearProfileOnSupabaseSignOut(curSession, curProfile)) {
      const uidToClear = curSession?.userId || curProfile?.id || '';
      if (uidToClear) {
        removeCachedProfileFromAsyncStorage(uidToClear).catch(() => undefined);
      }
      storageService.setSession(null);
      storageService.setProfile(null);
      callbacksRef.current.onSessionChange(null);
      callbacksRef.current.onProfileChange(null);
      callbacksRef.current.onPendingIdentityChange(null);
      callbacksRef.current.onSignedOut();
    }
  }, []);

  const refreshProfileFromAuth = useCallback(async () => {
    const supabase = clientRef.current || (await initSupabaseClient()).client;
    if (!supabase) return;
    const { data } = await supabase.auth.getSession();
    if (data.session) {
      await syncSupabaseSession(data.session);
    }
  }, [syncSupabaseSession]);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  useEffect(() => {
    if (!enabled) return;

    let authUnsubscribe: (() => void) | null = null;
    let deepLinkUnsubscribe: (() => void) | null = null;
    let active = true;

    (async () => {
      const [authInit, { client: supabase }] = await Promise.all([
        authService.initialize(),
        initSupabaseClient(),
      ]);
      if (!active || !mountedRef.current) return;

      clientRef.current = supabase;
      callbacksRef.current.onInitialized(authInit);

      // 1. Consume pending OAuth redirect on startup (Web URL or Android cold-start deep link)
      const pendingOAuthResult = await authService.consumePendingOAuthRedirect();
      if (!active || !mountedRef.current) return;

      if (pendingOAuthResult?.ok && pendingOAuthResult.session) {
        setLastAuthEvent('SIGNED_IN');
        await syncSupabaseSession(pendingOAuthResult.session);
      } else {
        if (
          pendingOAuthResult &&
          !pendingOAuthResult.ok &&
          pendingOAuthResult.error
        ) {
          callbacksRef.current.onAuthError?.(pendingOAuthResult.error);
        }
        if (supabase) {
          try {
            const { data } = await supabase.auth.getSession();
            if (active && mountedRef.current && data.session) {
              setLastAuthEvent('INITIAL_SESSION');
              await syncSupabaseSession(data.session);
            }
          } catch {
            // ignore initial session check errors
          }
        }
      }

      if (!active || !mountedRef.current) return;

      // 2. Listen directly to `supabase.auth.onAuthStateChange` and sync `profiles` row
      if (supabase) {
        const { data: listener } = supabase.auth.onAuthStateChange(
          (event, sbSession) => {
            if (!active || !mountedRef.current) return;
            setLastAuthEvent(event);

            if (event === 'SIGNED_OUT') {
              handleSupabaseSignOutEvent();
              return;
            }

            if (
              sbSession &&
              (event === 'INITIAL_SESSION' ||
                event === 'SIGNED_IN' ||
                event === 'TOKEN_REFRESHED' ||
                event === 'USER_UPDATED')
            ) {
              syncSupabaseSession(sbSession).catch(() => undefined);
            }
          }
        );
        authUnsubscribe = () => listener.subscription.unsubscribe();
      }

      // 3. Watch warm-start Android / iOS deep-link OAuth callbacks
      deepLinkUnsubscribe = authService.subscribeNativeOAuthDeepLinks(
        (result) => {
          if (!active || !mountedRef.current) return;
          if (result.ok && result.session) {
            setLastAuthEvent('SIGNED_IN');
            syncSupabaseSession(result.session).catch(() => undefined);
          } else if (!result.ok && result.error) {
            callbacksRef.current.onAuthError?.(result.error);
          }
        }
      );

      callbacksRef.current.onBootstrapComplete();
    })();

    return () => {
      active = false;
      if (authUnsubscribe) authUnsubscribe();
      if (deepLinkUnsubscribe) deepLinkUnsubscribe();
    };
  }, [enabled, handleSupabaseSignOutEvent, syncSupabaseSession]);

  return {
    isProfileSyncing,
    isUsingCachedProfile,
    cachedBasicUserInfo,
    lastAuthEvent,
    syncSupabaseSession,
    refreshProfileFromAuth,
  };
}

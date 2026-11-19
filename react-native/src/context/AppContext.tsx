import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import { AuthChangeEvent } from '@supabase/supabase-js';
import {
  ActiveRoute,
  AppLanguage,
  AppNotification,
  MainTab,
  ThemeMode,
  UserProfile,
  UserProfileMetadataSummary,
} from '../types';
import { AppStrings, getAppStrings } from '../localization/appStrings';
import { storageService, StoredAuthSession } from '../services/storageService';
import { AppPalette, getPalette } from '../theme/colors';
import { GoogleOAuthResult } from '../services/supabaseClient';
import { authService, AuthServiceInitResult } from '../services/authService';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  ANDROID_OAUTH_CREDENTIALS,
  NormalizedSupabaseUser,
} from '../services/supabaseCallbackParser';
import {
  buildUserMetadataSummary,
  getSupabaseProfileCacheKey,
  normalizeProfileMetadata,
  ReconciledPendingIdentity,
  serializeCachedSupabaseProfile,
} from '../services/profileAuthReconciler';
import { useSupabaseSync } from '../hooks/useSupabaseSync';

export type PendingIdentity = ReconciledPendingIdentity;

export type UserMetadataPatch = Partial<
  Pick<
    UserProfile,
    | 'preferredUniversityTrack'
    | 'currentAcademicLevel'
    | 'academicBatch'
    | 'institutionName'
    | 'medium'
    | 'nctbVersion'
    | 'englishCurriculum'
    | 'targetSelections'
    | 'preferredLanguage'
    | 'preferredTheme'
  >
>;

interface AppContextValue {
  hydrated: boolean;
  theme: ThemeMode;
  isDark: boolean;
  palette: AppPalette;
  toggleTheme: () => void;
  language: AppLanguage;
  setLanguage: (lang: AppLanguage) => void;
  strings: AppStrings;

  isAuthenticated: boolean;
  isGuest: boolean;
  authProvider: 'google' | 'phone' | 'guest' | null;
  supabaseConfigured: boolean;
  supabaseCallbackUrl: string;
  googleAndroidClientId: string;
  isGoogleAuthLoading: boolean;
  isProfileSyncing: boolean;
  isUsingCachedProfile: boolean;
  cachedBasicUserInfo: NormalizedSupabaseUser | null;
  lastAuthEvent: AuthChangeEvent | null;
  profileLastSyncedAt: string | null;
  authCallbackError: string | null;
  clearAuthCallbackError: () => void;
  profile: UserProfile | null;
  userMetadata: UserProfileMetadataSummary | null;
  pendingIdentity: PendingIdentity | null;
  loginAsGuest: () => void;
  loginWithPhone: (name: string, phone: string) => void;
  loginWithGoogle: () => Promise<GoogleOAuthResult>;
  refreshProfileFromAuth: () => Promise<void>;
  updateUserMetadata: (patch: UserMetadataPatch) => Promise<void>;
  completeOnboarding: (profile: UserProfile) => void;
  updateProfile: (profile: UserProfile) => void;
  logout: () => void;
  deleteAccount: () => void;

  activeRoute: ActiveRoute;
  navigate: (route: ActiveRoute) => void;
  goBack: () => void;
  setMainTab: (tab: MainTab) => void;

  notifications: AppNotification[];
  unreadCount: number;
  markNotificationRead: (id: string) => void;
  markAllNotificationsRead: () => void;

  toast: string | null;
  showToast: (msg: string) => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [storageReady, setStorageReady] = useState(false);
  const [hydrated, setHydrated] = useState(false);
  const [theme, setTheme] = useState<ThemeMode>('light');
  const [language, setLanguageState] = useState<AppLanguage>('english');
  const [session, setSession] = useState<StoredAuthSession | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [pendingIdentity, setPendingIdentity] = useState<PendingIdentity | null>(null);
  const [profileLastSyncedAt, setProfileLastSyncedAt] = useState<string | null>(null);
  const [authCallbackError, setAuthCallbackError] = useState<string | null>(null);
  const [supabaseConfigured, setSupabaseConfigured] = useState(false);
  const [supabaseCallbackUrl, setSupabaseCallbackUrl] = useState('/auth/callback');
  const [googleAndroidClientId, setGoogleAndroidClientId] = useState<string>(
    ANDROID_OAUTH_CREDENTIALS.androidClientId
  );
  const [isGoogleAuthLoading, setIsGoogleAuthLoading] = useState(false);
  const [routeStack, setRouteStack] = useState<ActiveRoute[]>([
    { name: 'dashboard', tab: 'home' },
  ]);
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    setTimeout(() => {
      setToast((prev) => (prev === msg ? null : prev));
    }, 2800);
  }, []);

  // Step 1: Hydrate local AsyncStorage cache before attaching Supabase auth listeners
  useEffect(() => {
    let mounted = true;
    storageService.hydrate().then(() => {
      if (!mounted) return;
      setTheme(storageService.getTheme());
      setLanguageState(storageService.getLanguage());
      setNotifications(storageService.getNotifications());
      setStorageReady(true);
    });
    return () => {
      mounted = false;
    };
  }, []);

  const handleAuthInitialized = useCallback((init: AuthServiceInitResult) => {
    setSupabaseConfigured(init.configured);
    setSupabaseCallbackUrl(init.redirectUri);
    setGoogleAndroidClientId(init.androidCredentials.androidClientId);
  }, []);

  const handleSyncedProfileChange = useCallback((nextProfile: UserProfile | null) => {
    if (!nextProfile) {
      setProfile(null);
      return;
    }
    const normalized = normalizeProfileMetadata(nextProfile);
    setProfile(normalized);

    // Apply user's synced Supabase language & theme preferences automatically
    if (normalized.preferredTheme) {
      setTheme(normalized.preferredTheme);
      storageService.setTheme(normalized.preferredTheme);
    }
    if (normalized.preferredLanguage) {
      setLanguageState(normalized.preferredLanguage);
      storageService.setLanguage(normalized.preferredLanguage);
    }
  }, []);

  const handleSupabaseSignedOut = useCallback(() => {
    setProfileLastSyncedAt(null);
    setRouteStack([{ name: 'dashboard', tab: 'home' }]);
  }, []);

  const handleBootstrapComplete = useCallback(() => {
    let currentSession = storageService.getSession();
    let currentProfile = storageService.getProfile();

    const isAutostart =
      typeof window !== 'undefined' &&
      window.location &&
      window.location.search.includes('autostart=1');

    if (isAutostart && (!currentSession || !currentProfile)) {
      currentSession = {
        token: `guest-token-${Date.now()}`,
        isGuest: true,
        userId: 'guest_preview_01',
        provider: 'guest',
      };
      storageService.setSession(currentSession);
      currentProfile = normalizeProfileMetadata({
        id: 'guest_preview_01',
        name: 'Tanvir Ahmed',
        phone: '01712345678',
        authProvider: 'guest',
        gender: 'male',
        divisionId: 'dhaka',
        divisionName: 'Dhaka',
        districtId: 'dhaka_dist',
        districtName: 'Dhaka',
        sscGroup: 'Science',
        sscYear: '2023',
        sscGpa: '5.00',
        sscInstitution: 'Notre Dame College, Dhaka',
        hscGroup: 'Science',
        hscBatch: "HSC '25",
        hscGpa: '5.00',
        hscInstitution: 'Notre Dame College, Dhaka',
        medium: 'bangla',
        nctbVersion: 'bangla',
        academicBatch: "HSC '25",
        institutionName: 'Notre Dame College, Dhaka',
        studyStreakDays: 0,
        targetSelections: {
          nsu: ['nsu_cse'],
          brac: ['brac_cse'],
          ewu: ['ewu_cse'],
          uiu: ['uiu_cse'],
          aiub: ['aiub_cse'],
          aust: ['aust_eng'],
          uap: ['uap_cse'],
        },
      });
      storageService.setProfile(currentProfile);
    }

    setSession(currentSession);
    setProfile(currentProfile ? normalizeProfileMetadata(currentProfile) : null);
    setHydrated(true);
  }, []);

  const clearAuthCallbackError = useCallback(() => {
    setAuthCallbackError(null);
  }, []);

  const handleAuthError = useCallback((message: string) => {
    setAuthCallbackError(message);
  }, []);

  // Step 2: Listen to supabase.auth.onAuthStateChange & sync full metadata from `profiles`
  const {
    isProfileSyncing,
    isUsingCachedProfile,
    cachedBasicUserInfo,
    lastAuthEvent,
    syncSupabaseSession,
    refreshProfileFromAuth,
  } = useSupabaseSync({
    enabled: storageReady,
    onInitialized: handleAuthInitialized,
    onSessionChange: setSession,
    onProfileChange: handleSyncedProfileChange,
    onPendingIdentityChange: setPendingIdentity,
    onMetadataSynced: setProfileLastSyncedAt,
    onAuthError: handleAuthError,
    onSignedOut: handleSupabaseSignedOut,
    onBootstrapComplete: handleBootstrapComplete,
  });

  const persistAndSyncProfile = useCallback(async (nextProfile: UserProfile) => {
    const nowIso = new Date().toISOString();
    const normalized = normalizeProfileMetadata({
      ...nextProfile,
      updatedAt: nowIso,
    });
    storageService.setProfile(normalized);
    setProfile(normalized);

    if (normalized.authProvider === 'google' && normalized.id) {
      AsyncStorage.setItem(
        getSupabaseProfileCacheKey(normalized.id),
        serializeCachedSupabaseProfile({
          version: 1,
          userId: normalized.id,
          cachedAt: nowIso,
          basicUserInfo: {
            id: normalized.id,
            email: normalized.email || '',
            name: normalized.name,
            avatarUrl: normalized.avatarUrl,
            provider: 'google',
          },
          profile: normalized,
        })
      ).catch(() => undefined);
    }

    const syncedAt = await authService.syncProfile(normalized);
    if (syncedAt) {
      setProfileLastSyncedAt(syncedAt);
    }
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme((prev) => {
      const next: ThemeMode = prev === 'dark' ? 'light' : 'dark';
      storageService.setTheme(next);
      const curProfile = storageService.getProfile();
      if (curProfile) {
        persistAndSyncProfile({ ...curProfile, preferredTheme: next }).catch(
          () => undefined
        );
      }
      return next;
    });
  }, [persistAndSyncProfile]);

  const setLanguage = useCallback(
    (lang: AppLanguage) => {
      setLanguageState(lang);
      storageService.setLanguage(lang);
      const curProfile = storageService.getProfile();
      if (curProfile) {
        persistAndSyncProfile({ ...curProfile, preferredLanguage: lang }).catch(
          () => undefined
        );
      }
      showToast(getAppStrings(lang).languageUpdated);
    },
    [persistAndSyncProfile, showToast]
  );

  const loginAsGuest = useCallback(() => {
    const guestSession: StoredAuthSession = {
      token: `guest-token-${Date.now()}`,
      isGuest: true,
      userId: 'guest_preview_01',
      provider: 'guest',
    };
    storageService.setSession(guestSession);
    setSession(guestSession);

    const existingProfile = storageService.getProfile();
    if (!existingProfile || existingProfile.id !== 'guest_preview_01') {
      const demoProfile = normalizeProfileMetadata({
        id: 'guest_preview_01',
        name: 'Tanvir Ahmed',
        phone: '01712345678',
        authProvider: 'guest',
        gender: 'male',
        divisionId: 'dhaka',
        divisionName: 'Dhaka',
        districtId: 'dhaka_dist',
        districtName: 'Dhaka',
        sscGroup: 'Science',
        sscYear: '2023',
        sscGpa: '5.00',
        sscInstitution: 'Notre Dame College, Dhaka',
        hscGroup: 'Science',
        hscBatch: "HSC '25",
        hscGpa: '5.00',
        hscInstitution: 'Notre Dame College, Dhaka',
        medium: 'bangla',
        nctbVersion: 'bangla',
        academicBatch: "HSC '25",
        institutionName: 'Notre Dame College, Dhaka',
        studyStreakDays: 0,
        targetSelections: {
          nsu: ['nsu_cse'],
          brac: ['brac_cse'],
          ewu: ['ewu_cse'],
          uiu: ['uiu_cse'],
          aiub: ['aiub_cse'],
          aust: ['aust_eng'],
          uap: ['uap_cse'],
        },
      });
      storageService.setProfile(demoProfile);
      setProfile(demoProfile);
    } else {
      setProfile(normalizeProfileMetadata(existingProfile));
    }
    setPendingIdentity(null);
    setRouteStack([{ name: 'dashboard', tab: 'home' }]);
  }, []);

  const loginWithPhone = useCallback((name: string, phone: string) => {
    const userId = `usr_${phone.replace(/\D/g, '') || Date.now()}`;
    const newSession: StoredAuthSession = {
      token: `otp-token-${Date.now()}`,
      isGuest: false,
      userId,
      provider: 'phone',
    };
    storageService.setSession(newSession);
    setSession(newSession);

    const existing = storageService.getProfile();
    if (existing && existing.id === userId) {
      setProfile(normalizeProfileMetadata(existing));
    } else {
      setPendingIdentity({
        userId,
        name: name.trim() || 'Candidate',
        phone: phone.trim(),
        authProvider: 'phone',
      });
      setProfile(null);
      storageService.setProfile(null);
    }
    setRouteStack([{ name: 'dashboard', tab: 'home' }]);
  }, []);

  const loginWithGoogle = useCallback(async (): Promise<GoogleOAuthResult> => {
    setAuthCallbackError(null);
    setIsGoogleAuthLoading(true);
    try {
      const result = await authService.signInWithGoogle();
      if (result.ok && result.session) {
        await syncSupabaseSession(result.session);
        setRouteStack([{ name: 'dashboard', tab: 'home' }]);
        showToast(
          result.user?.email
            ? `Signed in with Google (${result.user.email})`
            : 'Signed in with Google'
        );
      }
      return result;
    } finally {
      setIsGoogleAuthLoading(false);
    }
  }, [syncSupabaseSession, showToast]);

  const updateUserMetadata = useCallback(
    async (patch: UserMetadataPatch) => {
      const base = storageService.getProfile() || profile;
      if (!base) return;
      const merged: UserProfile = {
        ...base,
        ...patch,
      };
      if (patch.preferredTheme) {
        setTheme(patch.preferredTheme);
        storageService.setTheme(patch.preferredTheme);
      }
      if (patch.preferredLanguage) {
        setLanguageState(patch.preferredLanguage);
        storageService.setLanguage(patch.preferredLanguage);
      }
      await persistAndSyncProfile(merged);
    },
    [persistAndSyncProfile, profile]
  );

  const completeOnboarding = useCallback(
    (newProfile: UserProfile) => {
      const enriched = normalizeProfileMetadata({
        ...newProfile,
        preferredLanguage: newProfile.preferredLanguage || language,
        preferredTheme: newProfile.preferredTheme || theme,
      });
      setPendingIdentity(null);
      persistAndSyncProfile(enriched).catch(() => undefined);
      setRouteStack([{ name: 'dashboard', tab: 'home' }]);
    },
    [language, persistAndSyncProfile, theme]
  );

  const updateProfile = useCallback(
    (updated: UserProfile) => {
      const enriched = normalizeProfileMetadata({
        ...updated,
        preferredLanguage: updated.preferredLanguage || language,
        preferredTheme: updated.preferredTheme || theme,
      });
      persistAndSyncProfile(enriched).catch(() => undefined);
      showToast('Admission profile updated!');
    },
    [language, persistAndSyncProfile, showToast, theme]
  );

  const logout = useCallback(() => {
    const isGoogleSession = session?.provider === 'google';
    const uidToClear = session?.userId || profile?.id || '';
    authService.signOut().catch(() => undefined);
    storageService.setSession(null);
    if (isGoogleSession) {
      if (uidToClear) {
        AsyncStorage.removeItem(getSupabaseProfileCacheKey(uidToClear)).catch(
          () => undefined
        );
      }
      storageService.setProfile(null);
      setProfile(null);
    }
    setProfileLastSyncedAt(null);
    setSession(null);
    setPendingIdentity(null);
    setRouteStack([{ name: 'dashboard', tab: 'home' }]);
  }, [profile?.id, session?.provider, session?.userId]);

  const deleteAccount = useCallback(() => {
    const uidToClear = session?.userId || profile?.id || '';
    if (uidToClear) {
      AsyncStorage.removeItem(getSupabaseProfileCacheKey(uidToClear)).catch(
        () => undefined
      );
    }
    authService.signOut().catch(() => undefined);
    storageService.clearAllUserData();
    setProfileLastSyncedAt(null);
    setSession(null);
    setProfile(null);
    setPendingIdentity(null);
    setRouteStack([{ name: 'dashboard', tab: 'home' }]);
    showToast('Account data removed from device.');
  }, [profile?.id, session?.userId, showToast]);

  const activeRoute = routeStack[routeStack.length - 1] || { name: 'dashboard', tab: 'home' };

  const navigate = useCallback((route: ActiveRoute) => {
    if (route.name === 'dashboard') {
      setRouteStack([route]);
    } else {
      setRouteStack((prev) => [...prev, route]);
    }
  }, []);

  const goBack = useCallback(() => {
    setRouteStack((prev) =>
      prev.length > 1 ? prev.slice(0, -1) : [{ name: 'dashboard', tab: 'home' }]
    );
  }, []);

  const setMainTab = useCallback((tab: MainTab) => {
    setRouteStack([{ name: 'dashboard', tab }]);
  }, []);

  const markNotificationRead = useCallback((id: string) => {
    setNotifications((prev) => {
      const next = prev.map((n) => (n.id === id ? { ...n, isRead: true } : n));
      storageService.saveNotifications(next);
      return next;
    });
  }, []);

  const markAllNotificationsRead = useCallback(() => {
    setNotifications((prev) => {
      const next = prev.map((n) => ({ ...n, isRead: true }));
      storageService.saveNotifications(next);
      return next;
    });
  }, []);

  const unreadCount = notifications.filter((n) => !n.isRead).length;
  const strings = getAppStrings(language);
  const palette = getPalette(theme);
  const userMetadata = useMemo(
    () => buildUserMetadataSummary(profile, profileLastSyncedAt),
    [profile, profileLastSyncedAt]
  );

  return (
    <AppContext.Provider
      value={{
        hydrated,
        theme,
        isDark: theme === 'dark',
        palette,
        toggleTheme,
        language,
        setLanguage,
        strings,
        isAuthenticated: Boolean(session),
        isGuest: Boolean(session?.isGuest),
        authProvider: session?.provider ?? (session?.isGuest ? 'guest' : null),
        supabaseConfigured,
        supabaseCallbackUrl,
        googleAndroidClientId,
        isGoogleAuthLoading,
        isProfileSyncing,
        isUsingCachedProfile,
        cachedBasicUserInfo,
        lastAuthEvent,
        profileLastSyncedAt,
        authCallbackError,
        clearAuthCallbackError,
        profile,
        userMetadata,
        pendingIdentity,
        loginAsGuest,
        loginWithPhone,
        loginWithGoogle,
        refreshProfileFromAuth,
        updateUserMetadata,
        completeOnboarding,
        updateProfile,
        logout,
        deleteAccount,
        activeRoute,
        navigate,
        goBack,
        setMainTab,
        notifications,
        unreadCount,
        markNotificationRead,
        markAllNotificationsRead,
        toast,
        showToast,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used inside AppProvider');
  return ctx;
}

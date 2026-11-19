import AsyncStorage from '@react-native-async-storage/async-storage';
import { Linking, Platform } from 'react-native';
import { createClient, Session, SupabaseClient } from '@supabase/supabase-js';
import { UserProfile } from '../types';
import {
  ANDROID_OAUTH_CREDENTIALS,
  isMatchingOAuthRedirectUrl,
  normalizeSupabaseAuthUser,
  NormalizedSupabaseUser,
  OAuthCallbackParams,
  parseOAuthCallbackParams,
  parseOAuthCallbackUrl,
} from './supabaseCallbackParser';
import {
  buildSupabaseProfileUpsertPayload,
  hydrateUserProfileFromSupabaseRow,
  SupabaseProfileRow,
} from './profileAuthReconciler';

export interface SupabaseRuntimeConfig {
  configured: boolean;
  supabaseUrl: string;
  supabaseAnonKey: string;
  nativeRedirectUri: string;
  webCallbackUrl: string;
  googleAndroidClientId: string;
  googleWebClientId: string;
}

export interface GoogleOAuthResult {
  ok: boolean;
  session?: Session;
  user?: NormalizedSupabaseUser;
  error?: string;
  notConfigured?: boolean;
  callbackUrl?: string;
}

const DEFAULT_NATIVE_REDIRECT_URI =
  ANDROID_OAUTH_CREDENTIALS.defaultNativeRedirectUri;
const DEFAULT_GOOGLE_ANDROID_CLIENT_ID =
  ANDROID_OAUTH_CREDENTIALS.androidClientId;
const OAUTH_MESSAGE_TYPE = 'PREP404_SUPABASE_OAUTH_CALLBACK';

let cachedClient: SupabaseClient | null = null;
let cachedConfig: SupabaseRuntimeConfig | null = null;
let initPromise: Promise<{
  client: SupabaseClient | null;
  config: SupabaseRuntimeConfig;
}> | null = null;

function getWebOrigin(): string {
  if (typeof window !== 'undefined' && window.location?.origin) {
    return window.location.origin;
  }
  return '';
}

function getBuildTimeEnvConfig(): {
  url: string;
  anonKey: string;
  nativeRedirectUri: string;
  googleAndroidClientId: string;
  googleWebClientId: string;
} {
  const procEnv =
    typeof process !== 'undefined' && process.env ? process.env : {};
  const metaEnv =
    typeof import.meta !== 'undefined' &&
    (import.meta as unknown as { env?: Record<string, string> }).env
      ? (import.meta as unknown as { env: Record<string, string> }).env
      : {};

  const url = String(
    metaEnv.VITE_SUPABASE_URL ||
      metaEnv.SUPABASE_URL ||
      procEnv.VITE_SUPABASE_URL ||
      procEnv.SUPABASE_URL ||
      ''
  ).trim();
  const anonKey = String(
    metaEnv.VITE_SUPABASE_ANON_KEY ||
      metaEnv.SUPABASE_ANON_KEY ||
      procEnv.VITE_SUPABASE_ANON_KEY ||
      procEnv.SUPABASE_ANON_KEY ||
      ''
  ).trim();
  const nativeRedirectUri = String(
    metaEnv.VITE_AUTH_REDIRECT_URI ||
      metaEnv.AUTH_REDIRECT_URI ||
      procEnv.AUTH_REDIRECT_URI ||
      DEFAULT_NATIVE_REDIRECT_URI
  ).trim();
  const googleAndroidClientId = String(
    metaEnv.VITE_GOOGLE_ANDROID_CLIENT_ID ||
      metaEnv.GOOGLE_ANDROID_CLIENT_ID ||
      metaEnv.GOOGLE_CLIENT_ID ||
      procEnv.GOOGLE_ANDROID_CLIENT_ID ||
      procEnv.GOOGLE_CLIENT_ID ||
      DEFAULT_GOOGLE_ANDROID_CLIENT_ID
  ).trim();
  const googleWebClientId = String(
    metaEnv.VITE_GOOGLE_WEB_CLIENT_ID ||
      metaEnv.GOOGLE_WEB_CLIENT_ID ||
      procEnv.GOOGLE_WEB_CLIENT_ID ||
      ''
  ).trim();

  return {
    url,
    anonKey,
    nativeRedirectUri,
    googleAndroidClientId,
    googleWebClientId,
  };
}

const supabaseStorageAdapter = {
  async getItem(key: string): Promise<string | null> {
    if (Platform.OS === 'web' && typeof window !== 'undefined' && window.localStorage) {
      try {
        return window.localStorage.getItem(key);
      } catch {
        // fall through to AsyncStorage
      }
    }
    try {
      return await AsyncStorage.getItem(key);
    } catch {
      return null;
    }
  },
  async setItem(key: string, value: string): Promise<void> {
    if (Platform.OS === 'web' && typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.setItem(key, value);
        return;
      } catch {
        // fall through to AsyncStorage
      }
    }
    try {
      await AsyncStorage.setItem(key, value);
    } catch {
      // ignore storage write failures
    }
  },
  async removeItem(key: string): Promise<void> {
    if (Platform.OS === 'web' && typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.removeItem(key);
        return;
      } catch {
        // fall through to AsyncStorage
      }
    }
    try {
      await AsyncStorage.removeItem(key);
    } catch {
      // ignore storage remove failures
    }
  },
};

export async function initSupabaseClient(): Promise<{
  client: SupabaseClient | null;
  config: SupabaseRuntimeConfig;
}> {
  if (cachedConfig) {
    return { client: cachedClient, config: cachedConfig };
  }
  if (initPromise) return initPromise;

  initPromise = (async () => {
    const buildEnv = getBuildTimeEnvConfig();
    let supabaseUrl = buildEnv.url;
    let supabaseAnonKey = buildEnv.anonKey;
    let nativeRedirectUri = buildEnv.nativeRedirectUri;
    let googleAndroidClientId = buildEnv.googleAndroidClientId;
    let googleWebClientId = buildEnv.googleWebClientId;
    let webCallbackUrl = getWebOrigin()
      ? `${getWebOrigin()}/auth/callback`
      : '/auth/callback';

    if (Platform.OS === 'web' && typeof fetch === 'function') {
      try {
        const resp = await fetch('/api/v1/auth/supabase-config');
        if (resp.ok) {
          const data = (await resp.json()) as {
            supabaseUrl?: string;
            supabaseAnonKey?: string;
            nativeRedirectUri?: string;
            webCallbackUrl?: string;
            googleAndroidClientId?: string;
            googleWebClientId?: string;
          };
          if (data.supabaseUrl) supabaseUrl = data.supabaseUrl.trim();
          if (data.supabaseAnonKey) supabaseAnonKey = data.supabaseAnonKey.trim();
          if (data.nativeRedirectUri) {
            nativeRedirectUri = data.nativeRedirectUri.trim();
          }
          if (data.googleAndroidClientId) {
            googleAndroidClientId = data.googleAndroidClientId.trim();
          }
          if (data.googleWebClientId) {
            googleWebClientId = data.googleWebClientId.trim();
          }
          if (data.webCallbackUrl && !getWebOrigin()) {
            webCallbackUrl = data.webCallbackUrl.trim();
          }
        }
      } catch {
        // Offline or non-gateway environment; rely on build-time env vars
      }
    }

    const configured = Boolean(supabaseUrl && supabaseAnonKey);
    cachedConfig = {
      configured,
      supabaseUrl,
      supabaseAnonKey,
      nativeRedirectUri,
      webCallbackUrl,
      googleAndroidClientId,
      googleWebClientId,
    };

    if (configured) {
      cachedClient = createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          storage: supabaseStorageAdapter,
          autoRefreshToken: true,
          persistSession: true,
          detectSessionInUrl: false,
          flowType: 'pkce',
        },
      });
    } else {
      cachedClient = null;
    }

    return { client: cachedClient, config: cachedConfig };
  })();

  return initPromise;
}

export function getSupabaseClient(): SupabaseClient | null {
  return cachedClient;
}

export function getSupabaseRuntimeConfig(): SupabaseRuntimeConfig | null {
  return cachedConfig;
}

export async function signInWithGoogleIdToken(
  idToken: string,
  nonce?: string
): Promise<GoogleOAuthResult> {
  const { client, config } = await initSupabaseClient();
  if (!client || !config.configured) {
    return {
      ok: false,
      notConfigured: true,
      callbackUrl: config.nativeRedirectUri,
      error:
        'Set SUPABASE_URL and SUPABASE_ANON_KEY to verify native Google ID tokens with Supabase.',
    };
  }

  const { data, error } = await client.auth.signInWithIdToken({
    provider: 'google',
    token: idToken,
    nonce,
  });

  if (error || !data.session || !data.user) {
    return {
      ok: false,
      error: error?.message || 'Supabase could not verify the Google ID token.',
    };
  }

  return {
    ok: true,
    session: data.session,
    user: normalizeSupabaseAuthUser(data.user),
  };
}

const inflightCodeExchanges = new Map<string, Promise<GoogleOAuthResult>>();

export async function completeOAuthSessionFromParams(
  client: SupabaseClient,
  params: OAuthCallbackParams
): Promise<GoogleOAuthResult> {
  if (params.error) {
    return {
      ok: false,
      error: params.errorDescription || params.error,
    };
  }

  if (params.code) {
    const existing = inflightCodeExchanges.get(params.code);
    if (existing) return existing;

    const exchangePromise = (async (): Promise<GoogleOAuthResult> => {
      const { data, error } = await client.auth.exchangeCodeForSession(
        params.code!
      );
      if (error || !data.session || !data.user) {
        return {
          ok: false,
          error:
            error?.message ||
            'Could not exchange Google OAuth code with Supabase.',
        };
      }
      return {
        ok: true,
        session: data.session,
        user: normalizeSupabaseAuthUser(data.user),
      };
    })();

    inflightCodeExchanges.set(params.code, exchangePromise);
    // Keep settled result briefly to absorb duplicate deep-link/message deliveries
    setTimeout(() => {
      inflightCodeExchanges.delete(params.code!);
    }, 30_000);

    return exchangePromise;
  }

  if (params.accessToken && params.refreshToken) {
    const { data, error } = await client.auth.setSession({
      access_token: params.accessToken,
      refresh_token: params.refreshToken,
    });
    if (error || !data.session || !data.user) {
      return {
        ok: false,
        error:
          error?.message ||
          'Could not establish Supabase session from Google tokens.',
      };
    }
    return {
      ok: true,
      session: data.session,
      user: normalizeSupabaseAuthUser(data.user),
    };
  }

  return {
    ok: false,
    error:
      'Google OAuth callback did not return an authorization code or session token.',
  };
}

export async function consumePendingWebOAuthUrl(): Promise<GoogleOAuthResult | null> {
  if (Platform.OS !== 'web' || typeof window === 'undefined') return null;
  const params = parseOAuthCallbackParams(
    window.location.search,
    window.location.hash
  );
  if (!params.code && !params.accessToken && !params.error) return null;

  const { client } = await initSupabaseClient();
  if (!client) return null;

  const result = await completeOAuthSessionFromParams(client, params);
  try {
    const cleanPath =
      window.location.pathname === '/auth/callback' ||
      window.location.pathname === '/auth/callback/'
        ? '/'
        : window.location.pathname;
    const cleanUrl = `${window.location.origin}${cleanPath}`;
    window.history.replaceState({}, document.title, cleanUrl);
  } catch {
    // ignore history replace errors
  }
  return result;
}

export async function signInWithGoogleOAuth(): Promise<GoogleOAuthResult> {
  const { client, config } = await initSupabaseClient();
  const callbackUrl =
    Platform.OS === 'web' ? config.webCallbackUrl : config.nativeRedirectUri;

  if (!client || !config.configured) {
    return {
      ok: false,
      notConfigured: true,
      callbackUrl,
      error:
        'Set SUPABASE_URL and SUPABASE_ANON_KEY in your environment variables to enable live Google Sign-In via Supabase.',
    };
  }

  const { data, error } = await client.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: callbackUrl,
      skipBrowserRedirect: true,
      queryParams: {
        access_type: 'offline',
        prompt: 'select_account',
      },
    },
  });

  if (error || !data?.url) {
    return {
      ok: false,
      error: error?.message || 'Supabase failed to initialize Google OAuth.',
    };
  }

  // Web / AI Studio iframe preview: open Supabase -> Google OAuth directly in a popup window
  if (Platform.OS === 'web' && typeof window !== 'undefined') {
    return new Promise<GoogleOAuthResult>((resolve) => {
      const width = 520;
      const height = 660;
      const left = Math.max(0, Math.round(window.screenX + (window.outerWidth - width) / 2));
      const top = Math.max(0, Math.round(window.screenY + (window.outerHeight - height) / 2));

      const popup = window.open(
        data.url,
        'prep404_google_oauth',
        `width=${width},height=${height},left=${left},top=${top},noopener=no,noreferrer=no`
      );

      if (!popup) {
        resolve({
          ok: false,
          error: 'Popup was blocked by your browser. Allow popups for this site and try Google Sign-In again.',
        });
        return;
      }

      let settled = false;
      const cleanup = () => {
        window.removeEventListener('message', handleMessage);
        clearInterval(closePollTimer);
        clearTimeout(timeoutTimer);
      };

      const finish = (result: GoogleOAuthResult) => {
        if (settled) return;
        settled = true;
        cleanup();
        resolve(result);
      };

      const handleMessage = async (event: MessageEvent) => {
        if (!event.data || event.data.type !== OAUTH_MESSAGE_TYPE) return;
        const allowedOrigin = window.location.origin;
        if (
          event.origin !== allowedOrigin &&
          !event.origin.endsWith('.run.app') &&
          !event.origin.includes('localhost')
        ) {
          return;
        }

        const params: OAuthCallbackParams = {
          code: typeof event.data.code === 'string' ? event.data.code : undefined,
          accessToken:
            typeof event.data.accessToken === 'string'
              ? event.data.accessToken
              : undefined,
          refreshToken:
            typeof event.data.refreshToken === 'string'
              ? event.data.refreshToken
              : undefined,
          error: typeof event.data.error === 'string' ? event.data.error : undefined,
          errorDescription:
            typeof event.data.errorDescription === 'string'
              ? event.data.errorDescription
              : undefined,
        };

        try {
          popup.close();
        } catch {
          // ignore cross-window close errors
        }

        const result = await completeOAuthSessionFromParams(client, params);
        finish(result);
      };

      const closePollTimer = setInterval(() => {
        if (popup.closed) {
          setTimeout(() => {
            if (!settled) {
              finish({
                ok: false,
                error: 'Google sign-in window was closed before completing authentication.',
              });
            }
          }, 450);
        }
      }, 400);

      const timeoutTimer = setTimeout(() => {
        if (!settled) {
          try {
            popup.close();
          } catch {
            // ignore
          }
          finish({
            ok: false,
            error: 'Google sign-in timed out. Please try again.',
          });
        }
      }, 180_000);

      window.addEventListener('message', handleMessage);
    });
  }

  // Native Android / iOS: open system browser and listen for deep link callback
  return new Promise<GoogleOAuthResult>((resolve) => {
    let settled = false;
    const subscription = Linking.addEventListener('url', async ({ url }) => {
      if (settled) return;
      if (!isMatchingOAuthRedirectUrl(url, config.nativeRedirectUri)) return;
      settled = true;
      subscription.remove();
      clearTimeout(timeoutTimer);
      const params = parseOAuthCallbackUrl(url);
      const result = await completeOAuthSessionFromParams(client, params);
      resolve(result);
    });

    const timeoutTimer = setTimeout(() => {
      if (settled) return;
      settled = true;
      subscription.remove();
      resolve({
        ok: false,
        error: 'Google sign-in timed out waiting for app redirect.',
      });
    }, 180_000);

    Linking.openURL(data.url).catch((err) => {
      if (settled) return;
      settled = true;
      subscription.remove();
      clearTimeout(timeoutTimer);
      resolve({
        ok: false,
        error: err instanceof Error ? err.message : 'Unable to open Google sign-in browser.',
      });
    });
  });
}

export async function signOutSupabase(): Promise<void> {
  const client = cachedClient;
  if (!client) return;
  try {
    await client.auth.signOut();
  } catch {
    // ignore sign-out network errors
  }
}

export async function fetchProfileFromSupabase(
  userId: string
): Promise<UserProfile | null> {
  const client = cachedClient;
  if (!client || !userId) return null;
  try {
    const { data, error } = await client
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (error || !data) return null;
    return hydrateUserProfileFromSupabaseRow(data as SupabaseProfileRow);
  } catch {
    return null;
  }
}

export async function syncProfileToSupabase(
  profile: UserProfile
): Promise<string | null> {
  const client = cachedClient;
  if (!client || !profile.id) return null;
  try {
    const { data: sessionData } = await client.auth.getSession();
    const authUid = sessionData.session?.user?.id;
    if (!authUid || authUid !== profile.id) return null;

    const fullPayload = buildSupabaseProfileUpsertPayload(
      authUid,
      profile,
      sessionData.session?.user?.email
    );

    const { error } = await client
      .from('profiles')
      .upsert(fullPayload, { onConflict: 'id' });

    if (!error) {
      return String(fullPayload.updated_at);
    }

    // Fallback for projects running the initial core schema before ALTER TABLE columns
    const fallbackNow = new Date().toISOString();
    const { error: fallbackError } = await client.from('profiles').upsert(
      {
        id: authUid,
        email: fullPayload.email,
        full_name: fullPayload.full_name,
        phone: fullPayload.phone,
        avatar_url: fullPayload.avatar_url,
        target_selections: fullPayload.target_selections,
        profile_json: fullPayload.profile_json,
        updated_at: fallbackNow,
      },
      { onConflict: 'id' }
    );

    return fallbackError ? null : fallbackNow;
  } catch {
    // Graceful no-op if the Supabase `profiles` table has not been migrated yet
    return null;
  }
}

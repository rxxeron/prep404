import { Linking, Platform } from 'react-native';
import { AuthChangeEvent, Session } from '@supabase/supabase-js';
import { UserProfile } from '../types';
import {
  completeOAuthSessionFromParams,
  consumePendingWebOAuthUrl,
  fetchProfileFromSupabase,
  getSupabaseClient,
  GoogleOAuthResult,
  initSupabaseClient,
  signInWithGoogleIdToken as supabaseSignInWithGoogleIdToken,
  signInWithGoogleOAuth,
  signOutSupabase,
  SupabaseRuntimeConfig,
  syncProfileToSupabase,
} from './supabaseClient';
import {
  ANDROID_OAUTH_CREDENTIALS,
  isMatchingOAuthRedirectUrl,
  normalizeSupabaseAuthUser,
  NormalizedSupabaseUser,
  parseOAuthCallbackUrl,
  resolvePlatformRedirectUri,
} from './supabaseCallbackParser';

export interface AuthServiceInitResult {
  configured: boolean;
  provider: 'supabase';
  config: SupabaseRuntimeConfig;
  redirectUri: string;
  androidCredentials: {
    androidClientId: string;
    packageName: string;
    redirectScheme: string;
    redirectHost: string;
    redirectUri: string;
  };
}

export interface AuthSessionSnapshot {
  session: Session;
  user: NormalizedSupabaseUser;
}

/**
 * Prep404 Authentication Service (Supabase Auth — zero Firebase Auth dependency).
 *
 * Handles:
 * - Android OAuth credentials (`560610133772-03ij6u6cqo2pk1t2tbjvmpqrl79md609.apps.googleusercontent.com`)
 * - Android / iOS deep-link OAuth redirect (`com.rxxxeron.prep404://login-callback`)
 *   including cold-start (`Linking.getInitialURL()`) and warm-start (`Linking.addEventListener('url')`)
 * - Native Android Google Sign-In ID token exchange (`supabase.auth.signInWithIdToken`)
 * - Web / iframe preview popup OAuth + `/auth/callback` PKCE handoff
 */
export const authService = {
  async initialize(): Promise<AuthServiceInitResult> {
    const { config } = await initSupabaseClient();
    const webOrigin =
      Platform.OS === 'web' && typeof window !== 'undefined'
        ? window.location.origin
        : undefined;
    const redirectUri = resolvePlatformRedirectUri({
      platformOS: Platform.OS,
      webOrigin,
      nativeRedirectUri: config.nativeRedirectUri,
    });

    return {
      configured: config.configured,
      provider: 'supabase',
      config,
      redirectUri,
      androidCredentials: {
        androidClientId:
          config.googleAndroidClientId ||
          ANDROID_OAUTH_CREDENTIALS.androidClientId,
        packageName: ANDROID_OAUTH_CREDENTIALS.packageName,
        redirectScheme: ANDROID_OAUTH_CREDENTIALS.redirectScheme,
        redirectHost: ANDROID_OAUTH_CREDENTIALS.redirectHost,
        redirectUri: config.nativeRedirectUri,
      },
    };
  },

  async getActiveSession(): Promise<AuthSessionSnapshot | null> {
    const { client } = await initSupabaseClient();
    if (!client) return null;
    try {
      const { data, error } = await client.auth.getSession();
      if (error || !data.session?.user) return null;
      return {
        session: data.session,
        user: normalizeSupabaseAuthUser(data.session.user),
      };
    } catch {
      return null;
    }
  },

  /**
   * Consumes any pending OAuth redirect on app startup:
   * - Web: `?code=` or `#access_token=` in the current window URL
   * - Android / iOS: cold-start deep link via `Linking.getInitialURL()`
   */
  async consumePendingOAuthRedirect(): Promise<GoogleOAuthResult | null> {
    if (Platform.OS === 'web') {
      return consumePendingWebOAuthUrl();
    }

    try {
      const initialUrl = await Linking.getInitialURL();
      if (!initialUrl) return null;
      return this.handleNativeRedirectUrl(initialUrl);
    } catch {
      return null;
    }
  },

  async handleOAuthCallbackUrl(
    incomingUrl: string
  ): Promise<GoogleOAuthResult | null> {
    const { client, config } = await initSupabaseClient();
    if (!client || !config.configured) return null;

    const expectedUri =
      Platform.OS === 'web' ? config.webCallbackUrl : config.nativeRedirectUri;
    const matchesExpected =
      isMatchingOAuthRedirectUrl(incomingUrl, expectedUri) ||
      isMatchingOAuthRedirectUrl(incomingUrl, config.nativeRedirectUri);
    if (!matchesExpected) {
      return null;
    }

    const params = parseOAuthCallbackUrl(incomingUrl);
    if (!params.code && !params.accessToken && !params.error) {
      return null;
    }
    return completeOAuthSessionFromParams(client, params);
  },

  async handleNativeRedirectUrl(
    incomingUrl: string
  ): Promise<GoogleOAuthResult | null> {
    return this.handleOAuthCallbackUrl(incomingUrl);
  },

  /**
   * Subscribes to warm-start Android/iOS deep-link OAuth callbacks
   * (`com.rxxxeron.prep404://login-callback?code=...`).
   */
  subscribeNativeOAuthDeepLinks(
    onResult: (result: GoogleOAuthResult) => void
  ): () => void {
    if (Platform.OS === 'web') {
      return () => undefined;
    }
    const sub = Linking.addEventListener('url', async ({ url }) => {
      const result = await this.handleNativeRedirectUrl(url);
      if (result) {
        onResult(result);
      }
    });
    return () => sub.remove();
  },

  subscribeAuthState(
    listener: (event: AuthChangeEvent, session: Session | null) => void
  ): () => void {
    const client = getSupabaseClient();
    if (!client) return () => undefined;
    const { data } = client.auth.onAuthStateChange((event, session) => {
      listener(event, session);
    });
    return () => data.subscription.unsubscribe();
  },

  async signInWithGoogle(): Promise<GoogleOAuthResult> {
    return signInWithGoogleOAuth();
  },

  async signInWithGoogleIdToken(
    idToken: string,
    nonce?: string
  ): Promise<GoogleOAuthResult> {
    return supabaseSignInWithGoogleIdToken(idToken, nonce);
  },

  async signOut(): Promise<void> {
    return signOutSupabase();
  },

  async fetchProfile(userId: string): Promise<UserProfile | null> {
    return fetchProfileFromSupabase(userId);
  },

  async syncProfile(profile: UserProfile): Promise<string | null> {
    return syncProfileToSupabase(profile);
  },
};

export interface OAuthCallbackParams {
  code?: string;
  accessToken?: string;
  refreshToken?: string;
  error?: string;
  errorDescription?: string;
}

export interface NormalizedSupabaseUser {
  id: string;
  email: string;
  name: string;
  avatarUrl?: string;
  provider: 'google' | 'oauth';
}

function parseQueryString(raw: string): Record<string, string> {
  const cleaned = raw.replace(/^[?#]/, '').trim();
  if (!cleaned) return {};
  const result: Record<string, string> = {};
  for (const part of cleaned.split('&')) {
    if (!part) continue;
    const eqIdx = part.indexOf('=');
    const key = eqIdx >= 0 ? part.slice(0, eqIdx) : part;
    const val = eqIdx >= 0 ? part.slice(eqIdx + 1) : '';
    try {
      const decodedKey = decodeURIComponent(key.replace(/\+/g, ' '));
      const decodedVal = decodeURIComponent(val.replace(/\+/g, ' '));
      result[decodedKey] = decodedVal;
    } catch {
      result[key] = val;
    }
  }
  return result;
}

export function parseOAuthCallbackParams(
  search: string = '',
  hash: string = ''
): OAuthCallbackParams {
  const searchParams = parseQueryString(search);
  const hashParams = parseQueryString(hash);

  const code = searchParams.code || hashParams.code || undefined;
  const accessToken =
    hashParams.access_token || searchParams.access_token || undefined;
  const refreshToken =
    hashParams.refresh_token || searchParams.refresh_token || undefined;
  const error = searchParams.error || hashParams.error || undefined;
  const errorDescription =
    searchParams.error_description ||
    hashParams.error_description ||
    undefined;

  return {
    code,
    accessToken,
    refreshToken,
    error,
    errorDescription,
  };
}

export function parseOAuthCallbackUrl(fullUrl: string): OAuthCallbackParams {
  if (!fullUrl) return {};
  const hashIdx = fullUrl.indexOf('#');
  const withoutHash = hashIdx >= 0 ? fullUrl.slice(0, hashIdx) : fullUrl;
  const hash = hashIdx >= 0 ? fullUrl.slice(hashIdx + 1) : '';

  const queryIdx = withoutHash.indexOf('?');
  const search = queryIdx >= 0 ? withoutHash.slice(queryIdx + 1) : '';

  return parseOAuthCallbackParams(search, hash);
}

export function normalizeSupabaseAuthUser(user: {
  id: string;
  email?: string | null;
  user_metadata?: Record<string, unknown> | null;
  app_metadata?: Record<string, unknown> | null;
}): NormalizedSupabaseUser {
  const meta = user.user_metadata || {};
  const appMeta = user.app_metadata || {};
  const fullName =
    (typeof meta.full_name === 'string' && meta.full_name.trim()) ||
    (typeof meta.name === 'string' && meta.name.trim()) ||
    (user.email ? user.email.split('@')[0] : 'Candidate');
  const avatarUrl =
    (typeof meta.avatar_url === 'string' && meta.avatar_url.trim()) ||
    (typeof meta.picture === 'string' && meta.picture.trim()) ||
    undefined;
  const rawProvider =
    typeof appMeta.provider === 'string' ? appMeta.provider.toLowerCase() : '';

  return {
    id: user.id,
    email: user.email || '',
    name: fullName,
    avatarUrl,
    provider: rawProvider === 'google' ? 'google' : 'oauth',
  };
}

export const ANDROID_OAUTH_CREDENTIALS = {
  androidClientId:
    '560610133772-03ij6u6cqo2pk1t2tbjvmpqrl79md609.apps.googleusercontent.com',
  packageName: 'com.rxxxeron.prep404',
  redirectScheme: 'com.rxxxeron.prep404',
  redirectHost: 'login-callback',
  defaultNativeRedirectUri: 'com.rxxxeron.prep404://login-callback',
} as const;

export function resolvePlatformRedirectUri(params: {
  platformOS: string;
  webOrigin?: string;
  nativeRedirectUri?: string;
}): string {
  if (params.platformOS === 'web') {
    const cleanOrigin = (params.webOrigin || '').replace(/\/+$/, '');
    return cleanOrigin ? `${cleanOrigin}/auth/callback` : '/auth/callback';
  }
  const nativeUri = (params.nativeRedirectUri || '').trim();
  return nativeUri || ANDROID_OAUTH_CREDENTIALS.defaultNativeRedirectUri;
}

export function isMatchingOAuthRedirectUrl(
  incomingUrl: string,
  expectedRedirectUri: string
): boolean {
  if (!incomingUrl || !expectedRedirectUri) return false;
  const stripQueryHash = (u: string) =>
    u.split('#')[0].split('?')[0].replace(/\/+$/, '').toLowerCase();
  return stripQueryHash(incomingUrl) === stripQueryHash(expectedRedirectUri);
}


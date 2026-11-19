import {
  AppLanguage,
  EnglishCurriculum,
  NctbVersion,
  StudentMedium,
  ThemeMode,
  UserProfile,
  UserProfileMetadataSummary,
} from '../types';
import { NormalizedSupabaseUser } from './supabaseCallbackParser';

export interface ReconciledPendingIdentity {
  name: string;
  phone: string;
  email?: string;
  avatarUrl?: string;
  userId?: string;
  authProvider?: 'google' | 'phone';
}

export interface ProfileReconciliationResult {
  profile: UserProfile | null;
  pendingIdentity: ReconciledPendingIdentity | null;
  shouldSyncBackToSupabase: boolean;
}

export interface SupabaseProfileRow {
  id: string;
  email?: string | null;
  full_name?: string | null;
  phone?: string | null;
  avatar_url?: string | null;
  preferred_university_track?: string | null;
  current_academic_level?: string | null;
  study_medium?: string | null;
  nctb_version?: string | null;
  english_curriculum?: string | null;
  academic_batch?: string | null;
  institution_name?: string | null;
  division_name?: string | null;
  district_name?: string | null;
  ssc_gpa?: string | null;
  hsc_gpa?: string | null;
  study_streak_days?: number | null;
  preferred_language?: string | null;
  preferred_theme?: string | null;
  target_selections?: Record<string, string[]> | null;
  profile_json?: Partial<UserProfile> | null;
  updated_at?: string | null;
}

const UNIVERSITY_ID_TO_CODE: Record<string, string> = {
  nsu: 'NSU',
  brac: 'BRACU',
  bracu: 'BRACU',
  ewu: 'EWU',
  uiu: 'UIU',
  aiub: 'AIUB',
  aust: 'AUST',
  uap: 'UAP',
};

export function extractTargetUniversityCodes(
  targetSelections?: Record<string, string[]> | null
): string[] {
  if (!targetSelections || typeof targetSelections !== 'object') return [];
  const codes: string[] = [];
  for (const [uniId, disciplines] of Object.entries(targetSelections)) {
    if (!Array.isArray(disciplines) || disciplines.length === 0) continue;
    const normalized =
      UNIVERSITY_ID_TO_CODE[uniId.toLowerCase()] || uniId.toUpperCase();
    if (!codes.includes(normalized)) {
      codes.push(normalized);
    }
  }
  return codes;
}

export function derivePreferredUniversityTrack(
  targetSelections?: Record<string, string[]> | null,
  explicitTrack?: string | null
): string {
  const trimmed = (explicitTrack || '').trim();
  if (trimmed) {
    return UNIVERSITY_ID_TO_CODE[trimmed.toLowerCase()] || trimmed;
  }
  const codes = extractTargetUniversityCodes(targetSelections);
  return codes[0] || 'NSU';
}

export function deriveCurrentAcademicLevel(profile: {
  currentAcademicLevel?: string | null;
  medium?: StudentMedium;
  academicBatch?: string;
  hscBatch?: string;
  hscGroup?: string;
  nctbVersion?: NctbVersion | null;
  englishCurriculum?: EnglishCurriculum | null;
  aLevelBatch?: string;
}): string {
  const explicit = (profile.currentAcademicLevel || '').trim();
  if (explicit) return explicit;

  if (profile.medium === 'english') {
    const batch = (profile.aLevelBatch || profile.academicBatch || 'A-Level').trim();
    const curriculum =
      profile.englishCurriculum === 'edexcel'
        ? 'Pearson Edexcel'
        : 'Cambridge (CAIE)';
    return `${batch} · ${curriculum}`;
  }

  const batch = (profile.hscBatch || profile.academicBatch || 'HSC').trim();
  const group = (profile.hscGroup || '').trim();
  const version =
    profile.nctbVersion === 'english' ? 'NCTB English Version' : 'NCTB Bangla';
  return group ? `${batch} · ${group} (${version})` : `${batch} (${version})`;
}

export function normalizeProfileMetadata(profile: UserProfile): UserProfile {
  return {
    ...profile,
    preferredUniversityTrack: derivePreferredUniversityTrack(
      profile.targetSelections,
      profile.preferredUniversityTrack
    ),
    currentAcademicLevel: deriveCurrentAcademicLevel(profile),
  };
}

/**
 * Hydrates a complete `UserProfile` from a Supabase `public.profiles` row,
 * supporting both full `profile_json` rows and relational-column-only rows.
 * Relational columns take precedence when present so updates made in Supabase
 * reflect immediately in the app.
 */
export function hydrateUserProfileFromSupabaseRow(
  row: SupabaseProfileRow | null | undefined
): UserProfile | null {
  if (!row || !row.id) return null;

  const json =
    row.profile_json && typeof row.profile_json === 'object'
      ? row.profile_json
      : {};

  const hasMeaningfulData =
    Boolean(json.name) ||
    Boolean(row.full_name) ||
    Boolean(row.preferred_university_track) ||
    Boolean(row.current_academic_level) ||
    Boolean(
      row.target_selections && Object.keys(row.target_selections).length > 0
    );

  if (!hasMeaningfulData) return null;

  const studyMedium: StudentMedium =
    row.study_medium === 'english' || row.study_medium === 'bangla'
      ? row.study_medium
      : json.medium === 'english'
        ? 'english'
        : 'bangla';

  const nctbVersion: NctbVersion | null =
    row.nctb_version === 'english' || row.nctb_version === 'bangla'
      ? row.nctb_version
      : json.nctbVersion ?? (studyMedium === 'bangla' ? 'bangla' : null);

  const englishCurriculum: EnglishCurriculum | null =
    row.english_curriculum === 'edexcel' ||
    row.english_curriculum === 'cambridge'
      ? row.english_curriculum
      : json.englishCurriculum ?? (studyMedium === 'english' ? 'cambridge' : null);

  const targetSelections: Record<string, string[]> =
    row.target_selections &&
    typeof row.target_selections === 'object' &&
    Object.keys(row.target_selections).length > 0
      ? row.target_selections
      : json.targetSelections || {};

  const preferredLanguage: AppLanguage | undefined =
    row.preferred_language === 'bangla' || row.preferred_language === 'english'
      ? row.preferred_language
      : json.preferredLanguage;

  const preferredTheme: ThemeMode | undefined =
    row.preferred_theme === 'dark' || row.preferred_theme === 'light'
      ? row.preferred_theme
      : json.preferredTheme;

  const hydrated: UserProfile = {
    ...json,
    id: row.id,
    name: (row.full_name || json.name || 'Candidate').trim(),
    phone: (row.phone ?? json.phone ?? '').trim(),
    email: (row.email ?? json.email ?? undefined) || undefined,
    avatarUrl: (row.avatar_url ?? json.avatarUrl ?? undefined) || undefined,
    authProvider: json.authProvider || 'google',
    divisionName: row.division_name || json.divisionName,
    districtName: row.district_name || json.districtName,
    sscGpa: row.ssc_gpa || json.sscGpa,
    hscGpa: row.hsc_gpa || json.hscGpa,
    medium: studyMedium,
    nctbVersion,
    englishCurriculum,
    academicBatch:
      row.academic_batch ||
      json.academicBatch ||
      (studyMedium === 'english' ? 'A-Level 2025' : "HSC '25"),
    institutionName: row.institution_name || json.institutionName || '',
    studyStreakDays:
      typeof row.study_streak_days === 'number'
        ? row.study_streak_days
        : json.studyStreakDays ?? 0,
    targetSelections,
    preferredUniversityTrack: derivePreferredUniversityTrack(
      targetSelections,
      row.preferred_university_track || json.preferredUniversityTrack
    ),
    currentAcademicLevel: deriveCurrentAcademicLevel({
      currentAcademicLevel:
        row.current_academic_level || json.currentAcademicLevel,
      medium: studyMedium,
      academicBatch: row.academic_batch || json.academicBatch,
      hscBatch: json.hscBatch,
      hscGroup: json.hscGroup,
      nctbVersion,
      englishCurriculum,
      aLevelBatch: json.aLevelBatch,
    }),
    preferredLanguage,
    preferredTheme,
    updatedAt: row.updated_at || json.updatedAt,
  };

  return hydrated;
}

export function buildSupabaseProfileUpsertPayload(
  authUid: string,
  profile: UserProfile,
  fallbackEmail?: string | null
): Record<string, unknown> {
  const normalized = normalizeProfileMetadata(profile);
  const nowIso = new Date().toISOString();

  return {
    id: authUid,
    email: normalized.email || fallbackEmail || null,
    full_name: normalized.name,
    phone: normalized.phone || null,
    avatar_url: normalized.avatarUrl || null,
    preferred_university_track: normalized.preferredUniversityTrack || null,
    current_academic_level: normalized.currentAcademicLevel || null,
    study_medium: normalized.medium,
    nctb_version: normalized.nctbVersion ?? null,
    english_curriculum: normalized.englishCurriculum ?? null,
    academic_batch: normalized.academicBatch || null,
    institution_name: normalized.institutionName || null,
    division_name: normalized.divisionName || null,
    district_name: normalized.districtName || null,
    ssc_gpa: normalized.sscGpa || null,
    hsc_gpa: normalized.hscGpa || null,
    study_streak_days: normalized.studyStreakDays ?? 0,
    preferred_language: normalized.preferredLanguage ?? null,
    preferred_theme: normalized.preferredTheme ?? null,
    target_selections: normalized.targetSelections || {},
    profile_json: {
      ...normalized,
      id: authUid,
      updatedAt: nowIso,
    },
    updated_at: nowIso,
  };
}

export function buildUserMetadataSummary(
  profile: UserProfile | null,
  syncedAt?: string | null
): UserProfileMetadataSummary | null {
  if (!profile) return null;
  const normalized = normalizeProfileMetadata(profile);
  return {
    preferredUniversityTrack: normalized.preferredUniversityTrack || 'NSU',
    currentAcademicLevel:
      normalized.currentAcademicLevel || normalized.academicBatch || 'HSC',
    studyMedium: normalized.medium,
    academicBatch: normalized.academicBatch,
    institutionName: normalized.institutionName,
    targetUniversityCodes: extractTargetUniversityCodes(
      normalized.targetSelections
    ),
    studyStreakDays: normalized.studyStreakDays ?? 0,
    preferredLanguage: normalized.preferredLanguage,
    preferredTheme: normalized.preferredTheme,
    syncedAt: syncedAt ?? normalized.updatedAt ?? null,
  };
}

function mergeIdentityIntoProfile(
  base: UserProfile,
  user: NormalizedSupabaseUser
): { merged: UserProfile; metadataChanged: boolean } {
  const nextEmail = user.email || base.email;
  const nextAvatar = user.avatarUrl || base.avatarUrl;
  const baseNameTrimmed = (base.name || '').trim();
  const nextName =
    !baseNameTrimmed || baseNameTrimmed === 'Candidate'
      ? user.name || base.name
      : base.name;
  const nextProvider: UserProfile['authProvider'] = 'google';
  const nextTrack = derivePreferredUniversityTrack(
    base.targetSelections,
    base.preferredUniversityTrack
  );
  const nextAcademicLevel = deriveCurrentAcademicLevel(base);

  const metadataChanged =
    nextEmail !== base.email ||
    nextAvatar !== base.avatarUrl ||
    nextName !== base.name ||
    base.authProvider !== nextProvider ||
    base.preferredUniversityTrack !== nextTrack ||
    base.currentAcademicLevel !== nextAcademicLevel;

  return {
    merged: {
      ...base,
      id: user.id,
      name: nextName,
      email: nextEmail,
      avatarUrl: nextAvatar,
      authProvider: nextProvider,
      preferredUniversityTrack: nextTrack,
      currentAcademicLevel: nextAcademicLevel,
    },
    metadataChanged,
  };
}

/**
 * Pure reconciler that maps a Supabase Auth user + local/remote profile snapshots
 * into the authoritative app `profile` and `pendingIdentity`.
 *
 * Prevents cross-account profile leakage when switching Google accounts and
 * keeps Google email / avatar / display name and structured academic metadata
 * in sync on `INITIAL_SESSION`, `SIGNED_IN`, `USER_UPDATED`, and `TOKEN_REFRESHED`.
 */
export function reconcileProfileForSupabaseSession(params: {
  user: NormalizedSupabaseUser;
  localProfile: UserProfile | null;
  remoteProfile: UserProfile | null;
}): ProfileReconciliationResult {
  const { user, localProfile, remoteProfile } = params;

  const matchingRemote =
    remoteProfile && remoteProfile.id === user.id ? remoteProfile : null;
  const matchingLocal =
    localProfile && localProfile.id === user.id ? localProfile : null;

  if (matchingRemote) {
    const { merged, metadataChanged } = mergeIdentityIntoProfile(
      matchingRemote,
      user
    );
    return {
      profile: merged,
      pendingIdentity: null,
      shouldSyncBackToSupabase: metadataChanged,
    };
  }

  if (matchingLocal) {
    const { merged } = mergeIdentityIntoProfile(matchingLocal, user);
    return {
      profile: merged,
      pendingIdentity: null,
      shouldSyncBackToSupabase: true,
    };
  }

  return {
    profile: null,
    pendingIdentity: {
      userId: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      phone: '',
      authProvider: 'google',
    },
    shouldSyncBackToSupabase: false,
  };
}

export function shouldClearProfileOnSupabaseSignOut(
  session: { provider?: string; isGuest?: boolean } | null,
  profile: UserProfile | null
): boolean {
  if (session?.provider === 'google') return true;
  if (!session && profile?.authProvider === 'google') return true;
  return false;
}

export interface CachedSupabaseProfileEntry {
  version: 1;
  userId: string;
  cachedAt: string;
  basicUserInfo: NormalizedSupabaseUser;
  profile: UserProfile | null;
}

const SUPABASE_PROFILE_CACHE_PREFIX = 'prep404_supabase_profile_cache_v1:';

export function getSupabaseProfileCacheKey(userId: string): string {
  return `${SUPABASE_PROFILE_CACHE_PREFIX}${userId.trim()}`;
}

export function serializeCachedSupabaseProfile(
  entry: CachedSupabaseProfileEntry
): string {
  return JSON.stringify(entry);
}

export function parseCachedSupabaseProfile(
  raw: string | null | undefined,
  expectedUserId: string
): CachedSupabaseProfileEntry | null {
  if (!raw || !expectedUserId) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<CachedSupabaseProfileEntry>;
    if (
      !parsed ||
      parsed.version !== 1 ||
      parsed.userId !== expectedUserId ||
      !parsed.basicUserInfo ||
      parsed.basicUserInfo.id !== expectedUserId
    ) {
      return null;
    }

    const validProfile =
      parsed.profile &&
      typeof parsed.profile === 'object' &&
      parsed.profile.id === expectedUserId
        ? normalizeProfileMetadata(parsed.profile)
        : null;

    return {
      version: 1,
      userId: expectedUserId,
      cachedAt:
        typeof parsed.cachedAt === 'string'
          ? parsed.cachedAt
          : new Date().toISOString(),
      basicUserInfo: parsed.basicUserInfo,
      profile: validProfile,
    };
  } catch {
    return null;
  }
}


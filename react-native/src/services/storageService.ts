import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  AIClusterGatewayConfig,
  AIConversationThread,
  AppLanguage,
  AppNotification,
  AppUsageTelemetry,
  BattleHistoryItem,
  ExamHistoryItem,
  QuestionTimingTelemetry,
  ReportedQuestionItem,
  SupportRequest,
  ThemeMode,
  TopicAttemptRecord,
  UserProfile,
} from '../types';
import { FSRSCardState } from '../algorithms/fsrs';

const KEYS = {
  theme: 'prep404_theme_mode',
  language: 'prep404_language',
  session: 'prep404_auth_session',
  profile: 'prep404_user_profile',
  examHistory: 'prep404_exam_history',
  bookmarks: 'prep404_bookmarked_questions',
  fsrsCards: 'prep404_fsrs_cards',
  battleHistory: 'prep404_battle_history',
  notifications: 'prep404_notifications',
  supportRequests: 'prep404_support_requests',
  reportedQuestions: 'prep404_reported_questions',
  subscriptionTier: 'prep404_subscription_tier',
  subscriptionMeta: 'prep404_subscription_meta',
  analyticsConsent: 'prep404_analytics_consent',
  reminders: 'prep404_reminder_prefs',
  roadmapCompleted: 'prep404_roadmap_completed',
  topicAttempts: 'prep404_topic_attempts',
  aiConversations: 'prep404_ai_conversations',
  aiGatewayConfig: 'prep404_ai_gateway_config',
  questionTelemetry: 'prep404_question_telemetry',
  appUsageTelemetry: 'prep404_app_usage_telemetry',
} as const;

const DEFAULT_AI_GATEWAY_CONFIG: AIClusterGatewayConfig = {
  cloudflareTunnelUrl: 'https://a4000-cluster.fourzerofour.tech',
  prep404ServerUrl: '/api/v1',
  localModelName: 'aether-ai-7b-prep404',
  keepFullConversationLedger: true,
  autoSyncToServer: true,
  lastHandshakeAt: new Date().toISOString(),
  lastHandshakeStatus: 'local_gateway_ready',
  lastLatencyMs: 0,
};

const EMPTY_APP_USAGE_TELEMETRY: AppUsageTelemetry = {
  activeFocusSeconds: 0,
  appSwitchCount: 0,
  sessionsStarted: 0,
  sessionsCompleted: 0,
  lastUpdatedAt: new Date().toISOString(),
};

// In-memory cache synced with React Native AsyncStorage and prep404_server pipeline
const memoryCache = new Map<string, string>();

function readJson<T>(key: string, fallback: T): T {
  try {
    const raw = memoryCache.get(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function writeJson<T>(key: string, value: T): void {
  try {
    const serialized = JSON.stringify(value);
    memoryCache.set(key, serialized);
    AsyncStorage.setItem(key, serialized).catch(() => undefined);
  } catch {
    // ignore serialization issues
  }
}

export interface StoredAuthSession {
  token: string;
  isGuest: boolean;
  userId: string;
  provider?: 'google' | 'phone' | 'guest';
  email?: string;
}

function getAuthHeaders(): Record<string, string> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  const session = readJson<StoredAuthSession | null>(KEYS.session, null);
  if (session && !session.isGuest && session.token && !session.token.startsWith('otp-token-')) {
    headers.Authorization = `Bearer ${session.token}`;
  }
  return headers;
}

function syncUsageToServer(usage: AppUsageTelemetry): void {
  if (typeof fetch !== 'function') return;
  fetch('/api/v1/telemetry/app-usage', {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(usage),
  }).catch(() => undefined);
}

export const storageService = {
  async hydrate(): Promise<void> {
    try {
      const entries = await AsyncStorage.multiGet(Object.values(KEYS));
      entries.forEach(([k, v]) => {
        if (v !== null) memoryCache.set(k, v);
      });

      // Clean out any legacy pre-seeded fake records from earlier builds
      const existingTelemetry = readJson<QuestionTimingTelemetry[]>(
        KEYS.questionTelemetry,
        []
      );
      if (existingTelemetry.some((e) => e.id?.startsWith('tel_seed_'))) {
        const realOnly = existingTelemetry.filter(
          (e) => !e.id?.startsWith('tel_seed_')
        );
        writeJson(KEYS.questionTelemetry, realOnly);
      }

      const existingThreads = readJson<AIConversationThread[]>(
        KEYS.aiConversations,
        []
      );
      if (existingThreads.some((t) => t.threadId?.startsWith('thr_seed_'))) {
        const realThreads = existingThreads.filter(
          (t) => !t.threadId?.startsWith('thr_seed_')
        );
        writeJson(KEYS.aiConversations, realThreads);
      }

      // Hydrate from prep404_server persistent pipeline if local cache is empty
      if (typeof fetch === 'function') {
        try {
          const resp = await fetch('/api/v1/pipeline/state');
          if (resp.ok) {
            const serverState = (await resp.json()) as {
              ok?: boolean;
              telemetryLocks?: QuestionTimingTelemetry[];
              examSubmissions?: ExamHistoryItem[];
              appUsage?: AppUsageTelemetry | null;
            };
            if (
              Array.isArray(serverState.telemetryLocks) &&
              serverState.telemetryLocks.length > 0 &&
              this.getQuestionTelemetryHistory().length === 0
            ) {
              writeJson(KEYS.questionTelemetry, serverState.telemetryLocks);
            }
            if (
              Array.isArray(serverState.examSubmissions) &&
              serverState.examSubmissions.length > 0 &&
              this.getExamHistory().length === 0
            ) {
              writeJson(KEYS.examHistory, serverState.examSubmissions);
            }
            if (
              serverState.appUsage &&
              this.getAppUsageTelemetry().activeFocusSeconds === 0 &&
              serverState.appUsage.activeFocusSeconds > 0
            ) {
              writeJson(KEYS.appUsageTelemetry, serverState.appUsage);
            }
          }
        } catch {
          // Offline or local CLI test environment
        }
      }
    } catch {
      // fallback to clean memory defaults
    }
  },

  getTheme(): ThemeMode {
    return memoryCache.get(KEYS.theme) === 'dark' ? 'dark' : 'light';
  },
  setTheme(mode: ThemeMode) {
    memoryCache.set(KEYS.theme, mode);
    AsyncStorage.setItem(KEYS.theme, mode).catch(() => undefined);
  },

  getLanguage(): AppLanguage {
    return memoryCache.get(KEYS.language) === 'bangla' ? 'bangla' : 'english';
  },
  setLanguage(lang: AppLanguage) {
    memoryCache.set(KEYS.language, lang);
    AsyncStorage.setItem(KEYS.language, lang).catch(() => undefined);
  },

  getSession(): StoredAuthSession | null {
    return readJson(KEYS.session, null);
  },
  setSession(session: StoredAuthSession | null) {
    if (!session) {
      memoryCache.delete(KEYS.session);
      AsyncStorage.removeItem(KEYS.session).catch(() => undefined);
    } else {
      writeJson(KEYS.session, session);
    }
  },

  getProfile(): UserProfile | null {
    return readJson(KEYS.profile, null);
  },
  setProfile(profile: UserProfile | null) {
    if (!profile) {
      memoryCache.delete(KEYS.profile);
      AsyncStorage.removeItem(KEYS.profile).catch(() => undefined);
    } else {
      writeJson(KEYS.profile, profile);
    }
  },

  getExamHistory(): ExamHistoryItem[] {
    return readJson(KEYS.examHistory, []);
  },
  addExamHistory(item: ExamHistoryItem) {
    const updated = [item, ...this.getExamHistory()].slice(0, 100);
    writeJson(KEYS.examHistory, updated);

    // Increment real user study streak on exam completion
    const currentProfile = this.getProfile();
    if (currentProfile) {
      this.setProfile({
        ...currentProfile,
        studyStreakDays: Math.max(1, (currentProfile.studyStreakDays || 0) + 1),
      });
    }

    if (typeof fetch === 'function') {
      fetch('/api/v1/exams/submit', {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(item),
      }).catch(() => undefined);
    }
  },

  getTopicAttempts(): TopicAttemptRecord[] {
    return readJson(KEYS.topicAttempts, []);
  },
  addTopicAttempt(attempt: TopicAttemptRecord) {
    const updated = [attempt, ...this.getTopicAttempts()].slice(0, 500);
    writeJson(KEYS.topicAttempts, updated);
  },

  getAIConversations(): AIConversationThread[] {
    return readJson<AIConversationThread[]>(KEYS.aiConversations, []);
  },
  saveAIConversations(threads: AIConversationThread[]) {
    writeJson(KEYS.aiConversations, threads);
  },
  upsertAIConversation(thread: AIConversationThread): AIConversationThread[] {
    const list = this.getAIConversations();
    const exists = list.some((t) => t.threadId === thread.threadId);
    const updated = exists
      ? list.map((t) => (t.threadId === thread.threadId ? thread : t))
      : [thread, ...list];
    writeJson(KEYS.aiConversations, updated);
    return updated;
  },

  getAIGatewayConfig(): AIClusterGatewayConfig {
    return readJson(KEYS.aiGatewayConfig, DEFAULT_AI_GATEWAY_CONFIG);
  },
  setAIGatewayConfig(config: AIClusterGatewayConfig) {
    writeJson(KEYS.aiGatewayConfig, config);
  },

  getBookmarks(): string[] {
    return readJson(KEYS.bookmarks, []);
  },
  toggleBookmark(questionId: string): string[] {
    const list = this.getBookmarks();
    const next = list.includes(questionId)
      ? list.filter((id) => id !== questionId)
      : [...list, questionId];
    writeJson(KEYS.bookmarks, next);
    return next;
  },

  getFsrsCards(): Record<string, FSRSCardState> {
    return readJson(KEYS.fsrsCards, {});
  },
  saveFsrsCard(questionId: string, state: FSRSCardState) {
    const cards = this.getFsrsCards();
    cards[questionId] = state;
    writeJson(KEYS.fsrsCards, cards);
  },

  getBattleHistory(): BattleHistoryItem[] {
    return readJson(KEYS.battleHistory, []);
  },
  addBattleHistory(item: BattleHistoryItem) {
    const existing = this.getBattleHistory();
    writeJson(KEYS.battleHistory, [item, ...existing].slice(0, 50));
  },

  getNotifications(): AppNotification[] {
    return readJson<AppNotification[]>(KEYS.notifications, []);
  },
  saveNotifications(list: AppNotification[]) {
    writeJson(KEYS.notifications, list);
  },

  getSupportRequests(): SupportRequest[] {
    return readJson(KEYS.supportRequests, []);
  },
  addSupportRequest(req: SupportRequest) {
    writeJson(KEYS.supportRequests, [req, ...this.getSupportRequests()]);
  },

  getReportedQuestions(): ReportedQuestionItem[] {
    return readJson(KEYS.reportedQuestions, []);
  },
  addReportedQuestion(item: ReportedQuestionItem) {
    writeJson(KEYS.reportedQuestions, [item, ...this.getReportedQuestions()]);
  },

  getSubscription(): {
    tier: 'free' | 'pro' | 'elite';
    planName: string;
    price: number;
    method: string;
    date: string;
  } {
    const tier =
      (memoryCache.get(KEYS.subscriptionTier) as 'free' | 'pro' | 'elite') || 'free';
    const meta = readJson(KEYS.subscriptionMeta, {
      planName:
        tier === 'free'
          ? 'Free Starter Plan'
          : tier === 'elite'
            ? 'Varsity Elite Pass'
            : 'Prep404 Pro Pass',
      price: tier === 'free' ? 0 : tier === 'elite' ? 2499 : 1499,
      method: 'bKash',
      date: new Date().toISOString().split('T')[0],
    });
    return { tier, ...meta };
  },
  setSubscription(
    tier: 'free' | 'pro' | 'elite',
    planName: string,
    price: number,
    method: string
  ) {
    memoryCache.set(KEYS.subscriptionTier, tier);
    AsyncStorage.setItem(KEYS.subscriptionTier, tier).catch(() => undefined);
    writeJson(KEYS.subscriptionMeta, {
      planName,
      price,
      method,
      date: new Date().toISOString().split('T')[0],
    });
  },

  getAnalyticsConsent(): boolean {
    const val = memoryCache.get(KEYS.analyticsConsent);
    return val === undefined ? true : val === 'true';
  },
  setAnalyticsConsent(enabled: boolean) {
    memoryCache.set(KEYS.analyticsConsent, String(enabled));
    AsyncStorage.setItem(KEYS.analyticsConsent, String(enabled)).catch(() => undefined);
  },

  getReminderPrefs(): {
    practiceReminders: boolean;
    dailyLiveAlert: boolean;
    streakShieldAlert: boolean;
    preferredTime: string;
  } {
    return readJson(KEYS.reminders, {
      practiceReminders: true,
      dailyLiveAlert: true,
      streakShieldAlert: true,
      preferredTime: '20:00',
    });
  },
  setReminderPrefs(prefs: {
    practiceReminders: boolean;
    dailyLiveAlert: boolean;
    streakShieldAlert: boolean;
    preferredTime: string;
  }) {
    writeJson(KEYS.reminders, prefs);
  },

  getCompletedRoadmapIds(): string[] {
    return readJson(KEYS.roadmapCompleted, []);
  },
  markRoadmapCompleted(milestoneId: string) {
    const existing = this.getCompletedRoadmapIds();
    if (!existing.includes(milestoneId)) {
      writeJson(KEYS.roadmapCompleted, [...existing, milestoneId]);
    }
  },

  getQuestionTelemetryHistory(): QuestionTimingTelemetry[] {
    return readJson<QuestionTimingTelemetry[]>(KEYS.questionTelemetry, []);
  },
  saveQuestionTelemetryEvent(event: QuestionTimingTelemetry) {
    const existing = this.getQuestionTelemetryHistory();
    const updated = [event, ...existing].slice(0, 500);
    writeJson(KEYS.questionTelemetry, updated);
  },

  getAppUsageTelemetry(): AppUsageTelemetry {
    return readJson<AppUsageTelemetry>(
      KEYS.appUsageTelemetry,
      EMPTY_APP_USAGE_TELEMETRY
    );
  },
  incrementAppSwitchInterrupt() {
    const cur = this.getAppUsageTelemetry();
    const next: AppUsageTelemetry = {
      ...cur,
      appSwitchCount: cur.appSwitchCount + 1,
      lastUpdatedAt: new Date().toISOString(),
    };
    writeJson(KEYS.appUsageTelemetry, next);
    syncUsageToServer(next);
  },
  addActiveFocusSeconds(seconds: number) {
    const cur = this.getAppUsageTelemetry();
    const next: AppUsageTelemetry = {
      ...cur,
      activeFocusSeconds: cur.activeFocusSeconds + Math.max(0, seconds),
      lastUpdatedAt: new Date().toISOString(),
    };
    writeJson(KEYS.appUsageTelemetry, next);
    syncUsageToServer(next);
  },
  incrementSessionsStarted() {
    const cur = this.getAppUsageTelemetry();
    const next: AppUsageTelemetry = {
      ...cur,
      sessionsStarted: cur.sessionsStarted + 1,
      lastUpdatedAt: new Date().toISOString(),
    };
    writeJson(KEYS.appUsageTelemetry, next);
    syncUsageToServer(next);
  },
  incrementSessionsCompleted() {
    const cur = this.getAppUsageTelemetry();
    const next: AppUsageTelemetry = {
      ...cur,
      sessionsCompleted: cur.sessionsCompleted + 1,
      lastUpdatedAt: new Date().toISOString(),
    };
    writeJson(KEYS.appUsageTelemetry, next);
    syncUsageToServer(next);

    // Ensure study streak is at least 1 once the user completes a real study session
    const currentProfile = this.getProfile();
    if (currentProfile && (currentProfile.studyStreakDays || 0) === 0) {
      this.setProfile({
        ...currentProfile,
        studyStreakDays: 1,
      });
    }
  },

  clearAllUserData() {
    Object.values(KEYS).forEach((k) => {
      if (k !== KEYS.theme && k !== KEYS.language) {
        memoryCache.delete(k);
        AsyncStorage.removeItem(k).catch(() => undefined);
      }
    });
    if (typeof fetch === 'function') {
      fetch('/api/v1/pipeline/reset', { method: 'POST' }).catch(() => undefined);
    }
  },
};

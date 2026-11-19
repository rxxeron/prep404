import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  AnswerBehaviorClass,
  AppUsageTelemetry,
  DataLoggingQueueStatus,
  FingerTouchSample,
  Question,
  QuestionTimingTelemetry,
  TouchCadenceLabel,
  TouchGestureKind,
  TouchPatternMetrics,
} from '../types';
import { storageService } from './storageService';

const TELEMETRY_OUTBOX_KEY = 'prep404_telemetry_outbox_v1';
const TELEMETRY_ENDPOINT = '/api/v1/telemetry/answer-lock';
const MAX_TRACE_SAMPLES = 24;
const MAX_OUTBOX_ITEMS = 250;
const DEBOUNCE_FIRST_TOUCH_MS = 120;

export interface ActiveQuestionLifecycle {
  questionId: string;
  questionText: string;
  topicId?: string;
  subjectName: string;
  universityCode?: string;
  sourceScreen: QuestionTimingTelemetry['sourceScreen'];
  renderTimestampMs: number;
  firstFingerActivityMs: number | null;
  touchInteractionCount: number;
  scrollCount: number;
  pressInCount: number;
  touchTimestampsMs: number[];
  touchTrace: FingerTouchSample[];
}

export interface AnswerLockIngestionPayload {
  schemaVersion: 'aether-telemetry-v2';
  eventId: string;
  candidateId: string;
  platform: string;
  questionId: string;
  topicId?: string;
  subjectName: string;
  universityCode?: string;
  sourceScreen: QuestionTimingTelemetry['sourceScreen'];
  renderTimestampMs: number;
  firstFingerActivityMs: number;
  answerLockedAtMs: number;
  readTimeMs: number;
  thinkTimeMs: number;
  totalTimeMs: number;
  expectedMinReadMs: number;
  touchInteractionCount: number;
  touchPattern: TouchPatternMetrics;
  classification: AnswerBehaviorClass;
  behaviorClass: AnswerBehaviorClass;
  lockedOptionId: string;
  selectedOptionId: string;
  isCorrect: boolean;
  appUsageSnapshot: AppUsageTelemetry;
  recordedAt: string;
}

export interface FingerActivityMetadata {
  kind?: TouchGestureKind;
  x?: number;
  y?: number;
  optionId?: string;
  nowMs?: number;
}

export interface QueuedTelemetryEnvelope {
  payload: AnswerLockIngestionPayload;
  retryCount: number;
  nextAttemptAtMs: number;
  queuedAt: string;
}

export interface ReactNativeLifecycleAppState {
  currentState?: string | null;
  addEventListener: (
    type: 'change',
    listener: (nextState: string) => void
  ) => { remove: () => void };
}

type StatusListener = (status: DataLoggingQueueStatus) => void;

const activeSessions = new Map<string, ActiveQuestionLifecycle>();
const statusListeners = new Set<StatusListener>();

let outboxCache: QueuedTelemetryEnvelope[] = [];
let outboxHydrated = false;
let isFlushing = false;
let transmittedCount = 0;
let failedAttemptsCount = 0;
let lastSyncedAt: string | undefined;
let lastError: string | undefined;
let runtimePlatform = 'react-native';
let lifecycleAttached = false;
let periodicFlushTimer: ReturnType<typeof setInterval> | null = null;

function notifyStatusListeners(): void {
  const snapshot: DataLoggingQueueStatus = {
    pendingCount: outboxCache.length,
    transmittedCount,
    failedAttemptsCount,
    isFlushing,
    lastSyncedAt,
    lastError,
  };
  statusListeners.forEach((cb) => {
    try {
      cb(snapshot);
    } catch {
      // ignore listener errors
    }
  });
}

async function persistOutbox(): Promise<void> {
  try {
    await AsyncStorage.setItem(TELEMETRY_OUTBOX_KEY, JSON.stringify(outboxCache));
  } catch {
    // ignore AsyncStorage failure in constrained test environments
  }
}

export async function hydrateTelemetryOutbox(): Promise<void> {
  if (outboxHydrated) return;
  outboxHydrated = true;
  try {
    const raw = await AsyncStorage.getItem(TELEMETRY_OUTBOX_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as QueuedTelemetryEnvelope[];
      if (Array.isArray(parsed)) {
        outboxCache = parsed;
      }
    }
  } catch {
    outboxCache = [];
  }
  notifyStatusListeners();
}

/**
 * Extracts sanitized local coordinates from a React Native GestureResponderEvent
 * (works identically on Android, iOS, and React Native Web).
 */
export function extractTouchPoint(event: unknown): { x?: number; y?: number } {
  if (!event || typeof event !== 'object') return {};
  const nativeEvent = (
    event as { nativeEvent?: Record<string, unknown> }
  ).nativeEvent;
  if (!nativeEvent) return {};
  const rawX =
    typeof nativeEvent.locationX === 'number'
      ? nativeEvent.locationX
      : typeof nativeEvent.pageX === 'number'
        ? nativeEvent.pageX
        : undefined;
  const rawY =
    typeof nativeEvent.locationY === 'number'
      ? nativeEvent.locationY
      : typeof nativeEvent.pageY === 'number'
        ? nativeEvent.pageY
        : undefined;

  return {
    x: rawX !== undefined && Number.isFinite(rawX) ? Math.round(rawX) : undefined,
    y: rawY !== undefined && Number.isFinite(rawY) ? Math.round(rawY) : undefined,
  };
}

/**
 * Computes minimum expected cognitive reading latency (ms) from stem length + formula density.
 */
export function computeStemExpectedMinReadMs(
  questionOrText: Question | string
): number {
  const rawText =
    typeof questionOrText === 'string'
      ? questionOrText
      : `${questionOrText.passage || ''} ${questionOrText.text || ''} ${questionOrText.options.map((o) => o.text).join(' ')}`;
  const clean = rawText.trim();
  if (!clean) return 2200;
  const words = clean.split(/\s+/).length;
  const hasMath =
    clean.includes('$') || clean.includes('\\') || clean.includes('^');
  const raw = 1800 + words * 95 + (hasMath ? 750 : 0);
  return Math.max(2200, Math.min(6500, raw));
}

export function classifyTelemetryTiming(
  firstMs: number,
  secondMs: number,
  thirdVal: number
): AnswerBehaviorClass {
  const isTotalSignature = thirdVal <= 300;
  const totalMs = isTotalSignature ? firstMs : firstMs + secondMs;
  const expectedMinReadMs = isTotalSignature ? secondMs : thirdVal;
  const overDwellThresholdMs = isTotalSignature
    ? Math.max(90_000, thirdVal * 2000)
    : 95_000;

  if (totalMs < 2500 || totalMs < Math.round(expectedMinReadMs * 0.65)) {
    return 'impulse_guess';
  }
  if (totalMs > overDwellThresholdMs) {
    return 'over_dwell';
  }
  return 'deliberate';
}

function summarizeTouchPattern(
  session: ActiveQuestionLifecycle | undefined,
  renderMs: number,
  firstFingerMs: number,
  commitMs: number,
  lockedOptionId: string,
  behaviorClass: AnswerBehaviorClass
): TouchPatternMetrics {
  const baseTrace = session ? [...session.touchTrace] : [];
  baseTrace.push({
    kind: 'option_lock',
    relativeMs: Math.max(0, commitMs - renderMs),
    optionId: lockedOptionId,
  });

  const timestamps = session
    ? [...session.touchTimestampsMs, commitMs].sort((a, b) => a - b)
    : [firstFingerMs, commitMs];

  let gapSum = 0;
  let gapCount = 0;
  for (let i = 1; i < timestamps.length; i++) {
    gapSum += Math.max(0, timestamps[i] - timestamps[i - 1]);
    gapCount += 1;
  }

  const hesitationGapMs = Math.max(0, commitMs - firstFingerMs);
  const interTouchMeanMs = gapCount > 0 ? Math.round(gapSum / gapCount) : hesitationGapMs;
  const scrollCount = session?.scrollCount ?? 0;
  const pressInCount = (session?.pressInCount ?? 0) + 1;

  let touchCadenceLabel: TouchCadenceLabel = 'steady_deliberate';
  if (behaviorClass === 'impulse_guess') {
    touchCadenceLabel = 'rapid_impulsive';
  } else if (behaviorClass === 'over_dwell') {
    touchCadenceLabel = 'prolonged_struggle';
  } else if (scrollCount > 0) {
    touchCadenceLabel = 'scrolled_scanning';
  }

  return {
    totalTouchCount: (session?.touchInteractionCount ?? 0) + 1,
    scrollCount,
    pressInCount,
    hesitationGapMs,
    interTouchMeanMs,
    touchCadenceLabel,
    touchTrace: baseTrace.slice(-MAX_TRACE_SAMPLES),
  };
}

export const dataLoggingService = {
  setRuntimePlatform(platformName: string): void {
    if (platformName) runtimePlatform = platformName;
  },

  attachLifecycleMonitor(
    appState?: ReactNativeLifecycleAppState,
    platformName?: string
  ): void {
    if (platformName) runtimePlatform = platformName;
    if (lifecycleAttached) return;
    lifecycleAttached = true;

    hydrateTelemetryOutbox().then(() => {
      if (outboxCache.length > 0) {
        void this.flushOutbox();
      }
    });

    if (appState && typeof appState.addEventListener === 'function') {
      appState.addEventListener('change', (nextState: string) => {
        if (nextState === 'active') {
          void this.flushOutbox();
        } else if (nextState === 'background' || nextState === 'inactive') {
          void persistOutbox();
        }
      });
    }

    if (!periodicFlushTimer) {
      periodicFlushTimer = setInterval(() => {
        if (outboxCache.length > 0 && !isFlushing) {
          void this.flushOutbox();
        }
      }, 20_000);
    }
  },

  startQuestionObservation(
    paramsOrId:
      | string
      | {
          questionId: string;
          questionText?: string;
          topicId?: string;
          subjectName?: string;
          universityCode?: string;
          sourceScreen?: QuestionTimingTelemetry['sourceScreen'];
          nowMs?: number;
        },
    nowMsArg?: number
  ): void {
    const isString = typeof paramsOrId === 'string';
    const questionId = isString ? paramsOrId : paramsOrId.questionId;
    const now = isString
      ? (nowMsArg ?? Date.now())
      : (paramsOrId.nowMs ?? nowMsArg ?? Date.now());

    const existing = activeSessions.get(questionId);
    if (
      existing &&
      nowMsArg === undefined &&
      (isString || paramsOrId.nowMs === undefined) &&
      now - existing.renderTimestampMs < 120_000
    ) {
      return;
    }

    activeSessions.set(questionId, {
      questionId,
      questionText: isString ? '' : paramsOrId.questionText || '',
      topicId: isString ? undefined : paramsOrId.topicId,
      subjectName: isString ? 'General' : paramsOrId.subjectName || 'General',
      universityCode: isString ? undefined : paramsOrId.universityCode,
      sourceScreen: isString
        ? 'live_exam'
        : paramsOrId.sourceScreen || 'live_exam',
      renderTimestampMs: now,
      firstFingerActivityMs: null,
      touchInteractionCount: 0,
      scrollCount: 0,
      pressInCount: 0,
      touchTimestampsMs: [],
      touchTrace: [{ kind: 'render', relativeMs: 0 }],
    });
  },

  recordFingerTouch(
    questionId: string,
    metaOrNowMs?: number | FingerActivityMetadata
  ): void {
    const session = activeSessions.get(questionId);
    if (!session) return;

    const meta: FingerActivityMetadata =
      typeof metaOrNowMs === 'number'
        ? { nowMs: metaOrNowMs }
        : metaOrNowMs || {};
    const nowMs = meta.nowMs ?? Date.now();
    const kind: TouchGestureKind = meta.kind || 'press_in';

    session.touchInteractionCount += 1;
    if (kind === 'scroll') session.scrollCount += 1;
    if (kind === 'press_in' || kind === 'option_inspect') {
      session.pressInCount += 1;
    }

    if (
      session.firstFingerActivityMs === null &&
      nowMs > session.renderTimestampMs + DEBOUNCE_FIRST_TOUCH_MS
    ) {
      session.firstFingerActivityMs = nowMs;
    }

    session.touchTimestampsMs.push(nowMs);
    if (session.touchTrace.length < MAX_TRACE_SAMPLES - 1) {
      session.touchTrace.push({
        kind,
        relativeMs: Math.max(0, nowMs - session.renderTimestampMs),
        x: meta.x,
        y: meta.y,
        optionId: meta.optionId,
      });
    }
  },

  commitAnswerLockAndDispatch(params: {
    question?: Question;
    questionId?: string;
    questionText?: string;
    topicId?: string;
    subjectName?: string;
    universityCode?: string;
    sourceScreen: QuestionTimingTelemetry['sourceScreen'];
    selectedOptionId: string;
    isCorrect?: boolean;
    nowMs?: number;
    skipNetworkDispatch?: boolean;
  }): {
    event: QuestionTimingTelemetry;
    payload: AnswerLockIngestionPayload;
  } {
    const now = params.nowMs ?? Date.now();
    const q = params.question;
    const questionId = q ? q.id : params.questionId || 'unknown_q';
    const questionSource = q || params.questionText || '';
    const topicId = q ? q.topicId : params.topicId;
    const subjectName = q ? q.subjectName : params.subjectName || 'General';
    const universityCode = q ? q.universityTags?.[0] : params.universityCode;
    const lockedOptionId = params.selectedOptionId;
    const isCorrect = q
      ? lockedOptionId.toUpperCase() === q.correctOptionId.toUpperCase()
      : Boolean(params.isCorrect);

    const session = activeSessions.get(questionId);
    const renderMs = session ? session.renderTimestampMs : now - 5_000;
    const totalTimeMs = Math.max(250, now - renderMs);
    const expectedMinReadMs = computeStemExpectedMinReadMs(questionSource);

    let readTimeMs: number;
    let thinkTimeMs: number;
    let firstFingerMs: number;

    if (
      session?.firstFingerActivityMs &&
      session.firstFingerActivityMs > renderMs &&
      session.firstFingerActivityMs < now
    ) {
      firstFingerMs = session.firstFingerActivityMs;
      readTimeMs = Math.max(200, firstFingerMs - renderMs);
      thinkTimeMs = Math.max(100, now - firstFingerMs);
    } else {
      const estimatedRead = Math.min(
        expectedMinReadMs,
        Math.round(totalTimeMs * 0.44)
      );
      readTimeMs = Math.max(200, estimatedRead);
      thinkTimeMs = Math.max(50, totalTimeMs - readTimeMs);
      firstFingerMs = renderMs + readTimeMs;
    }

    const classification = classifyTelemetryTiming(
      readTimeMs,
      thinkTimeMs,
      expectedMinReadMs
    );

    const touchPattern = summarizeTouchPattern(
      session,
      renderMs,
      firstFingerMs,
      now,
      lockedOptionId,
      classification
    );

    const eventId = `tel_${questionId}_${now}`;
    const recordedAt = new Date(now).toISOString();

    const event: QuestionTimingTelemetry = {
      id: eventId,
      eventId,
      questionId,
      topicId,
      subjectName,
      universityCode,
      sourceScreen: params.sourceScreen,
      renderTimestampMs: renderMs,
      firstFingerActivityMs: firstFingerMs,
      answerLockedAtMs: now,
      readTimeMs,
      thinkTimeMs,
      totalTimeMs,
      expectedMinReadMs,
      touchInteractionCount: touchPattern.totalTouchCount,
      touchPattern,
      classification,
      behaviorClass: classification,
      lockedOptionId,
      selectedOptionId: lockedOptionId,
      isCorrect,
      platform: runtimePlatform,
      recordedAt,
    };

    const profile = storageService.getProfile();
    const sessionAuth = storageService.getSession();
    const appUsageSnapshot = storageService.getAppUsageTelemetry();

    const payload: AnswerLockIngestionPayload = {
      schemaVersion: 'aether-telemetry-v2',
      eventId,
      candidateId:
        profile?.id || sessionAuth?.userId || 'unauthenticated_candidate',
      platform: runtimePlatform,
      questionId,
      topicId,
      subjectName,
      universityCode,
      sourceScreen: params.sourceScreen,
      renderTimestampMs: renderMs,
      firstFingerActivityMs: firstFingerMs,
      answerLockedAtMs: now,
      readTimeMs,
      thinkTimeMs,
      totalTimeMs,
      expectedMinReadMs,
      touchInteractionCount: touchPattern.totalTouchCount,
      touchPattern,
      classification,
      behaviorClass: classification,
      lockedOptionId,
      selectedOptionId: lockedOptionId,
      isCorrect,
      appUsageSnapshot,
      recordedAt,
    };

    activeSessions.delete(questionId);
    storageService.saveQuestionTelemetryEvent(event);

    if (!params.skipNetworkDispatch) {
      this.enqueueAndSend(payload);
    }

    return { event, payload };
  },

  enqueueAndSend(payload: AnswerLockIngestionPayload): void {
    const gatewayConfig = storageService.getAIGatewayConfig();
    if (!gatewayConfig.autoSyncToServer) return;

    outboxCache.push({
      payload,
      retryCount: 0,
      nextAttemptAtMs: Date.now(),
      queuedAt: new Date().toISOString(),
    });
    if (outboxCache.length > MAX_OUTBOX_ITEMS) {
      outboxCache = outboxCache.slice(-MAX_OUTBOX_ITEMS);
    }
    notifyStatusListeners();
    void persistOutbox();
    void this.flushOutbox();
  },

  async flushOutbox(
    transportFn?: (url: string, body: AnswerLockIngestionPayload) => Promise<boolean>
  ): Promise<{ delivered: number; remaining: number }> {
    if (isFlushing || outboxCache.length === 0) {
      return { delivered: 0, remaining: outboxCache.length };
    }

    const baseRoute = (
      storageService.getAIGatewayConfig().prep404ServerUrl || '/api/v1'
    ).replace(/\/$/, '');
    const targetUrl = baseRoute.endsWith('/api/v1')
      ? `${baseRoute}/telemetry/answer-lock`
      : TELEMETRY_ENDPOINT;

    const sendPayload =
      transportFn ||
      (async (url: string, body: AnswerLockIngestionPayload): Promise<boolean> => {
        if (typeof fetch !== 'function') return false;
        try {
          const headers: Record<string, string> = {
            'Content-Type': 'application/json',
            'X-Prep404-Platform': body.platform,
          };
          const session = storageService.getSession();
          if (
            session &&
            !session.isGuest &&
            session.token &&
            !session.token.startsWith('otp-token-')
          ) {
            headers.Authorization = `Bearer ${session.token}`;
          }
          const res = await fetch(url, {
            method: 'POST',
            headers,
            body: JSON.stringify(body),
          });
          return res.ok;
        } catch {
          return false;
        }
      });

    isFlushing = true;
    notifyStatusListeners();

    const nowMs = Date.now();
    const stillPending: QueuedTelemetryEnvelope[] = [];
    let delivered = 0;

    try {
      for (const envelope of outboxCache) {
        if (!transportFn && envelope.nextAttemptAtMs > nowMs) {
          stillPending.push(envelope);
          continue;
        }

        const ok = await sendPayload(targetUrl, envelope.payload);
        if (ok) {
          delivered += 1;
          transmittedCount += 1;
          lastSyncedAt = new Date().toISOString();
          lastError = undefined;
        } else {
          failedAttemptsCount += 1;
          const nextRetry = envelope.retryCount + 1;
          const backoffMs = Math.min(300_000, 1500 * Math.pow(2, nextRetry));
          lastError = `Deferred (${nextRetry} retries) — queued safely for retry`;
          if (nextRetry <= 8) {
            stillPending.push({
              ...envelope,
              retryCount: nextRetry,
              nextAttemptAtMs: nowMs + backoffMs,
            });
          }
        }
      }

      outboxCache = stillPending;
      await persistOutbox();
    } finally {
      isFlushing = false;
      notifyStatusListeners();
    }

    return { delivered, remaining: outboxCache.length };
  },

  getActiveSession(questionId: string): ActiveQuestionLifecycle | undefined {
    return activeSessions.get(questionId);
  },

  getQueueStatus(): DataLoggingQueueStatus {
    return {
      pendingCount: outboxCache.length,
      transmittedCount,
      failedAttemptsCount,
      isFlushing,
      lastSyncedAt,
      lastError,
    };
  },

  subscribeStatus(listener: StatusListener): () => void {
    statusListeners.add(listener);
    listener(this.getQueueStatus());
    return () => {
      statusListeners.delete(listener);
    };
  },

  resetOutboxForTests(): void {
    outboxCache = [];
    transmittedCount = 0;
    failedAttemptsCount = 0;
    lastSyncedAt = undefined;
    lastError = undefined;
    activeSessions.clear();
    notifyStatusListeners();
  },
};

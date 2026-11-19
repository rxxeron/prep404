import {
  createInitialFSRSState,
  FSRSRating,
  reviewFSRSCard,
} from '../algorithms/fsrs';
import {
  AnswerBehaviorClass,
  CandidateSeriousnessProfile,
  Question,
  QuestionTimingTelemetry,
} from '../types';
import {
  classifyTelemetryTiming,
  computeStemExpectedMinReadMs,
  dataLoggingService,
  FingerActivityMetadata,
} from './dataLoggingService';
import { storageService } from './storageService';

export interface ReactNativeAppStateLike {
  currentState?: string | null;
  addEventListener: (
    type: 'change',
    listener: (nextState: string) => void
  ) => { remove: () => void };
}

let focusMonitorAttached = false;
let focusTickTimer: ReturnType<typeof setInterval> | null = null;

/**
  * Computes the minimum expected cognitive reading time (ms) for a question stem
  * based on word count and mathematical formula density.
  */
export function computeExpectedMinReadMs(
  questionOrText: Question | string
): number {
  return computeStemExpectedMinReadMs(questionOrText);
}

/**
  * Classifies how a candidate answered a question based on Read -> Think -> Lock timing.
  * Supports both (totalTimeMs, expectedMinReadMs, targetSolveSec) and (readTimeMs, thinkTimeMs, expectedMinReadMs).
  */
export function classifyQuestionTiming(
  firstMs: number,
  secondMs: number,
  thirdVal: number
): AnswerBehaviorClass {
  return classifyTelemetryTiming(firstMs, secondMs, thirdVal);
}

/**
  * Starts tracking a newly rendered question via dataLoggingService so Read Time
  * latency, finger touch patterns, and Think Time intervals are recorded accurately.
  */
export function startQuestionTelemetry(
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
  dataLoggingService.startQuestionObservation(paramsOrId, nowMsArg);
}

/**
  * Records finger/pointer/scroll activity (including gesture type, coordinates,
  * and touched option ID) on an active question before or during option lock.
  */
export function recordQuestionFingerActivity(
  questionId: string,
  metaOrNowMs?: number | FingerActivityMetadata
): void {
  dataLoggingService.recordFingerTouch(questionId, metaOrNowMs);
}

/**
  * Permanently locks the candidate's answer for a question, updates FSRS state,
  * and hands off the enriched finger-pattern & Read->Think->Lock payload to
  * dataLoggingService for /api/v1/telemetry/answer-lock ingestion.
  */
export function lockQuestionAnswerTelemetry(
  params:
    | {
        question: Question;
        selectedOptionId: string;
        mode: QuestionTimingTelemetry['sourceScreen'];
        nowMs?: number;
      }
    | {
        questionId: string;
        questionText: string;
        topicId?: string;
        subjectName: string;
        universityCode?: string;
        sourceScreen: QuestionTimingTelemetry['sourceScreen'];
        lockedOptionId: string;
        isCorrect: boolean;
        nowMs?: number;
      }
): QuestionTimingTelemetry {
  const hasQuestionObj = 'question' in params;
  const now = params.nowMs ?? Date.now();

  const { event } = dataLoggingService.commitAnswerLockAndDispatch(
    hasQuestionObj
      ? {
          question: params.question,
          selectedOptionId: params.selectedOptionId,
          sourceScreen: params.mode,
          nowMs: now,
        }
      : {
          questionId: params.questionId,
          questionText: params.questionText,
          topicId: params.topicId,
          subjectName: params.subjectName,
          universityCode: params.universityCode,
          sourceScreen: params.sourceScreen,
          selectedOptionId: params.lockedOptionId,
          isCorrect: params.isCorrect,
          nowMs: now,
        }
  );

  // Automatically update FSRS memory card from this real locked answer
  const existingCards = storageService.getFsrsCards();
  const currentCard =
    existingCards[event.questionId] || createInitialFSRSState(new Date(now));
  const fsrsRating = !event.isCorrect
    ? FSRSRating.again
    : event.classification === 'impulse_guess' ||
        event.classification === 'over_dwell'
      ? FSRSRating.hard
      : event.totalTimeMs <= 25_000
        ? FSRSRating.easy
        : FSRSRating.good;
  const updatedFsrs = reviewFSRSCard(currentCard, fsrsRating, new Date(now));
  storageService.saveFsrsCard(event.questionId, updatedFsrs.state);

  return event;
}

/**
  * Records a phone/app background switch or browser tab blur during study/exam.
  */
export function recordAppSwitchInterrupt(): void {
  storageService.incrementAppSwitchInterrupt();
}

/**
  * Records session start and completion for seriousness integrity tracking.
  */
export function recordStudySessionStart(): void {
  storageService.incrementSessionsStarted();
}

export function recordStudySessionComplete(): void {
  storageService.incrementSessionsCompleted();
}

/**
  * Attaches React Native AppState listener + DataLoggingService lifecycle outbox flush
  * across Android, iOS, and Web.
  */
export function initCandidateFocusMonitor(
  appState?: ReactNativeAppStateLike,
  platformName?: string
): void {
  dataLoggingService.attachLifecycleMonitor(appState, platformName);

  if (focusMonitorAttached) return;
  focusMonitorAttached = true;

  if (appState && typeof appState.addEventListener === 'function') {
    appState.addEventListener('change', (nextState: string) => {
      if (nextState === 'background' || nextState === 'inactive') {
        recordAppSwitchInterrupt();
      }
    });
  }

  if (!focusTickTimer) {
    focusTickTimer = setInterval(() => {
      if (!appState || !appState.currentState || appState.currentState === 'active') {
        storageService.addActiveFocusSeconds(10);
      }
    }, 10_000);
  }
}

/**
  * Computes the candidate's live Seriousness & Finger Telemetry evaluation profile
  * strictly from real user telemetry and AppState usage records (zero fake baselines).
  */
export function computeCandidateSeriousnessProfile(): CandidateSeriousnessProfile {
  const rawEvents = storageService.getQuestionTelemetryHistory();
  const events: QuestionTimingTelemetry[] = rawEvents.map((e) => ({
    ...e,
    eventId: e.eventId || e.id,
    behaviorClass: e.behaviorClass || e.classification,
    selectedOptionId: e.selectedOptionId || e.lockedOptionId,
  }));
  const usage = storageService.getAppUsageTelemetry();

  const lockedAnswersCount = events.length;
  const impulseTapCount = events.filter(
    (e) => e.classification === 'impulse_guess'
  ).length;
  const deliberateCount = events.filter(
    (e) => e.classification === 'deliberate'
  ).length;
  const overDwellCount = events.filter(
    (e) => e.classification === 'over_dwell'
  ).length;

  const avgReadMs =
    lockedAnswersCount > 0
      ? events.reduce((acc, e) => acc + e.readTimeMs, 0) / lockedAnswersCount
      : 0;
  const avgThinkMs =
    lockedAnswersCount > 0
      ? events.reduce((acc, e) => acc + e.thinkTimeMs, 0) / lockedAnswersCount
      : 0;
  const avgTotalMs = avgReadMs + avgThinkMs;

  const impulseGuessRatePercent =
    lockedAnswersCount > 0
      ? Math.round((impulseTapCount / lockedAnswersCount) * 100)
      : 0;

  const sessionsStarted = usage.sessionsStarted;
  const sessionsCompleted = Math.min(sessionsStarted, usage.sessionsCompleted);
  const sessionCompletionRatePercent =
    sessionsStarted > 0
      ? Math.round((sessionsCompleted / sessionsStarted) * 100)
      : 0;

  let seriousnessScore = 0;
  let statusLabel: string = 'Uncalibrated — Lock Answers to Train AETHER AI';

  if (lockedAnswersCount > 0 || sessionsStarted > 0) {
    const deliberateRatio =
      lockedAnswersCount > 0 ? deliberateCount / lockedAnswersCount : 0;
    const cadencePoints = Math.round(deliberateRatio * 55);
    const focusPenalty = Math.min(25, usage.appSwitchCount * 4);
    const focusPoints =
      lockedAnswersCount > 0 || usage.activeFocusSeconds > 0
        ? Math.max(0, 25 - focusPenalty)
        : 0;
    const completionPoints =
      sessionsStarted > 0
        ? Math.round((sessionCompletionRatePercent / 100) * 15)
        : lockedAnswersCount > 0
          ? 10
          : 0;
    const durationPoints = Math.min(
      5,
      Math.floor(usage.activeFocusSeconds / 120)
    );

    seriousnessScore = Math.max(
      0,
      Math.min(100, cadencePoints + focusPoints + completionPoints + durationPoints)
    );

    if (lockedAnswersCount === 0) {
      statusLabel = 'Session Active — Awaiting First Answer Lock';
    } else if (impulseGuessRatePercent >= 30) {
      statusLabel = 'Impulse Rushing (<2.5s Locks Detected)';
    } else if (usage.appSwitchCount >= 5) {
      statusLabel = 'Distracted — Frequent App Switching';
    } else if (seriousnessScore >= 75) {
      statusLabel = 'Focused & Disciplined';
    } else {
      statusLabel = 'Calibrating Telemetry Cadence';
    }
  }

  const avgReadTimeSeconds = Math.round(avgReadMs / 100) / 10;
  const avgThinkTimeSeconds = Math.round(avgThinkMs / 100) / 10;
  const avgTotalLockSeconds = Math.round(avgTotalMs / 100) / 10;
  const activeFocusMinutes = Math.floor(usage.activeFocusSeconds / 60);

  const aetherEvaluationNotes: string[] =
    lockedAnswersCount === 0
      ? [
          'Pipeline Ready: 0 questions locked so far. Start a Practice Drill, 1v1 Duel, or Live Exam so AETHER AI can capture your real Read → Think → Lock finger telemetry.',
          `Phone & App Focus Monitor: ${usage.activeFocusSeconds}s active foreground focus logged (${usage.appSwitchCount} app switches, ${sessionsCompleted}/${sessionsStarted} sessions completed).`,
        ]
      : [
          `Finger Lock Cadence (${lockedAnswersCount} real locks): Avg ${avgReadTimeSeconds}s stem reading + ${avgThinkTimeSeconds}s analytical deliberation before permanent answer lock.`,
          impulseGuessRatePercent > 15
            ? `Impulse Alert: ${impulseGuessRatePercent}% (${impulseTapCount}/${lockedAnswersCount}) of locked answers were tapped in <2.5s before full stem reading.`
            : `Discipline Verified: ${100 - impulseGuessRatePercent}% of answers locked after full stem comprehension (${deliberateCount}/${lockedAnswersCount} deliberate commits).`,
          `Phone & App Focus: ${usage.appSwitchCount} background switches logged across ${activeFocusMinutes}m (${usage.activeFocusSeconds}s) active focus (${sessionCompletionRatePercent}% session completion).`,
        ];

  const recentEvents = events.slice(0, 25);

  return {
    seriousnessScore,
    statusLabel,
    activeFocusSeconds: usage.activeFocusSeconds,
    activeFocusMinutes,
    appSwitchCount: usage.appSwitchCount,
    appSwitchInterrupts: usage.appSwitchCount,
    impulseTapCount,
    deliberateCount,
    overDwellCount,
    lockedAnswersCount,
    sessionsStarted,
    sessionsCompleted,
    sessionCompletionRatePercent,
    avgReadTimeSeconds,
    avgReadSeconds: avgReadTimeSeconds,
    avgThinkTimeSeconds,
    avgThinkSeconds: avgThinkTimeSeconds,
    avgTotalLockSeconds,
    impulseGuessRatePercent,
    recentEvents,
    recentTelemetry: recentEvents,
    aetherEvaluationNotes,
    evaluationNotes: aetherEvaluationNotes,
  };
}

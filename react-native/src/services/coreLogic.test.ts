import test from 'node:test';
import assert from 'node:assert/strict';
import {
  createInitialFSRSState,
  FSRSCardStatus,
  FSRSRating,
  reviewFSRSCard,
} from '../algorithms/fsrs';
import {
  computeDaysUntilAdmission,
  generateAdmissionRoadmap,
  synthesizeAetherPersonalPlan,
} from './admissionPlanService';
import {
  adjustExamSessionDuration,
  computeElapsedSeconds,
  computeRemainingSeconds,
  createExamSessionTiming,
  formatSecondsHMS,
  getDailyWindowStatus,
  shuffleQuestionOptions,
  summarizeExamProgress,
} from './examService';
import { QUESTION_BANK } from '../data/questionBank';
import { getRouteTransitionKey, resolveMotionConfig } from '../theme/motion';
import {
  buildSubjectRadarData,
  classifySpeedAccuracyQuadrant,
  computeLearnerKnowledgeProfile,
  computeUniversityReadiness,
} from './knowledgeProfileService';
import {
  exportConversationLedgerAsJsonl,
  synthesizeLocalAetherResponse,
} from './aiTutorService';
import {
  ANDROID_OAUTH_CREDENTIALS,
  isMatchingOAuthRedirectUrl,
  normalizeSupabaseAuthUser,
  parseOAuthCallbackParams,
  parseOAuthCallbackUrl,
  resolvePlatformRedirectUri,
} from './supabaseCallbackParser';
import {
  buildSupabaseProfileUpsertPayload,
  buildUserMetadataSummary,
  getSupabaseProfileCacheKey,
  hydrateUserProfileFromSupabaseRow,
  parseCachedSupabaseProfile,
  reconcileProfileForSupabaseSession,
  serializeCachedSupabaseProfile,
  shouldClearProfileOnSupabaseSignOut,
} from './profileAuthReconciler';
import {
  classifyQuestionTiming,
  computeCandidateSeriousnessProfile,
  computeExpectedMinReadMs,
  lockQuestionAnswerTelemetry,
  recordQuestionFingerActivity,
  startQuestionTelemetry,
} from './telemetryService';
import { PHASE_1_UNIVERSITY_CODES } from '../data/universities';
import { dataLoggingService, extractTouchPoint } from './dataLoggingService';
import {
  buildSubjectPerformanceTrends,
  computeD3TrendGeometry,
} from './performanceTrendService';

test('FSRS schedules longer interval for Easy than Again', () => {
  const now = new Date('2026-11-17T10:00:00Z');
  const initial = createInitialFSRSState(now);
  const again = reviewFSRSCard(initial, FSRSRating.again, now);
  const easy = reviewFSRSCard(initial, FSRSRating.easy, now);

  assert.equal(again.intervalDays, 1);
  assert.equal(again.state.status, FSRSCardStatus.learning);
  assert.ok(easy.intervalDays > again.intervalDays);
  assert.equal(easy.state.status, FSRSCardStatus.review);
});

test('AETHER AI admission countdown & personal plan synthesize custom syllabus and one unified personal exam', () => {
  const countdown = computeDaysUntilAdmission('BRACU', new Date('2026-11-18T00:00:00Z'));
  assert.ok(countdown.daysRemaining >= 1);

  const milestones = generateAdmissionRoadmap(
    'NSU',
    'engineering',
    20,
    ['ms_topic_1']
  );
  assert.equal(milestones.length, 12);
  assert.equal(milestones[0].status, 'completed');
  assert.equal(milestones[1].status, 'active');
  assert.equal(milestones.filter((m) => m.status === 'active').length, 1);

  const plan = synthesizeAetherPersonalPlan({
    universityCode: 'BRACU',
    category: 'engineering',
    completedIds: ['ms_topic_1'],
  });
  assert.ok(plan.daysRemaining >= 1);
  assert.ok(plan.customSyllabus.length >= 4);
  assert.equal(plan.unifiedPersonalExam.negativeMark, 0);
  assert.ok(plan.personalExamQuestions.length > 0);
});

test('Daily exam window status and HMS formatting stay accurate', () => {
  assert.equal(formatSecondsHMS(3665), '01:01:05');
  const openAtNoon = getDailyWindowStatus(new Date(2026, 10, 17, 12, 0, 0));
  assert.equal(openAtNoon.isOpen, true);
  assert.equal(openAtNoon.label, 'LIVE NOW');
});

test('Option shuffler preserves the single correct answer', () => {
  const sample = QUESTION_BANK[0];
  const shuffled = shuffleQuestionOptions(sample);
  const originalCorrectText = sample.options.find(
    (o) => o.id === sample.correctOptionId
  )?.text;
  const newCorrectText = shuffled.options.find(
    (o) => o.id === shuffled.correctOptionId
  )?.text;
  assert.equal(newCorrectText, originalCorrectText);
});

test('summarizeExamProgress computes answered, flagged, and unanswered indices accurately', () => {
  const sampleQs = [{ id: 'q1' }, { id: 'q2' }, { id: 'q3' }, { id: 'q4' }];
  const summary = summarizeExamProgress(
    sampleQs,
    { q1: 'A', q3: 'C' },
    { q2: true, q3: true, q4: false }
  );
  assert.equal(summary.total, 4);
  assert.equal(summary.answeredCount, 2);
  assert.equal(summary.flaggedCount, 2);
  assert.equal(summary.unansweredCount, 2);
  assert.deepEqual(summary.answeredIndices, [0, 2]);
  assert.deepEqual(summary.flaggedIndices, [1, 2]);
  assert.deepEqual(summary.unansweredIndices, [1, 3]);
});

test('Deadline-based exam timing preserves accurate countdown across backgrounding and mode switches', () => {
  const startMs = 1_700_000_000_000;
  const timing = createExamSessionTiming(1500, startMs); // 25 minutes
  assert.equal(timing.deadlineMs, startMs + 1_500_000);

  // Simulate 3 minutes (180s) spent in background
  const afterBackgroundMs = startMs + 180_000;
  assert.equal(computeRemainingSeconds(timing.deadlineMs, afterBackgroundMs), 1320);
  assert.equal(computeElapsedSeconds(timing.startedAtMs, timing.totalSeconds, afterBackgroundMs), 180);

  // Switching to OMR (+15m = 2400s total) preserves original startedAtMs and shifts deadlineMs
  const omrTiming = adjustExamSessionDuration(timing, 2400);
  assert.equal(omrTiming.startedAtMs, startMs);
  assert.equal(computeRemainingSeconds(omrTiming.deadlineMs, afterBackgroundMs), 2220);

  // Past deadline clamps cleanly to 0 remaining and totalSeconds elapsed
  const pastDeadlineMs = startMs + 3_000_000;
  assert.equal(computeRemainingSeconds(omrTiming.deadlineMs, pastDeadlineMs), 0);
  assert.equal(computeElapsedSeconds(omrTiming.startedAtMs, omrTiming.totalSeconds, pastDeadlineMs), 2400);
});

test('Motion system resolves Reanimated spring, layout transition, and reduced-motion tokens cleanly', () => {
  const standard = resolveMotionConfig(false);
  assert.equal(standard.reduceMotion, false);
  assert.equal(standard.pressDuration, 110);
  assert.equal(standard.pressedScale, 0.97);
  assert.equal(standard.modalAnimationType, 'fade');
  assert.equal(standard.enableScreenLayoutTransition, true);
  assert.equal(standard.springPress.stiffness, 340);
  assert.equal(standard.springRelease.stiffness, 280);
  assert.equal(standard.springLayout.damping, 22);

  const reduced = resolveMotionConfig(true);
  assert.equal(reduced.reduceMotion, true);
  assert.equal(reduced.pressDuration, 0);
  assert.equal(reduced.stateDuration, 0);
  assert.equal(reduced.screenEnterDuration, 0);
  assert.equal(reduced.screenExitDuration, 0);
  assert.equal(reduced.modalDuration, 0);
  assert.equal(reduced.pressedScale, 1);
  assert.equal(reduced.modalAnimationType, 'none');
  assert.equal(reduced.enableScreenLayoutTransition, false);

  assert.equal(getRouteTransitionKey({ name: 'dashboard', tab: 'home' }), 'dashboard:home');
  assert.equal(
    getRouteTransitionKey({
      name: 'liveExam',
      slug: 'daily-nsu-live',
      title: 'NSU Live',
      durationMinutes: 25,
      negativeMark: 0,
    }),
    'liveExam:daily-nsu-live'
  );
  assert.equal(
    getRouteTransitionKey({ name: 'knowledgeProfile', initialUniversityCode: 'NSU' }),
    'knowledgeProfile:NSU'
  );
  assert.equal(
    getRouteTransitionKey({ name: 'aiTutor', questionId: 'q_hm_001' }),
    'aiTutor:q_hm_001'
  );
});

test('Speed vs Accuracy quadrant classifier accurately flags impulse locks and mastery zones', () => {
  assert.equal(classifySpeedAccuracyQuadrant(85, 32, 50, 0), 'mastered_fast');
  assert.equal(classifySpeedAccuracyQuadrant(80, 65, 50, 0), 'accurate_slow');
  assert.equal(classifySpeedAccuracyQuadrant(55, 18, 50, 0), 'rushed_costly');
  assert.equal(classifySpeedAccuracyQuadrant(48, 70, 50, 0), 'critical_deficit');
});

test('360° Learner Knowledge Profile & Radar Chart enforce 0.00 negative marking and zero fake baseline until real user attempts arrive', () => {
  // 1. Uncalibrated state: zero fake attempts, zero fake mastery
  const uncalibrated = computeLearnerKnowledgeProfile({
    examHistory: [],
    topicAttempts: [],
    questionTelemetry: [],
    fsrsCards: {},
  });
  assert.equal(uncalibrated.totalAttempts, 0);
  assert.equal(uncalibrated.overallMasteryPercent, 0);
  assert.equal(uncalibrated.universityProjections.NSU.projectedScore, 0);
  assert.equal(uncalibrated.universityProjections.NSU.admissionProbabilityPercent, 0);

  // 2. Real user attempt ingested into pipeline
  const profile = computeLearnerKnowledgeProfile({
    topicAttempts: [
      {
        id: 'att_real_1',
        topicId: 'calculus_limits',
        subjectId: 'higher_math',
        questionId: 'q_hm_01',
        selectedOptionId: 'B',
        correctOptionId: 'B',
        isCorrect: true,
        timeSpentSeconds: 34,
        negativePenalty: 0,
        createdAt: new Date().toISOString(),
      },
    ],
  });
  assert.deepEqual(
    Object.keys(profile.universityProjections),
    ['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP']
  );
  assert.equal(Object.keys(profile.universityProjections).length, PHASE_1_UNIVERSITY_CODES.length);
  assert.equal(profile.subjects.length, 5);
  assert.ok(profile.topics.length >= 15);
  assert.equal(profile.totalAttempts, 1);
  assert.ok(profile.overallMasteryPercent > 0 && profile.overallMasteryPercent <= 100);
  assert.equal(profile.totalNegativeMarksLost, 0);

  for (const code of PHASE_1_UNIVERSITY_CODES) {
    const proj = computeUniversityReadiness(code, profile.subjects, profile.topics);
    assert.equal(proj.negativeMarkingPenalty, 0);
    assert.equal(proj.estimatedNetLossFromNegatives, 0);
  }

  const radarPoints = buildSubjectRadarData(profile.subjects, 'BRACU');
  assert.equal(radarPoints.length, 5);
  assert.equal(radarPoints[0].subject, 'Higher Math');
  assert.equal(radarPoints[0].targetGoal, 80);
  assert.equal(radarPoints[0].gap, radarPoints[0].currentMastery - radarPoints[0].targetGoal);
});

test('3-Phase Finger Timing Telemetry (Read -> Think -> Lock) and Candidate Seriousness Score evaluate learner behavior', () => {
  const sampleQ = QUESTION_BANK[0];
  const minReadMs = computeExpectedMinReadMs(sampleQ);
  assert.ok(minReadMs >= 2200);

  assert.equal(classifyQuestionTiming(1200, minReadMs, 45), 'impulse_guess');
  assert.equal(classifyQuestionTiming(18000, minReadMs, 45), 'deliberate');
  assert.equal(classifyQuestionTiming(120000, minReadMs, 45), 'over_dwell');

  startQuestionTelemetry(sampleQ.id, 1_000_000);
  recordQuestionFingerActivity(sampleQ.id, 1_004_200);
  const lockedEvent = lockQuestionAnswerTelemetry({
    question: sampleQ,
    selectedOptionId: sampleQ.correctOptionId,
    mode: 'live_exam',
    nowMs: 1_016_500,
  });

  assert.equal(lockedEvent.readTimeMs, 4200);
  assert.equal(lockedEvent.thinkTimeMs, 12300);
  assert.equal(lockedEvent.totalTimeMs, 16500);
  assert.equal(lockedEvent.behaviorClass, 'deliberate');
  assert.equal(lockedEvent.isCorrect, true);

  const seriousness = computeCandidateSeriousnessProfile();
  assert.ok(seriousness.seriousnessScore >= 0 && seriousness.seriousnessScore <= 100);
  assert.ok(seriousness.evaluationNotes.length > 0);
});

test('AETHER AI Engine synthesizes direct step-by-step solutions and exports zero-loss JSONL ledger', () => {
  const response = synthesizeLocalAetherResponse({
    userMessage: 'Solve the derivative of y = e^(2x) ln(x) at x = 1',
    mode: 'aether_solver',
    context: {
      topicId: 'calculus_diff',
      topicName: 'Differentiation & Tangents',
      subjectName: 'Higher Mathematics',
      questionId: 'q_hm_02',
      pickedOption: 'A',
    },
    priorAssistantTurnsCount: 0,
  });
  assert.ok(response.content.includes('AETHER AI'));
  assert.ok(!response.content.toLowerCase().includes('socratic'));
  assert.equal(response.aetherStage, 'direct_solve');

  const jsonl = exportConversationLedgerAsJsonl([
    {
      threadId: 'conv_test_1',
      userId: 'guest_preview_01',
      title: 'Test Thread',
      mode: 'aether_solver',
      universityCode: 'BRACU',
      topicId: 'calculus_diff',
      modelEndpointUsed: 'aether-ai-7b-prep404 (https://a4000-cluster.fourzerofour.tech)',
      createdAt: '2026-11-18T00:00:00Z',
      updatedAt: '2026-11-18T00:01:00Z',
      isResolved: true,
      messages: [
        {
          messageId: 'm1',
          threadId: 'conv_test_1',
          role: 'user',
          content: 'How do I solve this derivative?',
          aetherStage: 'direct_solve',
          modelSource: 'cloudflare_local_gpu',
          latencyMs: 0,
          tokenEstimate: 12,
          timestamp: '2026-11-18T00:00:00Z',
        },
        {
          messageId: 'm2',
          threadId: 'conv_test_1',
          role: 'assistant',
          content: response.content,
          aetherStage: 'direct_solve',
          modelSource: 'cloudflare_local_gpu',
          latencyMs: 140,
          tokenEstimate: response.tokenEstimate,
          timestamp: '2026-11-18T00:00:01Z',
        },
      ],
    },
  ]);

  const parsed = JSON.parse(jsonl.trim());
  assert.equal(parsed.thread_id, 'conv_test_1');
  assert.equal(parsed.messages.length, 3); // system + user + assistant
});

test('dataLoggingService captures finger touch trace, Read->Think->Lock cadence, and builds aether-telemetry-v2 payload', () => {
  dataLoggingService.resetOutboxForTests();
  dataLoggingService.setRuntimePlatform('android');

  assert.deepEqual(
    extractTouchPoint({ nativeEvent: { locationX: 124.6, locationY: 312.2 } }),
    { x: 125, y: 312 }
  );
  assert.deepEqual(
    extractTouchPoint({ nativeEvent: { pageX: 48.4, pageY: 200.9 } }),
    { x: 48, y: 201 }
  );
  assert.deepEqual(extractTouchPoint(null), {});

  const sampleQ = QUESTION_BANK[0];
  const renderMs = 2_000_000;
  dataLoggingService.startQuestionObservation({
    questionId: sampleQ.id,
    questionText: sampleQ.text,
    topicId: sampleQ.topicId,
    subjectName: sampleQ.subjectName,
    universityCode: 'BRACU',
    sourceScreen: 'practice',
    nowMs: renderMs,
  });

  // Noise touch inside 120ms debounce window should NOT lock readTimeMs prematurely
  dataLoggingService.recordFingerTouch(sampleQ.id, {
    kind: 'touch_move',
    x: 10,
    y: 20,
    nowMs: renderMs + 50,
  });
  // First real scroll past 120ms sets firstFingerActivityMs
  dataLoggingService.recordFingerTouch(sampleQ.id, {
    kind: 'scroll',
    x: 120,
    y: 340,
    nowMs: renderMs + 3_200,
  });
  dataLoggingService.recordFingerTouch(sampleQ.id, {
    kind: 'press_in',
    optionId: sampleQ.correctOptionId,
    x: 184,
    y: 512,
    nowMs: renderMs + 9_200,
  });

  const { event, payload } = dataLoggingService.commitAnswerLockAndDispatch({
    question: sampleQ,
    selectedOptionId: sampleQ.correctOptionId,
    sourceScreen: 'practice',
    nowMs: renderMs + 12_200,
    skipNetworkDispatch: true,
  });

  assert.equal(event.readTimeMs, 3_200);
  assert.equal(event.thinkTimeMs, 9_000);
  assert.equal(event.totalTimeMs, 12_200);
  assert.equal(event.classification, 'deliberate');
  assert.equal(event.platform, 'android');
  assert.ok(event.touchPattern);
  assert.equal(event.touchPattern.scrollCount, 1);
  assert.equal(event.touchPattern.pressInCount, 2); // press_in + option_lock
  assert.equal(event.touchPattern.totalTouchCount, 4); // 3 touches + option_lock
  assert.equal(event.touchPattern.hesitationGapMs, 9_000);
  assert.equal(event.touchPattern.touchCadenceLabel, 'scrolled_scanning');
  assert.equal(event.touchPattern.touchTrace[0].kind, 'render');
  assert.equal(event.touchPattern.touchTrace[2].kind, 'scroll');
  assert.equal(event.touchPattern.touchTrace[3].optionId, sampleQ.correctOptionId);
  assert.equal(event.touchPattern.touchTrace[event.touchPattern.touchTrace.length - 1].kind, 'option_lock');

  assert.equal(payload.schemaVersion, 'aether-telemetry-v2');
  assert.equal(payload.platform, 'android');
  assert.equal(payload.lockedOptionId, sampleQ.correctOptionId);
  assert.equal(payload.touchPattern.touchCadenceLabel, 'scrolled_scanning');
});

test('dataLoggingService queues offline answer locks and retries with backoff until transport succeeds', async () => {
  dataLoggingService.resetOutboxForTests();
  dataLoggingService.setRuntimePlatform('ios');

  const sampleQ = QUESTION_BANK[1] || QUESTION_BANK[0];
  const renderMs = 3_000_000;
  dataLoggingService.startQuestionObservation({
    questionId: sampleQ.id,
    questionText: sampleQ.text,
    subjectName: sampleQ.subjectName,
    sourceScreen: 'live_exam',
    nowMs: renderMs,
  });
  dataLoggingService.recordFingerTouch(sampleQ.id, {
    kind: 'press_in',
    optionId: 'A',
    x: 90,
    y: 410,
    nowMs: renderMs + 4_000,
  });

  const { payload } = dataLoggingService.commitAnswerLockAndDispatch({
    question: sampleQ,
    selectedOptionId: 'A',
    sourceScreen: 'live_exam',
    nowMs: renderMs + 10_000,
    skipNetworkDispatch: true,
  });

  dataLoggingService.enqueueAndSend(payload);
  // Allow background auto-flush attempt to settle in Node test runtime
  await new Promise((resolve) => setTimeout(resolve, 25));

  const failedResult = await dataLoggingService.flushOutbox(async () => false);
  assert.equal(failedResult.delivered, 0);
  assert.equal(failedResult.remaining, 1);

  const queuedStatus = dataLoggingService.getQueueStatus();
  assert.equal(queuedStatus.pendingCount, 1);
  assert.ok(queuedStatus.failedAttemptsCount >= 1);

  let capturedUrl = '';
  let capturedPlatform = '';
  const successResult = await dataLoggingService.flushOutbox(async (url, body) => {
    capturedUrl = url;
    capturedPlatform = body.platform;
    return true;
  });

  assert.equal(successResult.delivered, 1);
  assert.equal(successResult.remaining, 0);
  assert.ok(capturedUrl.endsWith('/telemetry/answer-lock'));
  assert.equal(capturedPlatform, 'ios');

  const drainedStatus = dataLoggingService.getQueueStatus();
  assert.equal(drainedStatus.pendingCount, 0);
  assert.equal(drainedStatus.transmittedCount, 1);
  assert.equal(drainedStatus.lastError, undefined);
});

test('MistakeVault D3 performance trend service enforces zero fake data and computes multi-subject D3 SVG curves', () => {
  // 1. Empty state must never fabricate fake baseline trend points
  const empty = buildSubjectPerformanceTrends({
    examHistory: [],
    topicAttempts: [],
    questionTelemetry: [],
  });
  assert.equal(empty.hasData, false);
  assert.equal(empty.totalAttempts, 0);
  assert.equal(empty.subjectSeries.length, 0);

  const emptyGeo = computeD3TrendGeometry({
    seriesList: [],
    timelineKeys: [],
    timelineLabels: {},
    width: 360,
    height: 220,
  });
  assert.equal(emptyGeo.yTicks.length, 5);
  assert.equal(emptyGeo.renderedSeries.length, 0);

  // 2. Real multi-day exams across Higher Math and Physics produce accurate recovery deltas & valid D3 SVG paths
  const hmQs = QUESTION_BANK.filter((q) => q.subjectId === 'higher_math').slice(0, 2);
  const physQs = QUESTION_BANK.filter((q) => q.subjectId === 'physics').slice(0, 2);
  assert.equal(hmQs.length, 2);
  assert.equal(physQs.length, 2);

  const wrongOptionFor = (correct: string) => (correct === 'A' ? 'B' : 'A');

  const trends = buildSubjectPerformanceTrends({
    examHistory: [
      {
        id: 'exam_day1',
        examSlug: 'nsu-diag-1',
        title: 'NSU Diagnostic 1',
        track: 'NSU',
        mode: 'inApp',
        score: 2,
        totalQuestions: 4,
        correctCount: 2,
        wrongCount: 2,
        unansweredCount: 0,
        timeTakenSeconds: 180,
        submittedAt: '2026-11-17T10:00:00Z',
        userAnswers: {
          [hmQs[0].id]: hmQs[0].correctOptionId, // right
          [hmQs[1].id]: wrongOptionFor(hmQs[1].correctOptionId), // wrong -> 50% HM
          [physQs[0].id]: physQs[0].correctOptionId, // right
          [physQs[1].id]: wrongOptionFor(physQs[1].correctOptionId), // wrong -> 50% Phys
        },
        questionIds: [hmQs[0].id, hmQs[1].id, physQs[0].id, physQs[1].id],
      },
      {
        id: 'exam_day2',
        examSlug: 'nsu-retest-2',
        title: 'Adaptive Re-Test 2',
        track: 'NSU',
        mode: 'practice',
        score: 3,
        totalQuestions: 4,
        correctCount: 3,
        wrongCount: 1,
        unansweredCount: 0,
        timeTakenSeconds: 150,
        submittedAt: '2026-11-19T10:00:00Z',
        userAnswers: {
          [hmQs[0].id]: hmQs[0].correctOptionId, // right
          [hmQs[1].id]: hmQs[1].correctOptionId, // right -> 100% HM (+50%)
          [physQs[0].id]: physQs[0].correctOptionId, // right
          [physQs[1].id]: wrongOptionFor(physQs[1].correctOptionId), // wrong -> 50% Phys (0%)
        },
        questionIds: [hmQs[0].id, hmQs[1].id, physQs[0].id, physQs[1].id],
      },
    ],
    topicAttempts: [],
    questionTelemetry: [],
  });

  assert.equal(trends.hasData, true);
  assert.equal(trends.totalAttempts, 8);
  assert.equal(trends.totalMistakes, 3);
  assert.equal(trends.timelineKeys.length, 2);
  assert.equal(trends.overallSeries.points[0].accuracyPercent, 50);
  assert.equal(trends.overallSeries.points[1].accuracyPercent, 75);
  assert.equal(trends.overallSeries.deltaPercent, 25);

  const hmSeries = trends.subjectSeries.find((s) => s.subjectId === 'higher_math');
  const physSeries = trends.subjectSeries.find((s) => s.subjectId === 'physics');
  assert.ok(hmSeries);
  assert.ok(physSeries);
  assert.equal(hmSeries.latestAccuracy, 100);
  assert.equal(hmSeries.deltaPercent, 50);
  assert.equal(physSeries.latestAccuracy, 50);
  assert.equal(physSeries.deltaPercent, 0);

  const geo = computeD3TrendGeometry({
    seriesList: trends.subjectSeries,
    timelineKeys: trends.timelineKeys,
    timelineLabels: trends.timelineLabels,
    width: 480,
    height: 236,
  });

  assert.equal(geo.xTicks.length, 2);
  assert.equal(geo.renderedSeries.length, 2);
  for (const rs of geo.renderedSeries) {
    assert.ok(rs.linePath.startsWith('M'), 'D3 line generator must emit valid SVG M path');
    assert.ok(rs.areaPath.startsWith('M'), 'D3 area generator must emit valid SVG M path');
    assert.ok(!rs.linePath.includes('NaN'), 'D3 path must never contain NaN');
    assert.equal(rs.plottedPoints.length, 2);
  }
});

test('Supabase Google OAuth callback parser handles Web PKCE, Android deep links, implicit hash tokens, and user normalization', () => {
  // 1. Web popup PKCE callback
  const pkce = parseOAuthCallbackParams('?code=pkce_code_987654&state=xyz', '');
  assert.equal(pkce.code, 'pkce_code_987654');
  assert.equal(pkce.error, undefined);

  // 2. Android deep link callback (com.rxxxeron.prep404://login-callback)
  const androidDeepLink = parseOAuthCallbackUrl(
    'com.rxxxeron.prep404://login-callback?code=android_pkce_404'
  );
  assert.equal(androidDeepLink.code, 'android_pkce_404');

  // 3. Implicit fragment callback
  const implicit = parseOAuthCallbackParams(
    '',
    '#access_token=jwt_abc&refresh_token=ref_xyz&token_type=bearer'
  );
  assert.equal(implicit.accessToken, 'jwt_abc');
  assert.equal(implicit.refreshToken, 'ref_xyz');

  // 4. Error callback
  const errCb = parseOAuthCallbackParams(
    '?error=access_denied&error_description=User+cancelled+Google+consent',
    ''
  );
  assert.equal(errCb.error, 'access_denied');
  assert.equal(errCb.errorDescription, 'User cancelled Google consent');

  // 5. User normalization
  const normalized = normalizeSupabaseAuthUser({
    id: 'sb_uid_001',
    email: 'rhrakibulh795@gmail.com',
    user_metadata: {
      full_name: 'Rakibul Hasan',
      avatar_url: 'https://lh3.googleusercontent.com/a/example',
    },
    app_metadata: { provider: 'google' },
  });
  assert.equal(normalized.id, 'sb_uid_001');
  assert.equal(normalized.email, 'rhrakibulh795@gmail.com');
  assert.equal(normalized.name, 'Rakibul Hasan');
  assert.equal(normalized.provider, 'google');
  assert.equal(normalized.avatarUrl, 'https://lh3.googleusercontent.com/a/example');

  // 6. Android OAuth credentials & cross-platform redirect URI resolution
  assert.equal(
    ANDROID_OAUTH_CREDENTIALS.androidClientId,
    '560610133772-03ij6u6cqo2pk1t2tbjvmpqrl79md609.apps.googleusercontent.com'
  );
  assert.equal(
    resolvePlatformRedirectUri({ platformOS: 'android' }),
    'com.rxxxeron.prep404://login-callback'
  );
  assert.equal(
    resolvePlatformRedirectUri({
      platformOS: 'web',
      webOrigin: 'https://ais-dev-mxvnmhuoufm47ceoqf3wuz-1005573902453.asia-east1.run.app/',
    }),
    'https://ais-dev-mxvnmhuoufm47ceoqf3wuz-1005573902453.asia-east1.run.app/auth/callback'
  );
  assert.equal(
    isMatchingOAuthRedirectUrl(
      'com.rxxxeron.prep404://login-callback/?code=abc123',
      'com.rxxxeron.prep404://login-callback'
    ),
    true
  );
  assert.equal(
    isMatchingOAuthRedirectUrl(
      'https://evil.example.com/login-callback?code=abc123',
      'com.rxxxeron.prep404://login-callback'
    ),
    false
  );
});

test('Supabase auth state profile reconciler merges USER_UPDATED metadata, isolates account switches, and cleans up on SIGNED_OUT', () => {
  const baseProfile = {
    id: 'uid_user_a',
    name: 'Rakibul Hasan',
    phone: '01712345678',
    email: 'old@gmail.com',
    authProvider: 'google' as const,
    medium: 'bangla' as const,
    academicBatch: "HSC '25",
    institutionName: 'Notre Dame College, Dhaka',
    studyStreakDays: 3,
    targetSelections: { brac: ['brac_cse'] },
  };

  // 1. Remote profile + USER_UPDATED fresh email/avatar merges cleanly and flags sync
  const updated = reconcileProfileForSupabaseSession({
    user: {
      id: 'uid_user_a',
      email: 'rhrakibulh795@gmail.com',
      name: 'Rakibul Hasan',
      avatarUrl: 'https://lh3.googleusercontent.com/a/new-avatar',
      provider: 'google',
    },
    localProfile: null,
    remoteProfile: baseProfile,
  });
  assert.ok(updated.profile);
  assert.equal(updated.profile.email, 'rhrakibulh795@gmail.com');
  assert.equal(updated.profile.avatarUrl, 'https://lh3.googleusercontent.com/a/new-avatar');
  assert.equal(updated.profile.authProvider, 'google');
  assert.equal(updated.pendingIdentity, null);
  assert.equal(updated.shouldSyncBackToSupabase, true);

  // 2. Switching to User B must NEVER inherit User A's cached localProfile
  const switched = reconcileProfileForSupabaseSession({
    user: {
      id: 'uid_user_b',
      email: 'new.candidate@gmail.com',
      name: 'Nusrat Jahan',
      provider: 'google',
    },
    localProfile: baseProfile,
    remoteProfile: null,
  });
  assert.equal(switched.profile, null);
  assert.ok(switched.pendingIdentity);
  assert.equal(switched.pendingIdentity.userId, 'uid_user_b');
  assert.equal(switched.pendingIdentity.email, 'new.candidate@gmail.com');
  assert.equal(switched.pendingIdentity.name, 'Nusrat Jahan');

  // 3. SIGNED_OUT clears Google session/profile, but does not wipe an active Guest session
  assert.equal(
    shouldClearProfileOnSupabaseSignOut({ provider: 'google', isGuest: false }, baseProfile),
    true
  );
  assert.equal(
    shouldClearProfileOnSupabaseSignOut({ provider: 'guest', isGuest: true }, {
      ...baseProfile,
      id: 'guest_preview_01',
      authProvider: 'guest',
    }),
    false
  );
});

test('Supabase profiles table hydration & upsert sync complete user metadata (preferred university track, academic level, preferences)', () => {
  // 1. Relational-column-only Supabase row (no profile_json) hydrates full UserProfile cleanly
  const hydratedRelational = hydrateUserProfileFromSupabaseRow({
    id: 'sb_uid_900',
    email: 'rhrakibulh795@gmail.com',
    full_name: 'Rakibul Hasan',
    phone: '01711002233',
    preferred_university_track: 'BRACU',
    current_academic_level: "HSC '25 · Science (NCTB English Version)",
    study_medium: 'bangla',
    nctb_version: 'english',
    academic_batch: "HSC '25",
    institution_name: 'Dhaka Residential Model College',
    study_streak_days: 7,
    preferred_language: 'bangla',
    preferred_theme: 'dark',
    target_selections: { brac: ['brac_cse'], nsu: ['nsu_cse'] },
    updated_at: '2026-11-19T10:00:00Z',
  });
  assert.ok(hydratedRelational);
  assert.equal(hydratedRelational.preferredUniversityTrack, 'BRACU');
  assert.equal(
    hydratedRelational.currentAcademicLevel,
    "HSC '25 · Science (NCTB English Version)"
  );
  assert.equal(hydratedRelational.preferredLanguage, 'bangla');
  assert.equal(hydratedRelational.preferredTheme, 'dark');
  assert.equal(hydratedRelational.studyStreakDays, 7);

  // 2. Relational columns override stale values inside profile_json
  const hydratedOverride = hydrateUserProfileFromSupabaseRow({
    id: 'sb_uid_900',
    preferred_university_track: 'AUST',
    current_academic_level: 'A-Level 2025 · Pearson Edexcel',
    study_medium: 'english',
    english_curriculum: 'edexcel',
    profile_json: {
      id: 'sb_uid_900',
      name: 'Rakibul Hasan',
      preferredUniversityTrack: 'NSU',
      currentAcademicLevel: "HSC '25",
      medium: 'bangla',
      academicBatch: "HSC '25",
      institutionName: 'Sunbeams School',
      studyStreakDays: 4,
      targetSelections: { aust: ['aust_eng'], nsu: ['nsu_cse'] },
    },
  });
  assert.ok(hydratedOverride);
  assert.equal(hydratedOverride.preferredUniversityTrack, 'AUST');
  assert.equal(
    hydratedOverride.currentAcademicLevel,
    'A-Level 2025 · Pearson Edexcel'
  );
  assert.equal(hydratedOverride.medium, 'english');
  assert.equal(hydratedOverride.englishCurriculum, 'edexcel');

  // 3. Upsert payload writes all relational metadata columns + profile_json
  const payload = buildSupabaseProfileUpsertPayload(
    'sb_uid_900',
    hydratedRelational,
    'fallback@example.com'
  );
  assert.equal(payload.preferred_university_track, 'BRACU');
  assert.equal(
    payload.current_academic_level,
    "HSC '25 · Science (NCTB English Version)"
  );
  assert.equal(payload.study_medium, 'bangla');
  assert.equal(payload.academic_batch, "HSC '25");
  assert.equal(payload.institution_name, 'Dhaka Residential Model College');
  assert.equal(payload.preferred_language, 'bangla');
  assert.equal(payload.preferred_theme, 'dark');

  // 4. Metadata summary exposes normalized track, academic level & university codes
  const summary = buildUserMetadataSummary(
    hydratedRelational,
    '2026-11-19T10:00:00Z'
  );
  assert.ok(summary);
  assert.equal(summary.preferredUniversityTrack, 'BRACU');
  assert.deepEqual(summary.targetUniversityCodes, ['BRACU', 'NSU']);
  assert.equal(summary.syncedAt, '2026-11-19T10:00:00Z');

  // 5. AsyncStorage profile cache serialization, userId isolation & corruption guard
  const cacheKey = getSupabaseProfileCacheKey('sb_uid_900');
  assert.equal(cacheKey, 'prep404_supabase_profile_cache_v1:sb_uid_900');

  const serialized = serializeCachedSupabaseProfile({
    version: 1,
    userId: 'sb_uid_900',
    cachedAt: '2026-11-19T10:05:00Z',
    basicUserInfo: {
      id: 'sb_uid_900',
      email: 'rhrakibulh795@gmail.com',
      name: 'Rakibul Hasan',
      provider: 'google',
    },
    profile: hydratedRelational,
  });

  const restored = parseCachedSupabaseProfile(serialized, 'sb_uid_900');
  assert.ok(restored);
  assert.equal(restored.basicUserInfo.email, 'rhrakibulh795@gmail.com');
  assert.equal(restored.profile?.preferredUniversityTrack, 'BRACU');
  assert.equal(restored.profile?.institutionName, 'Dhaka Residential Model College');

  // Different userId must NEVER read another user's cached profile
  assert.equal(parseCachedSupabaseProfile(serialized, 'sb_uid_other'), null);
  // Corrupted JSON must cleanly return null
  assert.equal(parseCachedSupabaseProfile('{not-valid-json', 'sb_uid_900'), null);
});








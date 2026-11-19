import {
  DailyExamDetails,
  ExamHistoryItem,
  ExamSubmissionResult,
  Question,
  QuestionFeedback,
} from '../types';
import { MODEL_TESTS_CATALOG, QUESTION_BANK, pickQuestionsForExam } from '../data/questionBank';
import { storageService } from './storageService';

export function shuffleQuestionOptions(question: Question): Question {
  if (question.options.length < 2) return question;
  const hasRelational = question.options.some((o) => {
    const t = o.text.toLowerCase();
    return (
      t.includes('all of the above') ||
      t.includes('none of the above') ||
      t.includes('both ') ||
      t.includes('neither ') ||
      t.includes('উপরের সব') ||
      t.includes('কোনটিই নয়')
    );
  });
  if (hasRelational) return question;

  const texts = question.options.map((o) => ({
    text: o.text,
    wasCorrect:
      o.isCorrect || o.id.toUpperCase() === question.correctOptionId.toUpperCase(),
  }));

  for (let i = texts.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [texts[i], texts[j]] = [texts[j], texts[i]];
  }

  const letters = ['A', 'B', 'C', 'D', 'E'];
  let newCorrectId = question.correctOptionId;
  const newOptions = texts.map((item, idx) => {
    const id = letters[idx] || String(idx + 1);
    if (item.wasCorrect) newCorrectId = id;
    return {
      id,
      text: item.text,
      isCorrect: item.wasCorrect,
    };
  });

  return {
    ...question,
    options: newOptions,
    correctOptionId: newCorrectId,
  };
}

function extractTrackFromSlug(slug: string): string {
  const s = slug.toUpperCase();
  for (const code of ['BRACU', 'BRAC', 'NSU', 'AIUB', 'AUST', 'EWU', 'IUB', 'UIU', 'UAP']) {
    if (s.includes(code)) return code === 'BRAC' ? 'BRACU' : code;
  }
  return 'NSU';
}

export function buildExamDetails(params: {
  slug: string;
  title?: string;
  track?: string;
  durationMinutes?: number;
  negativeMark?: number;
  initialQuestions?: Question[];
}): DailyExamDetails {
  const catalogMatch = MODEL_TESTS_CATALOG.find(
    (m) => m.slug === params.slug || m.id === params.slug
  );
  const track = params.track || catalogMatch?.track || extractTrackFromSlug(params.slug);
  const durationMinutes = params.durationMinutes || catalogMatch?.durationMinutes || 30;
  const negativeMark = params.negativeMark ?? catalogMatch?.negativeMark ?? 0.0;

  const rawQuestions =
    params.initialQuestions && params.initialQuestions.length > 0
      ? params.initialQuestions
      : pickQuestionsForExam(track, catalogMatch?.questionCount || 15);

  const questions = rawQuestions.map((q) => shuffleQuestionOptions(q));

  return {
    id: catalogMatch?.id || params.slug,
    slug: params.slug,
    title: params.title || catalogMatch?.title || `${track} Live Model Test`,
    track,
    examType: catalogMatch?.examType || 'daily_live',
    durationMinutes,
    totalMarks: questions.length,
    negativeMark,
    questionCount: questions.length,
    shareableUrl: `https://prep404.app/m/${params.slug}`,
    questions,
    isLiveNow: true,
    activeCandidates: catalogMatch?.activeCandidates || 1240,
  };
}

export function scoreAndPersistExam(params: {
  exam: DailyExamDetails;
  userAnswers: Record<string, string>;
  timeTakenSeconds: number;
  candidateName: string;
  mode: 'inApp' | 'omrBubble' | 'practice';
  isPractice: boolean;
}): { result: ExamSubmissionResult; historyItem: ExamHistoryItem } {
  const { exam, userAnswers, timeTakenSeconds, candidateName, mode, isPractice } = params;
  let correctCount = 0;
  let wrongCount = 0;
  let unansweredCount = 0;

  const feedback: QuestionFeedback[] = exam.questions.map((q) => {
    const selected = userAnswers[q.id];
    const correct = q.correctOptionId;
    if (!selected) {
      unansweredCount++;
      return {
        questionId: q.id,
        selectedOption: undefined,
        correctOption: correct,
        isCorrect: false,
        explanation: q.explanation,
        hints: q.hints,
      };
    }
    const isCorrect = selected.toUpperCase() === correct.toUpperCase();
    if (isCorrect) correctCount++;
    else wrongCount++;
    return {
      questionId: q.id,
      selectedOption: selected,
      correctOption: correct,
      isCorrect,
      explanation: q.explanation,
      hints: q.hints,
    };
  });

  const rawScore = correctCount * 1.0 - wrongCount * exam.negativeMark;
  const score = Math.max(0, Number(rawScore.toFixed(2)));
  const totalParticipants = exam.activeCandidates || 1240;
  const pct = exam.questions.length > 0 ? score / exam.questions.length : 0;
  const estimatedRank = Math.max(
    1,
    Math.min(totalParticipants, Math.round((1 - pct * 0.92) * totalParticipants))
  );

  const historyItem: ExamHistoryItem = {
    id: `sub_${Date.now()}`,
    examSlug: exam.slug,
    title: exam.title,
    track: exam.track,
    mode: isPractice ? 'practice' : mode,
    score,
    totalQuestions: exam.questions.length,
    correctCount,
    wrongCount,
    unansweredCount,
    timeTakenSeconds,
    rank: isPractice ? undefined : estimatedRank,
    totalParticipants: isPractice ? undefined : totalParticipants,
    submittedAt: new Date().toISOString(),
    isDailyLive: exam.slug.includes('daily'),
    userAnswers,
    questionIds: exam.questions.map((q) => q.id),
  };

  storageService.addExamHistory(historyItem);

  const shareableResultText = isPractice
    ? `I practiced "${exam.title}" on Prep404 and scored ${score.toFixed(2)}/${exam.questions.length}!`
    : `I scored ${score.toFixed(2)}/${exam.questions.length} (Rank #${estimatedRank} of ${totalParticipants}) on ${exam.title} on Prep404!`;

  return {
    result: {
      submissionId: historyItem.id,
      candidateName,
      score,
      totalMarks: exam.questions.length,
      correctCount,
      wrongCount,
      unansweredCount,
      timeTakenSeconds,
      rank: estimatedRank,
      totalParticipants,
      shareableResultText,
      feedback,
      isPractice,
    },
    historyItem,
  };
}

export interface WeakTopicSummary {
  topicId: string;
  topicName: string;
  subjectName: string;
  wrongCount: number;
  skippedCount: number;
  deficitScore: number;
  rank: number;
}

export function computeMistakeVault(): {
  mistakes: Question[];
  skipped: Question[];
  weakTopics: WeakTopicSummary[];
} {
  const history = storageService.getExamHistory();
  const qMap = new Map<string, Question>(QUESTION_BANK.map((q) => [q.id, q]));

  const mistakeIds = new Set<string>();
  const skippedIds = new Set<string>();
  const topicStats = new Map<
    string,
    { topicId: string; topicName: string; subjectName: string; wrongCount: number; skippedCount: number }
  >();

  for (const h of history) {
    for (const qId of h.questionIds) {
      const q = qMap.get(qId);
      if (!q) continue;
      const tId = q.topicId || q.subjectId;
      const tName = q.topicName || q.subjectName;
      const stat = topicStats.get(tId) || {
        topicId: tId,
        topicName: tName,
        subjectName: q.subjectName,
        wrongCount: 0,
        skippedCount: 0,
      };
      const ans = h.userAnswers[qId];
      if (!ans) {
        skippedIds.add(qId);
        stat.skippedCount++;
      } else if (ans.toUpperCase() !== q.correctOptionId.toUpperCase()) {
        mistakeIds.add(qId);
        stat.wrongCount++;
      }
      if (stat.wrongCount > 0 || stat.skippedCount > 0) {
        topicStats.set(tId, stat);
      }
    }
  }

  const weakTopics: WeakTopicSummary[] = Array.from(topicStats.values())
    .map((s) => ({
      ...s,
      deficitScore: s.wrongCount * 3 + s.skippedCount,
      rank: 0,
    }))
    .sort((a, b) => b.deficitScore - a.deficitScore)
    .map((s, idx) => ({ ...s, rank: idx + 1 }));

  return {
    mistakes: Array.from(mistakeIds).map((id) => qMap.get(id)!).filter(Boolean),
    skipped: Array.from(skippedIds).map((id) => qMap.get(id)!).filter(Boolean),
    weakTopics,
  };
}

export interface ExamProgressSummary {
  total: number;
  answeredCount: number;
  flaggedCount: number;
  unansweredCount: number;
  answeredIndices: number[];
  flaggedIndices: number[];
  unansweredIndices: number[];
}

export function summarizeExamProgress(
  questions: Pick<Question, 'id'>[],
  answers: Record<string, string>,
  flaggedIds: Record<string, boolean>
): ExamProgressSummary {
  const answeredIndices: number[] = [];
  const flaggedIndices: number[] = [];
  const unansweredIndices: number[] = [];

  questions.forEach((q, idx) => {
    if (answers[q.id]) answeredIndices.push(idx);
    else unansweredIndices.push(idx);
    if (flaggedIds[q.id]) flaggedIndices.push(idx);
  });

  return {
    total: questions.length,
    answeredCount: answeredIndices.length,
    flaggedCount: flaggedIndices.length,
    unansweredCount: unansweredIndices.length,
    answeredIndices,
    flaggedIndices,
    unansweredIndices,
  };
}

export interface ExamSessionTiming {
  startedAtMs: number;
  deadlineMs: number;
  totalSeconds: number;
}

export function createExamSessionTiming(
  totalSeconds: number,
  nowMs: number = Date.now()
): ExamSessionTiming {
  const safeTotal = Math.max(1, Math.floor(totalSeconds));
  return {
    startedAtMs: nowMs,
    deadlineMs: nowMs + safeTotal * 1000,
    totalSeconds: safeTotal,
  };
}

export function adjustExamSessionDuration(
  timing: ExamSessionTiming,
  nextTotalSeconds: number
): ExamSessionTiming {
  const safeTotal = Math.max(1, Math.floor(nextTotalSeconds));
  return {
    startedAtMs: timing.startedAtMs,
    totalSeconds: safeTotal,
    deadlineMs: timing.startedAtMs + safeTotal * 1000,
  };
}

export function computeRemainingSeconds(
  deadlineMs: number,
  nowMs: number = Date.now()
): number {
  return Math.max(0, Math.ceil((deadlineMs - nowMs) / 1000));
}

export function computeElapsedSeconds(
  startedAtMs: number,
  totalSeconds: number,
  nowMs: number = Date.now()
): number {
  const rawElapsed = Math.round((nowMs - startedAtMs) / 1000);
  return Math.max(1, Math.min(totalSeconds, rawElapsed));
}

export function formatSecondsHMS(totalSeconds: number): string {
  const hrs = Math.floor(totalSeconds / 3600);
  const mins = Math.floor((totalSeconds % 3600) / 60);
  const secs = totalSeconds % 60;
  return `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

export function getDailyWindowStatus(now = new Date()): {
  isOpen: boolean;
  label: 'OPENS AT 10 AM' | 'LIVE NOW' | 'SLOT CLOSED';
  countdownText: string;
} {
  const hour = now.getHours();
  if (hour < 10) {
    const target = new Date(now);
    target.setHours(10, 0, 0, 0);
    const diff = Math.max(0, Math.floor((target.getTime() - now.getTime()) / 1000));
    return { isOpen: false, label: 'OPENS AT 10 AM', countdownText: formatSecondsHMS(diff) };
  }
  if (hour < 22) {
    const target = new Date(now);
    target.setHours(22, 0, 0, 0);
    const diff = Math.max(0, Math.floor((target.getTime() - now.getTime()) / 1000));
    return { isOpen: true, label: 'LIVE NOW', countdownText: formatSecondsHMS(diff) };
  }
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(10, 0, 0, 0);
  const diff = Math.max(0, Math.floor((tomorrow.getTime() - now.getTime()) / 1000));
  return { isOpen: false, label: 'SLOT CLOSED', countdownText: formatSecondsHMS(diff) };
}

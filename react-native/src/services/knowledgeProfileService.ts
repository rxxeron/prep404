import { calculateRetrievability, FSRSCardState } from '../algorithms/fsrs';
import { QUESTION_BANK } from '../data/questionBank';
import {
  getUniversityBlueprint,
  LEAGUE_TIERS,
  PHASE_1_UNIVERSITY_CODES,
} from '../data/universities';
import {
  DisciplineCategory,
  ExamHistoryItem,
  LearnerKnowledgeProfile,
  Question,
  QuestionTimingTelemetry,
  SpeedAccuracyQuadrant,
  SubjectMasteryNode,
  TopicAttemptRecord,
  TopicMasteryNode,
  UniversityReadinessProjection,
  UniversitySectionReadiness,
} from '../types';
import { storageService } from './storageService';

export interface TopicSeedBaseline {
  topicId: string;
  topicName: string;
  subjectId: string;
  subjectName: string;
  baseAttempts: number;
  baseCorrect: number;
  baseWrong: number;
  baseSkipped: number;
  baseAvgSeconds: number;
  targetTimeSeconds: number;
  baseStabilityDays: number;
  baseElapsedDays: number;
  universityRelevance: string[];
}

/**
 * Curriculum catalog for the 17 Phase 1 admission topics.
 * All base attempt counts are strictly 0 — mastery, accuracy, speed, and FSRS retention
 * are computed 100% from real user telemetry, practice attempts, and exam scripts.
 */
export const PHASE_1_TOPIC_CATALOG: TopicSeedBaseline[] = [
  // Higher Mathematics
  {
    topicId: 'calculus_limits',
    topicName: 'Limits & Continuity',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'AUST', 'EWU', 'UIU', 'AIUB', 'UAP'],
  },
  {
    topicId: 'calculus_diff',
    topicName: 'Differentiation & Tangents',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['BRACU', 'NSU', 'AUST', 'EWU', 'UIU', 'AIUB'],
  },
  {
    topicId: 'calculus_int',
    topicName: 'Definite & Indefinite Integrals',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 60,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['BRACU', 'AUST', 'EWU', 'UIU', 'UAP'],
  },
  {
    topicId: 'matrices',
    topicName: 'Matrices & Determinants',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 50,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'AUST', 'AIUB', 'EWU'],
  },
  {
    topicId: 'vectors',
    topicName: 'Vectors: Dot & Cross Product',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 52,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'BRACU', 'AIUB', 'UIU', 'EWU'],
  },
  {
    topicId: 'conics',
    topicName: 'Coordinate Geometry & Conics',
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 60,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'BRACU', 'NSU', 'EWU'],
  },
  // Quantitative Aptitude
  {
    topicId: 'algebra_word',
    topicName: 'Algebraic Equations & Inequalities',
    subjectId: 'quant_math',
    subjectName: 'Quantitative Aptitude',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 50,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'UIU', 'AIUB', 'UAP', 'EWU'],
  },
  {
    topicId: 'perm_prob',
    topicName: 'Permutations, Combinations & Probability',
    subjectId: 'quant_math',
    subjectName: 'Quantitative Aptitude',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'UIU', 'AUST'],
  },
  {
    topicId: 'ratios_percent',
    topicName: 'Ratios, Percentages & Data Sufficiency',
    subjectId: 'quant_math',
    subjectName: 'Quantitative Aptitude',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 48,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'EWU', 'UIU', 'UAP'],
  },
  // Physics
  {
    topicId: 'mechanics_newton',
    topicName: 'Newtonian Mechanics, Work & Energy',
    subjectId: 'physics',
    subjectName: 'Physics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['BRACU', 'AUST', 'EWU', 'UIU', 'AIUB', 'UAP'],
  },
  {
    topicId: 'electro_circuits',
    topicName: 'Current Electricity & Kirchhoff Laws',
    subjectId: 'physics',
    subjectName: 'Physics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'BRACU', 'EWU', 'UIU', 'AIUB'],
  },
  {
    topicId: 'waves_optics',
    topicName: 'Waves, Thermodynamics & Modern Physics',
    subjectId: 'physics',
    subjectName: 'Physics',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'EWU', 'BRACU', 'UAP'],
  },
  // Chemistry
  {
    topicId: 'organic_reactions',
    topicName: 'Organic Functional Groups & Isomerism',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 50,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'EWU', 'UAP'],
  },
  {
    topicId: 'chemical_eq',
    topicName: 'Chemical Equilibrium, pH & Bonding',
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 48,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['AUST', 'EWU', 'UAP'],
  },
  // English
  {
    topicId: 'english_grammar',
    topicName: 'Sentence Correction, Modifiers & Parallelism',
    subjectId: 'english',
    subjectName: 'English Grammar & Reading',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 42,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP'],
  },
  {
    topicId: 'reading_comp',
    topicName: 'Critical Reading & Inference Passages',
    subjectId: 'english',
    subjectName: 'English Grammar & Reading',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 55,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'UAP'],
  },
  {
    topicId: 'vocab_contextual',
    topicName: 'Academic Vocabulary & Contextual Usage',
    subjectId: 'english',
    subjectName: 'English Grammar & Reading',
    baseAttempts: 0,
    baseCorrect: 0,
    baseWrong: 0,
    baseSkipped: 0,
    baseAvgSeconds: 0,
    targetTimeSeconds: 35,
    baseStabilityDays: 0,
    baseElapsedDays: 0,
    universityRelevance: ['NSU', 'BRACU', 'EWU', 'AIUB', 'UIU', 'UAP'],
  },
];

export function classifySpeedAccuracyQuadrant(
  accuracyPercent: number,
  avgTimeSeconds: number,
  targetTimeSeconds: number,
  _negativeMarksLost: number = 0
): SpeedAccuracyQuadrant {
  if (avgTimeSeconds <= 0 && accuracyPercent <= 0) {
    return 'critical_deficit';
  }
  if (accuracyPercent >= 74 && avgTimeSeconds <= targetTimeSeconds) {
    return 'mastered_fast';
  }
  if (accuracyPercent >= 68 && avgTimeSeconds > targetTimeSeconds) {
    return 'accurate_slow';
  }
  if (accuracyPercent < 70 && avgTimeSeconds > 0 && avgTimeSeconds <= targetTimeSeconds * 0.92) {
    return 'rushed_costly';
  }
  return 'critical_deficit';
}

export function getQuadrantMetadata(quadrant: SpeedAccuracyQuadrant): {
  label: string;
  shortLabel: string;
  prescription: string;
  tone: 'success' | 'warning' | 'danger' | 'info';
} {
  switch (quadrant) {
    case 'mastered_fast':
      return {
        label: '● MASTERED & FAST',
        shortLabel: 'Mastered',
        prescription: 'Maintain via spaced FSRS intervals every 7–14 days.',
        tone: 'success',
      };
    case 'accurate_slow':
      return {
        label: '▲ ACCURATE · TIME BOTTLENECK',
        shortLabel: 'Slow Pace',
        prescription:
          'Concept is clear, but solving takes too long. Practice 15s timed shortcuts.',
        tone: 'info',
      };
    case 'rushed_costly':
      return {
        label: '■ RUSHED · IMPULSE LOCK',
        shortLabel: 'Impulse Lock',
        prescription:
          'Fast <2.5s impulse locking is costing accuracy. Pause 4s to read the full stem before locking.',
        tone: 'warning',
      };
    case 'critical_deficit':
      return {
        label: '■ UNCALIBRATED / DEFICIT',
        shortLabel: 'Needs Drill',
        prescription:
          'Lock answers in Practice or Personal Exam so AETHER AI can calibrate this chapter.',
        tone: 'danger',
      };
  }
}

function mapSectionNameToSubjectIds(sectionName: string): string[] {
  const lower = sectionName.toLowerCase();
  const ids: string[] = [];
  if (lower.includes('higher math') || lower.includes('calculus') || lower.includes('conic')) {
    ids.push('higher_math');
  }
  if (
    lower.includes('quantitative') ||
    lower.includes('sat math') ||
    lower.includes('aptitude') ||
    lower === 'mathematics' ||
    lower.includes('algebra')
  ) {
    ids.push('quant_math', 'higher_math');
  }
  if (lower.includes('physics') || lower.includes('mechanics')) {
    ids.push('physics');
  }
  if (lower.includes('chemistry') || lower.includes('science')) {
    ids.push('chemistry');
  }
  if (
    lower.includes('english') ||
    lower.includes('grammar') ||
    lower.includes('reading') ||
    lower.includes('vocabulary') ||
    lower.includes('composition')
  ) {
    ids.push('english');
  }
  return ids.length > 0 ? Array.from(new Set(ids)) : ['higher_math', 'english'];
}

export function computeUniversityReadiness(
  universityCode: string,
  subjects: SubjectMasteryNode[],
  topics: TopicMasteryNode[],
  category: DisciplineCategory = 'engineering'
): UniversityReadinessProjection {
  const blueprint = getUniversityBlueprint(universityCode, category);
  const subjectMap = new Map(subjects.map((s) => [s.subjectId, s]));

  let totalProjectedRaw = 0;
  let totalMaxMarks = 0;
  const totalUserAttempts = subjects.reduce(
    (acc, s) => acc + s.questionsAttempted,
    0
  );

  const sectionReadiness: UniversitySectionReadiness[] = blueprint.sections.map(
    (sec) => {
      const matchedSubjectIds = mapSectionNameToSubjectIds(sec.name);
      const matchedSubjects = matchedSubjectIds
        .map((id) => subjectMap.get(id))
        .filter((s): s is SubjectMasteryNode => Boolean(s));

      const avgMastery =
        matchedSubjects.length > 0
          ? Math.round(
              matchedSubjects.reduce((acc, s) => acc + s.masteryPercent, 0) /
                matchedSubjects.length
            )
          : 0;

      const projectedMarks = Number(
        ((sec.marks * avgMastery) / 100).toFixed(1)
      );
      totalProjectedRaw += projectedMarks;
      totalMaxMarks += sec.marks;

      return {
        name: sec.name,
        weightPercent: sec.weightPercent,
        projectedMarks,
        maxMarks: sec.marks,
        masteryPercent: avgMastery,
        color: sec.color,
      };
    }
  );

  const relevantTopics = topics.filter((t) =>
    t.universityRelevance.includes(blueprint.universityCode)
  );

  // Private universities in Phase 1 enforce 0.00 negative marking
  const estimatedNetLossFromNegatives = 0;

  const projectedScore = Number(Math.max(0, totalProjectedRaw).toFixed(1));
  const cutOffScore = Number(
    ((totalMaxMarks * blueprint.cutOffPercent) / 100).toFixed(1)
  );
  const gapMarks = Number((projectedScore - cutOffScore).toFixed(1));

  // If the user has attempted 0 questions so far, probability is 0% (uncalibrated)
  let admissionProbabilityPercent = 0;
  if (totalUserAttempts > 0 && projectedScore > 0) {
    const normalizedDelta =
      (projectedScore - cutOffScore) / Math.max(1, totalMaxMarks * 0.08);
    const rawProb = 1 / (1 + Math.exp(-normalizedDelta));
    admissionProbabilityPercent = Math.max(
      1,
      Math.min(99, Math.round(rawProb * 100))
    );
  }

  const topBlockingTopics = [...relevantTopics]
    .sort((a, b) => a.masteryScore - b.masteryScore)
    .slice(0, 3);

  return {
    universityCode: blueprint.universityCode,
    universityName: blueprint.universityName,
    programName: blueprint.programName,
    projectedScore,
    totalMarks: totalMaxMarks,
    cutOffScore,
    cutOffPercent: blueprint.cutOffPercent,
    gapMarks,
    admissionProbabilityPercent,
    negativeMarkingPenalty: 0,
    estimatedNetLossFromNegatives,
    sectionReadiness,
    topBlockingTopics,
  };
}

export function computeLearnerKnowledgeProfile(params?: {
  examHistory?: ExamHistoryItem[];
  topicAttempts?: TopicAttemptRecord[];
  questionTelemetry?: QuestionTimingTelemetry[];
  fsrsCards?: Record<string, FSRSCardState>;
  now?: Date;
}): LearnerKnowledgeProfile {
  const history = params?.examHistory ?? storageService.getExamHistory();
  const attempts = params?.topicAttempts ?? storageService.getTopicAttempts();
  const telemetry =
    params?.questionTelemetry ?? storageService.getQuestionTelemetryHistory();
  const fsrsCards = params?.fsrsCards ?? storageService.getFsrsCards();
  const now = params?.now ?? new Date();

  const qMap = new Map<string, Question>(QUESTION_BANK.map((q) => [q.id, q]));

  // Aggregate real user attempts from exam scripts, practice attempts, and finger telemetry locks
  const liveStats = new Map<
    string,
    {
      attempts: number;
      correct: number;
      wrong: number;
      skipped: number;
      totalSeconds: number;
      impulseLocks: number;
    }
  >();

  const ensureStat = (topicId: string) => {
    const existing = liveStats.get(topicId);
    if (existing) return existing;
    const init = {
      attempts: 0,
      correct: 0,
      wrong: 0,
      skipped: 0,
      totalSeconds: 0,
      impulseLocks: 0,
    };
    liveStats.set(topicId, init);
    return init;
  };

  for (const h of history) {
    const avgSecPerQ =
      h.questionIds.length > 0
        ? Math.max(5, Math.round(h.timeTakenSeconds / h.questionIds.length))
        : 30;

    for (const qId of h.questionIds) {
      const q = qMap.get(qId);
      if (!q) continue;
      const tId = q.topicId || PHASE_1_TOPIC_CATALOG[0].topicId;
      const st = ensureStat(tId);
      st.attempts += 1;
      st.totalSeconds += avgSecPerQ;
      const picked = h.userAnswers[qId];
      if (!picked) {
        st.skipped += 1;
      } else if (picked.toUpperCase() === q.correctOptionId.toUpperCase()) {
        st.correct += 1;
      } else {
        st.wrong += 1;
      }
    }
  }

  for (const att of attempts) {
    const st = ensureStat(att.topicId);
    st.attempts += 1;
    st.totalSeconds += att.timeSpentSeconds;
    if (att.isCorrect) {
      st.correct += 1;
    } else {
      st.wrong += 1;
    }
  }

  // Also fold in real 1-tap telemetry locks if not already accounted in topicAttempts
  if (attempts.length === 0 && history.length === 0 && telemetry.length > 0) {
    for (const ev of telemetry) {
      const q = qMap.get(ev.questionId);
      const tId = ev.topicId || q?.topicId || PHASE_1_TOPIC_CATALOG[0].topicId;
      const st = ensureStat(tId);
      st.attempts += 1;
      st.totalSeconds += Math.max(1, Math.round(ev.totalTimeMs / 1000));
      if (ev.isCorrect) {
        st.correct += 1;
      } else {
        st.wrong += 1;
      }
      if (ev.classification === 'impulse_guess') {
        st.impulseLocks += 1;
      }
    }
  } else {
    for (const ev of telemetry) {
      if (ev.classification === 'impulse_guess') {
        const q = qMap.get(ev.questionId);
        const tId = ev.topicId || q?.topicId;
        if (tId) {
          ensureStat(tId).impulseLocks += 1;
        }
      }
    }
  }

  // Build TopicMasteryNode list strictly from real attempts and FSRS state
  const topics: TopicMasteryNode[] = PHASE_1_TOPIC_CATALOG.map((seed) => {
    const delta = liveStats.get(seed.topicId);
    const attemptsCount = seed.baseAttempts + (delta?.attempts ?? 0);
    const correctCount = seed.baseCorrect + (delta?.correct ?? 0);
    const wrongCount = seed.baseWrong + (delta?.wrong ?? 0);
    const skippedCount = seed.baseSkipped + (delta?.skipped ?? 0);
    const negativeMarksLost = 0;

    const totalTime =
      seed.baseAttempts * seed.baseAvgSeconds + (delta?.totalSeconds ?? 0);
    const avgTimeSeconds =
      attemptsCount > 0 ? Math.round(totalTime / attemptsCount) : 0;

    const answered = correctCount + wrongCount;
    const accuracyPercent =
      answered > 0 ? Math.round((correctCount / answered) * 100) : 0;

    // Check real FSRS cards matching this topic
    const topicQuestions = QUESTION_BANK.filter(
      (q) => q.topicId === seed.topicId
    );
    let stabilitySum = 0;
    let stabilityCount = 0;
    let retrievabilitySum = 0;
    let dueCardCount = 0;

    for (const tq of topicQuestions) {
      const card = fsrsCards[tq.id];
      if (card) {
        const elapsed = Math.max(
          0,
          (now.getTime() - new Date(card.lastReview).getTime()) / 86400000
        );
        stabilitySum += card.stability;
        stabilityCount += 1;
        retrievabilitySum += calculateRetrievability(elapsed, card.stability) * 100;
        if (new Date(card.nextReview).getTime() <= now.getTime()) {
          dueCardCount += 1;
        }
      }
    }

    const fsrsStabilityDays =
      stabilityCount > 0 ? Number((stabilitySum / stabilityCount).toFixed(1)) : 0;
    const fsrsRetrievability =
      stabilityCount > 0
        ? Math.max(1, Math.min(100, Math.round(retrievabilitySum / stabilityCount)))
        : attemptsCount > 0
          ? accuracyPercent
          : 0;

    let masteryScore = 0;
    if (attemptsCount > 0 || stabilityCount > 0) {
      const speedFactor =
        avgTimeSeconds > 0 && avgTimeSeconds <= seed.targetTimeSeconds
          ? 95
          : avgTimeSeconds > 0
            ? Math.max(
                30,
                100 -
                  Math.round(
                    ((avgTimeSeconds - seed.targetTimeSeconds) /
                      seed.targetTimeSeconds) *
                      70
                  )
              )
            : 0;
      masteryScore = Math.max(
        1,
        Math.min(
          100,
          Math.round(
            accuracyPercent * 0.65 +
              fsrsRetrievability * 0.25 +
              speedFactor * 0.1
          )
        )
      );
    }

    const quadrant = classifySpeedAccuracyQuadrant(
      accuracyPercent,
      avgTimeSeconds,
      seed.targetTimeSeconds,
      delta?.impulseLocks ?? 0
    );

    return {
      topicId: seed.topicId,
      topicName: seed.topicName,
      subjectId: seed.subjectId,
      subjectName: seed.subjectName,
      masteryScore,
      accuracyPercent,
      fsrsStabilityDays,
      fsrsRetrievability,
      dueCardCount,
      attemptsCount,
      correctCount,
      wrongCount,
      skippedCount,
      negativeMarksLost,
      avgTimeSeconds,
      targetTimeSeconds: seed.targetTimeSeconds,
      quadrant,
      universityRelevance: seed.universityRelevance,
    };
  });

  // Group into SubjectMasteryNode list
  const subjectOrder: { id: string; name: string }[] = [
    { id: 'higher_math', name: 'Higher Mathematics' },
    { id: 'quant_math', name: 'Quantitative Aptitude' },
    { id: 'physics', name: 'Physics' },
    { id: 'english', name: 'English Grammar & Reading' },
    { id: 'chemistry', name: 'Chemistry' },
  ];

  const subjects: SubjectMasteryNode[] = subjectOrder.map(({ id, name }) => {
    const subTopics = topics.filter((t) => t.subjectId === id);
    const activeTopics = subTopics.filter((t) => t.attemptsCount > 0);
    const questionsAttempted = subTopics.reduce(
      (acc, t) => acc + t.attemptsCount,
      0
    );
    const correctCount = subTopics.reduce((acc, t) => acc + t.correctCount, 0);
    const wrongCount = subTopics.reduce((acc, t) => acc + t.wrongCount, 0);
    const negativeMarksLost = 0;

    const masteryPercent =
      activeTopics.length > 0
        ? Math.round(
            activeTopics.reduce((acc, t) => acc + t.masteryScore, 0) /
              activeTopics.length
          )
        : 0;
    const retentionPercent =
      activeTopics.length > 0
        ? Math.round(
            activeTopics.reduce((acc, t) => acc + t.fsrsRetrievability, 0) /
              activeTopics.length
          )
        : 0;
    const avgTimeSeconds =
      activeTopics.length > 0
        ? Math.round(
            activeTopics.reduce((acc, t) => acc + t.avgTimeSeconds, 0) /
              activeTopics.length
          )
        : 0;
    const targetTimeSeconds =
      subTopics.length > 0
        ? Math.round(
            subTopics.reduce((acc, t) => acc + t.targetTimeSeconds, 0) /
              subTopics.length
          )
        : 52;

    const status: SubjectMasteryNode['status'] =
      masteryPercent >= 78
        ? 'mastered'
        : masteryPercent >= 68
          ? 'on_track'
          : masteryPercent >= 50
            ? 'at_risk'
            : 'critical';

    return {
      subjectId: id,
      subjectName: name,
      masteryPercent,
      retentionPercent,
      questionsAttempted,
      correctCount,
      wrongCount,
      negativeMarksLost,
      avgTimeSeconds,
      targetTimeSeconds,
      status,
      topics: subTopics,
    };
  });

  const attemptedSubjects = subjects.filter((s) => s.questionsAttempted > 0);
  const overallMasteryPercent =
    attemptedSubjects.length > 0
      ? Math.round(
          attemptedSubjects.reduce((acc, s) => acc + s.masteryPercent, 0) /
            attemptedSubjects.length
        )
      : 0;
  const overallRetrievabilityPercent =
    attemptedSubjects.length > 0
      ? Math.round(
          attemptedSubjects.reduce((acc, s) => acc + s.retentionPercent, 0) /
            attemptedSubjects.length
        )
      : 0;
  const totalAttempts = subjects.reduce(
    (acc, s) => acc + s.questionsAttempted,
    0
  );
  const totalNegativeMarksLost = 0;
  const avgSolveSpeedSeconds =
    attemptedSubjects.length > 0
      ? Math.round(
          attemptedSubjects.reduce((acc, s) => acc + s.avgTimeSeconds, 0) /
            attemptedSubjects.length
        )
      : 0;
  const dueCardsTotal = topics.reduce((acc, t) => acc + t.dueCardCount, 0);

  const tierIndex =
    overallMasteryPercent >= 85
      ? 0
      : overallMasteryPercent >= 78
        ? 1
        : overallMasteryPercent >= 70
          ? 2
          : overallMasteryPercent >= 55
            ? 3
            : 4;
  const matchedLeague = LEAGUE_TIERS[tierIndex] || LEAGUE_TIERS[4];

  const universityProjections: Record<string, UniversityReadinessProjection> = {};
  for (const code of PHASE_1_UNIVERSITY_CODES) {
    universityProjections[code] = computeUniversityReadiness(
      code,
      subjects,
      topics
    );
  }

  return {
    overallMasteryPercent,
    overallRetrievabilityPercent,
    totalAttempts,
    totalNegativeMarksLost,
    avgSolveSpeedSeconds,
    dueCardsTotal,
    leagueTier: {
      id: matchedLeague.id,
      name: matchedLeague.name,
      greekSymbol: matchedLeague.greekSymbol,
      colorHex: matchedLeague.colorHex,
    },
    subjects,
    topics,
    universityProjections,
  };
}

export interface SubjectRadarDataPoint {
  subjectId: string;
  subject: string;
  fullSubjectName: string;
  currentMastery: number;
  targetGoal: number;
  fsrsRetention: number;
  gap: number;
  fullMark: number;
}

const SHORT_SUBJECT_LABELS: Record<string, string> = {
  higher_math: 'Higher Math',
  quant_math: 'Quant Math',
  physics: 'Physics',
  english: 'English',
  chemistry: 'Chemistry',
};

const UNIVERSITY_SUBJECT_TARGET_BONUS: Record<string, Record<string, number>> = {
  NSU: { higher_math: 76, quant_math: 82, physics: 72, english: 80, chemistry: 68 },
  BRACU: { higher_math: 80, quant_math: 78, physics: 78, english: 82, chemistry: 70 },
  AUST: { higher_math: 85, quant_math: 76, physics: 84, english: 72, chemistry: 80 },
  EWU: { higher_math: 76, quant_math: 74, physics: 75, english: 74, chemistry: 72 },
  UIU: { higher_math: 75, quant_math: 76, physics: 74, english: 72, chemistry: 68 },
  AIUB: { higher_math: 74, quant_math: 75, physics: 72, english: 75, chemistry: 68 },
  UAP: { higher_math: 70, quant_math: 72, physics: 70, english: 70, chemistry: 68 },
};

export function buildSubjectRadarData(
  subjects: SubjectMasteryNode[],
  universityCode = 'BRACU'
): SubjectRadarDataPoint[] {
  const code = universityCode.toUpperCase() === 'BRAC' ? 'BRACU' : universityCode.toUpperCase();
  const blueprint = getUniversityBlueprint(code, 'engineering');
  const uniTargets = UNIVERSITY_SUBJECT_TARGET_BONUS[code] || UNIVERSITY_SUBJECT_TARGET_BONUS.BRACU;

  return subjects.map((sub) => {
    const targetGoal = uniTargets[sub.subjectId] ?? Math.max(70, blueprint.cutOffPercent + 4);
    const currentMastery = Math.max(0, Math.min(100, sub.masteryPercent));
    const fsrsRetention = Math.max(0, Math.min(100, sub.retentionPercent));
    return {
      subjectId: sub.subjectId,
      subject: SHORT_SUBJECT_LABELS[sub.subjectId] || sub.subjectName,
      fullSubjectName: sub.subjectName,
      currentMastery,
      targetGoal,
      fsrsRetention,
      gap: currentMastery - targetGoal,
      fullMark: 100,
    };
  });
}

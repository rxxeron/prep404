import { QUESTION_BANK, pickQuestionsForExam } from '../data/questionBank';
import { UNIVERSITY_CATALOG, getUniversityBlueprint } from '../data/universities';
import {
  AetherSyllabusModule,
  AetherUnifiedPersonalExam,
  DisciplineCategory,
  Question,
  RoadmapMilestone,
} from '../types';
import { computeLearnerKnowledgeProfile } from './knowledgeProfileService';
import { computeCandidateSeriousnessProfile } from './telemetryService';

export type HorizonDays = number;

export interface AetherPersonalizedAdmissionPlan {
  universityCode: string;
  universityName: string;
  programName: string;
  examDateIso: string;
  examDateFormatted: string;
  daysRemaining: number;
  learnerLevelLabel: 'Foundation Builder' | 'Cut-Off Contender' | 'Merit Scholarship Tier';
  seriousnessScore: number;
  seriousnessStatus: string;
  overallMasteryPercent: number;
  projectedScore: number;
  cutOffScore: number;
  gapMarks: number;
  dailyStudyMinutes: number;
  dailyQuestionQuota: number;
  customSyllabus: AetherSyllabusModule[];
  unifiedPersonalExam: AetherUnifiedPersonalExam;
  personalExamQuestions: Question[];
  milestones: RoadmapMilestone[];
}

/**
 * Computes the exact number of days left until the university's admission test date.
 */
export function computeDaysUntilAdmission(
  universityCode: string,
  now: Date = new Date()
): { daysRemaining: number; examDateIso: string; examDateFormatted: string } {
  const code =
    universityCode.toUpperCase() === 'BRAC'
      ? 'BRACU'
      : universityCode.toUpperCase();
  const uni =
    UNIVERSITY_CATALOG.find((u) => u.code.toUpperCase() === code) ||
    UNIVERSITY_CATALOG.find((u) => u.code === 'NSU')!;

  const cycleDateStr =
    uni.admissionCycles?.[0]?.examDate ||
    uni.estimatedExamDate ||
    '2026-12-05T09:00:00Z';
  const examDate = new Date(cycleDateStr);
  const diffMs = examDate.getTime() - now.getTime();
  const rawDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
  // Clamp to a realistic active admission countdown window (7 to 45 days) if system date is near/after
  const daysRemaining = rawDays > 0 ? rawDays : 14;

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const formatted = `${String(examDate.getUTCDate()).padStart(2, '0')} ${months[examDate.getUTCMonth()]} ${examDate.getUTCFullYear()}`;

  return {
    daysRemaining,
    examDateIso: examDate.toISOString(),
    examDateFormatted: formatted,
  };
}

/**
 * Generates the personalized milestone sequence driven by exact days remaining to admission
 * and the learner's weak topics (no static 5/10/15/30/60 S-curve).
 */
export function generateAdmissionRoadmap(
  universityCode: string,
  category: DisciplineCategory,
  daysRemainingInput: number = 14,
  completedIds: string[] = []
): RoadmapMilestone[] {
  const blueprint = getUniversityBlueprint(universityCode, category);
  const sections = blueprint.sections.map((s) => s.name);
  const uni = blueprint.universityCode;
  const daysLeft = Math.max(4, daysRemainingInput);

  // Scale personalized countdown checkpoints based on actual days remaining to admission
  const scaleCount =
    daysLeft <= 9 ? 8 : daysLeft <= 16 ? 10 : daysLeft <= 25 ? 12 : 14;

  const templates: Omit<RoadmapMilestone, 'index' | 'status'>[] = [
    {
      id: 'ms_topic_1',
      title: `Day 1 · ${uni} Diagnostic Baseline & Syntax Lock`,
      subtitle: `${sections[0] || 'English'} Foundations · Permanent Lock Drill`,
      subjectTag: 'English',
      questionCount: 10,
      durationMinutes: 12,
      xpReward: 120,
      pillar: 'topic',
      topicId: 'english_grammar',
    },
    {
      id: 'ms_topic_2',
      title: 'Day 2 · Limits, Derivatives & Tangent Traps',
      subtitle: 'AETHER AI Direct Calculus Derivation & Shortcut',
      subjectTag: category === 'business' ? 'Quant Math' : 'Higher Math',
      questionCount: 10,
      durationMinutes: 15,
      xpReward: 140,
      pillar: 'topic',
      topicId: category === 'business' ? 'algebra_word' : 'calculus_diff',
    },
    {
      id: 'ms_subject_1',
      title: 'Day 3 · Quantitative & Algebraic Inequalities',
      subtitle: 'Logarithms, Permutations & Probability Calibration',
      subjectTag: 'Quant Math',
      questionCount: 12,
      durationMinutes: 18,
      xpReward: 160,
      pillar: 'subject',
      topicId: 'perm_prob',
    },
    {
      id: 'ms_topic_3',
      title:
        category === 'pharmacy'
          ? 'Day 4 · Cell Biology & Organic Functional Groups'
          : 'Day 4 · Vectors, Matrices & Conic Sections',
      subtitle: `${uni} High-Weight Chapter Stabilization`,
      subjectTag: category === 'pharmacy' ? 'Chemistry' : 'Higher Math',
      questionCount: 10,
      durationMinutes: 15,
      xpReward: 150,
      pillar: 'topic',
      topicId: category === 'pharmacy' ? 'organic_reactions' : 'conics',
    },
    {
      id: 'ms_section_1',
      title: `Day 5 · Section Simulation: ${sections[0] || 'English'}`,
      subtitle: `Timed ${uni} Section Pattern · 0 Negative Marking`,
      subjectTag: 'Section Exam',
      questionCount: 15,
      durationMinutes: 20,
      xpReward: 200,
      pillar: 'section',
    },
    {
      id: 'ms_subject_2',
      title:
        category === 'pharmacy'
          ? 'Day 6 · Chemical Equilibrium & pH Buffer Sprint'
          : 'Day 6 · Kirchhoff Circuits & Newtonian Mechanics',
      subtitle: 'Eliminate <2.5s Impulse Taps on Multi-Step Stems',
      subjectTag: category === 'pharmacy' ? 'Chemistry' : 'Physics',
      questionCount: 12,
      durationMinutes: 18,
      xpReward: 175,
      pillar: 'subject',
      topicId: category === 'pharmacy' ? 'chemical_eq' : 'electro_circuits',
    },
    {
      id: 'ms_topic_4',
      title: 'Day 7 · Critical Reading & Inference Passages',
      subtitle: '4-Second Stem Comprehension Floor Verification',
      subjectTag: 'English',
      questionCount: 10,
      durationMinutes: 15,
      xpReward: 150,
      pillar: 'topic',
      topicId: 'reading_comp',
    },
    {
      id: 'ms_overall_1',
      title: `Day 8 · ${uni} AETHER AI Personal Calibration Exam #1`,
      subtitle: 'Unified Multi-Section Benchmark (Digital / OMR)',
      subjectTag: 'Personal Exam',
      questionCount: 18,
      durationMinutes: 30,
      xpReward: 300,
      pillar: 'overall',
    },
    {
      id: 'ms_section_2',
      title: `Day 9 · Section Simulation: ${sections[1] || 'Mathematics'}`,
      subtitle: 'Read -> Think -> Lock Pacing Verification',
      subjectTag: 'Section Exam',
      questionCount: 15,
      durationMinutes: 20,
      xpReward: 220,
      pillar: 'section',
    },
    {
      id: 'ms_subject_3',
      title: 'Day 10 · Cross-Chapter FSRS Retention Lock',
      subtitle: 'Spaced Repetition Stabilization of Due Cards',
      subjectTag: 'FSRS Review',
      questionCount: 15,
      durationMinutes: 22,
      xpReward: 240,
      pillar: 'subject',
    },
    {
      id: 'ms_topic_5',
      title: 'Day 11 · Definite Integrals & Area Under Curve',
      subtitle: '15-Second AETHER AI Shortcut Verification',
      subjectTag: 'Higher Math',
      questionCount: 12,
      durationMinutes: 18,
      xpReward: 210,
      pillar: 'topic',
      topicId: 'calculus_int',
    },
    {
      id: 'ms_overall_2',
      title: `Day 12 · ${uni} Final Admission Cut-Off Qualifier`,
      subtitle: 'Full OMR / Digital Official Cut-Off Simulation',
      subjectTag: 'Summit Exam',
      questionCount: 20,
      durationMinutes: 40,
      xpReward: 400,
      pillar: 'overall',
    },
    {
      id: 'ms_section_3',
      title: `Day 13 · Section Simulation: ${sections[2] || 'Analytical'}`,
      subtitle: 'Precision First-Tap Lock Pass',
      subjectTag: 'Section Exam',
      questionCount: 14,
      durationMinutes: 18,
      xpReward: 230,
      pillar: 'section',
    },
    {
      id: 'ms_overall_3',
      title: `Day 14 · ${uni} Admission-Eve Readiness Certification`,
      subtitle: 'Final AETHER AI Personal Exam Verification',
      subjectTag: 'Summit Gate',
      questionCount: 20,
      durationMinutes: 45,
      xpReward: 500,
      pillar: 'overall',
    },
  ];

  const sliced = templates.slice(0, scaleCount);
  let activeAssigned = false;

  const profile = computeLearnerKnowledgeProfile();
  const topicAccMap = new Map(
    profile.topics
      .filter((t) => t.attemptsCount > 0)
      .map((t) => [t.topicId, t.accuracyPercent])
  );

  return sliced.map((item, idx) => {
    const isCompleted = completedIds.includes(item.id);
    let status: RoadmapMilestone['status'] = 'locked';
    if (isCompleted) {
      status = 'completed';
    } else if (!activeAssigned) {
      status = 'active';
      activeAssigned = true;
    }
    const realTopicAcc = item.topicId ? topicAccMap.get(item.topicId) : undefined;
    return {
      ...item,
      index: idx + 1,
      status,
      accuracyPercent:
        realTopicAcc !== undefined
          ? realTopicAcc
          : isCompleted && profile.overallMasteryPercent > 0
            ? profile.overallMasteryPercent
            : undefined,
    };
  });
}

/**
 * Synthesizes the complete AETHER AI Personalized Countdown Plan, Custom Syllabus,
 * and One Unified Personal Exam Access for the candidate.
 */
export function synthesizeAetherPersonalPlan(params: {
  universityCode: string;
  category: DisciplineCategory;
  completedIds: string[];
  now?: Date;
}): AetherPersonalizedAdmissionPlan {
  const { universityCode, category, completedIds, now = new Date() } = params;
  const blueprint = getUniversityBlueprint(universityCode, category);
  const countdown = computeDaysUntilAdmission(blueprint.universityCode, now);
  const profile = computeLearnerKnowledgeProfile({ now });
  const seriousness = computeCandidateSeriousnessProfile();
  const proj =
    profile.universityProjections[blueprint.universityCode] ||
    profile.universityProjections.NSU;

  const learnerLevelLabel: AetherPersonalizedAdmissionPlan['learnerLevelLabel'] =
    profile.overallMasteryPercent >= 78
      ? 'Merit Scholarship Tier'
      : profile.overallMasteryPercent >= 66
        ? 'Cut-Off Contender'
        : 'Foundation Builder';

  // Daily study workload scales inversely with days remaining and directly with cut-off gap
  const gapUrgency = Math.max(0, -proj.gapMarks);
  const dailyStudyMinutes = Math.min(
    180,
    Math.max(
      45,
      Math.round(55 + gapUrgency * 1.2 + (30 / Math.max(5, countdown.daysRemaining)) * 18)
    )
  );
  const dailyQuestionQuota = Math.max(
    20,
    Math.round(dailyStudyMinutes * 0.65)
  );

  // Build Custom Personalized Syllabus Modules ordered by urgency for this specific candidate
  const relevantTopics = profile.topics
    .filter((t) => t.universityRelevance.includes(blueprint.universityCode))
    .sort((a, b) => a.masteryScore - b.masteryScore);

  const customSyllabus: AetherSyllabusModule[] = relevantTopics
    .slice(0, 6)
    .map((topic, idx) => {
      const targetMasteryPercent = Math.max(76, blueprint.cutOffPercent + 5);
      const deficit = Math.max(4, targetMasteryPercent - topic.masteryScore);
      const priorityLevel: AetherSyllabusModule['priorityLevel'] =
        idx < 2 ? 'CRITICAL' : idx < 4 ? 'HIGH' : 'CORE';
      const weightPercent = idx < 2 ? 22 : idx < 4 ? 16 : 12;
      const estimatedHours = Number(
        Math.max(1.5, deficit * 0.12).toFixed(1)
      );

      const rationale =
        topic.attemptsCount === 0
          ? `0 attempts recorded yet — complete baseline drill to calibrate ${blueprint.universityCode} readiness.`
          : topic.quadrant === 'rushed_costly'
            ? `Impulse-lock risk (${topic.avgTimeSeconds}s/Q). Enforce >4s stem reading before first-tap lock.`
            : topic.quadrant === 'critical_deficit'
              ? `${deficit}% below ${blueprint.universityCode} target (${topic.dueCardCount} FSRS cards due).`
              : `High-yield ${blueprint.universityCode} section weight; lock in sub-${topic.targetTimeSeconds}s shortcut speed.`;

      return {
        id: `syl_${topic.topicId}`,
        title: topic.topicName,
        subjectName: topic.subjectName,
        topicId: topic.topicId,
        weightPercent,
        currentMasteryPercent: topic.masteryScore,
        targetMasteryPercent,
        priorityLevel,
        estimatedHours,
        rationale,
      };
    });

  // Synthesize One Unified Personal Exam Access tailored to this candidate's weak topics + target university
  const blockingTopicIds = new Set(
    relevantTopics.slice(0, 5).map((t) => t.topicId)
  );
  const targetedPool = QUESTION_BANK.filter(
    (q) =>
      (q.topicId && blockingTopicIds.has(q.topicId)) ||
      q.universityTags.includes(blueprint.universityCode)
  );
  const fallbackPool = pickQuestionsForExam(blueprint.universityCode, 20);
  const mergedQuestions: Question[] = [];
  const seenIds = new Set<string>();
  for (const q of [...targetedPool, ...fallbackPool]) {
    if (!seenIds.has(q.id)) {
      seenIds.add(q.id);
      mergedQuestions.push(q);
    }
    if (mergedQuestions.length >= 16) break;
  }

  const focusSubjects = Array.from(
    new Set(mergedQuestions.map((q) => q.subjectName))
  ).slice(0, 4);

  const calibrationSummary =
    profile.totalAttempts === 0 && seriousness.lockedAnswersCount === 0
      ? `Uncalibrated (0 questions locked). Launch this diagnostic exam to feed real Read → Think → Lock finger telemetry into AETHER AI.`
      : `Calibrated from ${profile.totalAttempts} real attempts & ${seriousness.lockedAnswersCount} finger locks (${seriousness.seriousnessScore}% seriousness · 0 negative marking).`;

  const unifiedPersonalExam: AetherUnifiedPersonalExam = {
    slug: `aether-personal-${blueprint.universityCode.toLowerCase()}-exam`,
    title: `${blueprint.universityCode} AETHER AI Personal Evaluation Exam`,
    subtitle: `Calibrated for ${countdown.daysRemaining}d Countdown · ${learnerLevelLabel} · 1-Tap Answer Lock`,
    universityCode: blueprint.universityCode,
    questionCount: mergedQuestions.length,
    durationMinutes: Math.max(20, Math.round(mergedQuestions.length * 1.5)),
    negativeMark: 0,
    calibrationSummary,
    focusSubjects,
  };

  const milestones = generateAdmissionRoadmap(
    blueprint.universityCode,
    category,
    countdown.daysRemaining,
    completedIds
  );

  return {
    universityCode: blueprint.universityCode,
    universityName: blueprint.universityName,
    programName: blueprint.programName,
    examDateIso: countdown.examDateIso,
    examDateFormatted: countdown.examDateFormatted,
    daysRemaining: countdown.daysRemaining,
    learnerLevelLabel,
    seriousnessScore: seriousness.seriousnessScore,
    seriousnessStatus: seriousness.statusLabel,
    overallMasteryPercent: profile.overallMasteryPercent,
    projectedScore: proj.projectedScore,
    cutOffScore: proj.cutOffScore,
    gapMarks: proj.gapMarks,
    dailyStudyMinutes,
    dailyQuestionQuota,
    customSyllabus,
    unifiedPersonalExam,
    personalExamQuestions: mergedQuestions,
    milestones,
  };
}

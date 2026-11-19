export type AppLanguage = 'english' | 'bangla';
export type ThemeMode = 'light' | 'dark';

export type StudentMedium = 'bangla' | 'english';
export type NctbVersion = 'bangla' | 'english';
export type EnglishCurriculum = 'cambridge' | 'edexcel';

export type DisciplineCategory =
  | 'engineering'
  | 'business'
  | 'pharmacy'
  | 'architecture'
  | 'lawAndArts';

export interface UniversityDiscipline {
  id: string;
  name: string;
  department?: string;
  category: DisciplineCategory;
  examSections: string[];
}

export interface AdmissionCycleInfo {
  id: string;
  season: string;
  academicYear: number;
  slotNumber: number;
  slotTitle: string;
  applicationDeadline?: string;
  examDate: string;
  examTime: string;
  applicationFee: string;
  venue: string;
  notes?: string;
  status: 'upcoming' | 'open' | 'closed';
}

export interface PrivateUniversity {
  id: string;
  code: string;
  fullName: string;
  location: string;
  estimatedExamDate: string; // ISO date
  disciplines: UniversityDiscipline[];
  examFormatType: 'centralized' | 'faculty_wide' | 'department_wise';
  examPatternSummary: string;
  admissionCycles?: AdmissionCycleInfo[];
}

export interface UserProfile {
  id: string;
  name: string;
  phone: string;
  email?: string;
  avatarUrl?: string;
  authProvider?: 'google' | 'phone' | 'guest';
  gender?: 'male' | 'female' | 'other';
  divisionId?: string;
  divisionName?: string;
  districtId?: string;
  districtName?: string;

  // SSC credentials
  sscGroup?: string;
  sscYear?: string;
  sscGpa?: string;
  sscInstitution?: string;
  sscEiin?: string;

  // HSC credentials
  hscGroup?: string;
  hscBatch?: string;
  hscGpa?: string;
  hscInstitution?: string;
  hscEiin?: string;

  // O-Level credentials
  oLevelBoard?: string;
  oLevelYear?: string;
  oLevelSubjectsCount?: number;
  oLevelGrades?: string;
  oLevelGpaEquiv?: string;
  oLevelSchool?: string;
  oLevelInstitutionId?: string;

  // A-Level credentials
  aLevelBoard?: string;
  aLevelBatch?: string;
  aLevelStatus?: string;
  aLevelSubjectsCount?: number;
  aLevelGrades?: string;
  aLevelGpaEquiv?: string;
  aLevelCollege?: string;
  aLevelInstitutionId?: string;

  medium: StudentMedium;
  nctbVersion?: NctbVersion | null;
  englishCurriculum?: EnglishCurriculum | null;
  academicBatch: string;
  institutionName: string;
  studyStreakDays: number;
  targetSelections: Record<string, string[]>;
  preferredUniversityTrack?: string;
  currentAcademicLevel?: string;
  preferredLanguage?: AppLanguage;
  preferredTheme?: ThemeMode;
  updatedAt?: string;
}

export interface UserProfileMetadataSummary {
  preferredUniversityTrack: string;
  currentAcademicLevel: string;
  studyMedium: StudentMedium;
  academicBatch: string;
  institutionName: string;
  targetUniversityCodes: string[];
  studyStreakDays: number;
  preferredLanguage?: AppLanguage;
  preferredTheme?: ThemeMode;
  syncedAt?: string | null;
}

export interface QuestionOption {
  id: string; // 'A', 'B', 'C', 'D'
  text: string;
  isCorrect?: boolean;
}

export interface Question {
  id: string;
  subjectId: string;
  subjectName: string;
  topicId?: string;
  topicName?: string;
  universityTags: string[];
  text: string;
  passage?: string;
  contextSnippet?: string;
  options: QuestionOption[];
  correctOptionId: string;
  explanation: string;
  hints: string[];
  hasMath?: boolean;
  difficulty?: 'easy' | 'medium' | 'hard';
  userAnswer?: string;
}

export interface DailyExamDetails {
  id: string;
  slug: string;
  title: string;
  track: string;
  examType?: 'model_test' | 'uni_exam' | 'section_exam' | 'daily_live';
  durationMinutes: number;
  totalMarks: number;
  negativeMark: number;
  questionCount: number;
  shareableUrl: string;
  questions: Question[];
  isLiveNow?: boolean;
  activeCandidates?: number;
}

export interface QuestionFeedback {
  questionId: string;
  selectedOption?: string;
  correctOption: string;
  isCorrect: boolean;
  explanation: string;
  hints: string[];
}

export interface ExamSubmissionResult {
  submissionId: string;
  candidateName: string;
  score: number;
  totalMarks: number;
  correctCount: number;
  wrongCount: number;
  unansweredCount: number;
  timeTakenSeconds: number;
  rank: number;
  totalParticipants: number;
  shareableResultText: string;
  feedback: QuestionFeedback[];
  isPractice: boolean;
}

export interface ExamHistoryItem {
  id: string;
  examSlug: string;
  title: string;
  track: string;
  mode: 'inApp' | 'omrBubble' | 'practice';
  score: number;
  totalQuestions: number;
  correctCount: number;
  wrongCount: number;
  unansweredCount: number;
  timeTakenSeconds: number;
  rank?: number;
  totalParticipants?: number;
  submittedAt: string;
  isDailyLive?: boolean;
  userAnswers: Record<string, string>;
  questionIds: string[];
}

export interface TopicAttemptRecord {
  id: string;
  questionId: string;
  subjectId: string;
  topicId: string;
  selectedOptionId: string;
  correctOptionId: string;
  isCorrect: boolean;
  timeSpentSeconds: number;
  negativePenalty: number;
  createdAt: string;
}

export type SpeedAccuracyQuadrant =
  | 'mastered_fast'
  | 'accurate_slow'
  | 'rushed_costly'
  | 'critical_deficit';

export interface TopicMasteryNode {
  topicId: string;
  topicName: string;
  subjectId: string;
  subjectName: string;
  masteryScore: number; // 0 - 100
  accuracyPercent: number; // 0 - 100
  fsrsStabilityDays: number;
  fsrsRetrievability: number; // 0 - 100
  dueCardCount: number;
  attemptsCount: number;
  correctCount: number;
  wrongCount: number;
  skippedCount: number;
  negativeMarksLost: number;
  avgTimeSeconds: number;
  targetTimeSeconds: number;
  quadrant: SpeedAccuracyQuadrant;
  universityRelevance: string[];
}

export interface SubjectMasteryNode {
  subjectId: string;
  subjectName: string;
  masteryPercent: number;
  retentionPercent: number;
  questionsAttempted: number;
  correctCount: number;
  wrongCount: number;
  negativeMarksLost: number;
  avgTimeSeconds: number;
  targetTimeSeconds: number;
  status: 'mastered' | 'on_track' | 'at_risk' | 'critical';
  topics: TopicMasteryNode[];
}

export interface UniversitySectionReadiness {
  name: string;
  weightPercent: number;
  projectedMarks: number;
  maxMarks: number;
  masteryPercent: number;
  color: string;
}

export interface UniversityReadinessProjection {
  universityCode: string;
  universityName: string;
  programName: string;
  projectedScore: number;
  totalMarks: number;
  cutOffScore: number;
  cutOffPercent: number;
  gapMarks: number; // positive = above cut-off, negative = deficit
  admissionProbabilityPercent: number;
  negativeMarkingPenalty: number;
  estimatedNetLossFromNegatives: number;
  sectionReadiness: UniversitySectionReadiness[];
  topBlockingTopics: TopicMasteryNode[];
}

export interface LearnerKnowledgeProfile {
  overallMasteryPercent: number;
  overallRetrievabilityPercent: number;
  totalAttempts: number;
  totalNegativeMarksLost: number;
  avgSolveSpeedSeconds: number;
  dueCardsTotal: number;
  leagueTier: {
    id: string;
    name: string;
    greekSymbol: string;
    colorHex: string;
  };
  subjects: SubjectMasteryNode[];
  topics: TopicMasteryNode[];
  universityProjections: Record<string, UniversityReadinessProjection>;
}

export type AITutorMode =
  | 'aether_solver'
  | 'socratic_tutor'
  | 'mistake_diagnosis'
  | 'study_planner'
  | 'formula_verifier';

export type AnswerBehaviorClass = 'deliberate' | 'impulse_guess' | 'over_dwell';

export type TouchGestureKind =
  | 'render'
  | 'scroll'
  | 'press_in'
  | 'touch_move'
  | 'option_inspect'
  | 'option_lock';

export type TouchCadenceLabel =
  | 'steady_deliberate'
  | 'rapid_impulsive'
  | 'scrolled_scanning'
  | 'prolonged_struggle';

export interface FingerTouchSample {
  kind: TouchGestureKind;
  relativeMs: number;
  x?: number;
  y?: number;
  optionId?: string;
}

export interface TouchPatternMetrics {
  totalTouchCount: number;
  scrollCount: number;
  pressInCount: number;
  hesitationGapMs: number;
  interTouchMeanMs: number;
  touchCadenceLabel: TouchCadenceLabel;
  touchTrace: FingerTouchSample[];
}

export interface DataLoggingQueueStatus {
  pendingCount: number;
  transmittedCount: number;
  failedAttemptsCount: number;
  isFlushing: boolean;
  lastSyncedAt?: string;
  lastError?: string;
}

export interface QuestionTimingTelemetry {
  id: string;
  eventId?: string;
  questionId: string;
  topicId?: string;
  subjectName: string;
  universityCode?: string;
  sourceScreen:
    | 'live_exam'
    | 'omr_sheet'
    | 'omr_exam'
    | 'practice'
    | 'battle_duel'
    | 'duel_1v1';
  renderTimestampMs: number;
  firstFingerActivityMs: number;
  answerLockedAtMs: number;
  readTimeMs: number;
  thinkTimeMs: number;
  totalTimeMs: number;
  expectedMinReadMs: number;
  touchInteractionCount: number;
  touchPattern?: TouchPatternMetrics;
  classification: AnswerBehaviorClass;
  behaviorClass?: AnswerBehaviorClass;
  lockedOptionId: string;
  selectedOptionId?: string;
  isCorrect: boolean;
  platform?: string;
  recordedAt: string;
}

export interface AppUsageTelemetry {
  activeFocusSeconds: number;
  appSwitchCount: number;
  sessionsStarted: number;
  sessionsCompleted: number;
  lastUpdatedAt: string;
}

export interface CandidateSeriousnessProfile {
  seriousnessScore: number;
  statusLabel: string;
  activeFocusSeconds: number;
  activeFocusMinutes: number;
  appSwitchCount: number;
  appSwitchInterrupts: number;
  impulseTapCount: number;
  deliberateCount: number;
  overDwellCount: number;
  lockedAnswersCount: number;
  sessionsStarted: number;
  sessionsCompleted: number;
  sessionCompletionRatePercent: number;
  avgReadTimeSeconds: number;
  avgReadSeconds: number;
  avgThinkTimeSeconds: number;
  avgThinkSeconds: number;
  avgTotalLockSeconds: number;
  impulseGuessRatePercent: number;
  recentEvents: QuestionTimingTelemetry[];
  recentTelemetry: QuestionTimingTelemetry[];
  aetherEvaluationNotes: string[];
  evaluationNotes: string[];
}

export interface AetherSyllabusModule {
  id: string;
  title: string;
  subjectName: string;
  topicId?: string;
  weightPercent: number;
  currentMasteryPercent: number;
  targetMasteryPercent: number;
  priorityLevel: 'CRITICAL' | 'HIGH' | 'CORE';
  estimatedHours: number;
  rationale: string;
}

export interface AetherUnifiedPersonalExam {
  slug: string;
  title: string;
  subtitle: string;
  universityCode: string;
  questionCount: number;
  durationMinutes: number;
  negativeMark: 0;
  calibrationSummary: string;
  focusSubjects: string[];
}

export interface AIStudentContextSnapshot {
  questionId?: string;
  questionText?: string;
  pickedOption?: string;
  correctOption?: string;
  subjectName?: string;
  topicId?: string;
  topicName?: string;
  topicMasteryPercent?: number;
  fsrsRetrievabilityPercent?: number;
  negativeMarksLost?: number;
  targetUniversity?: string;
  seriousnessScore?: number;
  impulseGuessRatePercent?: number;
}

export interface AIMessageRecord {
  messageId: string;
  threadId: string;
  role: 'system' | 'user' | 'assistant';
  content: string;
  socraticStep?: 1 | 2 | 3 | 'synthesis';
  aetherStage?: 'direct_solve' | 'shortcut' | 'diagnostic' | 'synthesis';
  studentContextSnapshot?: AIStudentContextSnapshot;
  modelSource:
    | 'cloudflare_local_gpu'
    | 'prep404_server_gateway'
    | 'aether_local_engine'
    | 'socratic_local_engine';
  latencyMs: number;
  tokenEstimate: number;
  timestamp: string;
}

export interface AIConversationThread {
  threadId: string;
  userId: string;
  title: string;
  mode: AITutorMode;
  questionId?: string;
  subjectId?: string;
  topicId?: string;
  topicName?: string;
  universityCode?: string;
  modelEndpointUsed: string;
  messages: AIMessageRecord[];
  createdAt: string;
  updatedAt: string;
  isResolved: boolean;
  studentRating?: 1 | 2 | 3 | 4 | 5;
}

export interface AIClusterGatewayConfig {
  cloudflareTunnelUrl: string;
  prep404ServerUrl: string;
  localModelName: string;
  keepFullConversationLedger: boolean;
  autoSyncToServer: boolean;
  lastHandshakeAt?: string;
  lastHandshakeStatus?: 'connected' | 'local_gateway_ready' | 'offline';
  lastLatencyMs?: number;
}

export type RoadmapSectionStatus = 'completed' | 'active' | 'locked';

export interface RoadmapMilestone {
  id: string;
  index: number;
  title: string;
  subtitle: string;
  subjectTag: string;
  questionCount: number;
  durationMinutes: number;
  xpReward: number;
  status: RoadmapSectionStatus;
  pillar: 'topic' | 'subject' | 'section' | 'overall';
  topicId?: string;
  accuracyPercent?: number;
}

export interface UniversityBlueprint {
  universityCode: string;
  universityName: string;
  programName: string;
  category: DisciplineCategory;
  totalQuestions: number;
  durationMinutes: number;
  negativeMarking: number;
  cutOffPercent: number;
  sections: {
    name: string;
    questionCount: number;
    marks: number;
    weightPercent: number;
    color: string;
  }[];
  patternNotes: string[];
}

export type BattlePhase =
  | 'idle'
  | 'queuing'
  | 'roomAssembly'
  | 'matched'
  | 'playing'
  | 'finished';

export interface BattlePlayer {
  id: string;
  name: string;
  college: string;
  score: number;
  roundPoints: number;
  hasAnswered: boolean;
  isReady?: boolean;
  isHost?: boolean;
}

export interface BattleHistoryItem {
  id: string;
  roomCode: string;
  track: string;
  opponentName: string;
  opponentCollege: string;
  yourScore: number;
  opponentScore: number;
  outcome: 'victory' | 'defeat' | 'draw';
  xpEarned: number;
  createdAt: string;
}

export interface LeaderboardEntry {
  rank: number;
  name: string;
  college: string;
  universityTrack: string;
  score: number;
  totalMarks: number;
  timeTakenSeconds: number;
  xp: number;
  isCurrentUser?: boolean;
}

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  eventType: 'exam_alert' | 'streak' | 'battle' | 'announcement';
  targetTab?: MainTab;
  isRead: boolean;
  createdAt: string;
}

export interface SupportRequest {
  id: string;
  category:
    | 'account_access'
    | 'profile_update'
    | 'learning_progress'
    | 'exam_access'
    | 'other';
  subject: string;
  message: string;
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  staffNote?: string;
  createdAt: string;
}

export interface ReportedQuestionItem {
  id: string;
  questionId: string;
  questionPreview: string;
  reason: string;
  details?: string;
  status: 'submitted' | 'under_review' | 'resolved';
  createdAt: string;
}

export interface CommunityLink {
  id: string;
  platform: 'facebook' | 'instagram' | 'linkedin' | 'twitter' | 'youtube';
  title: string;
  description: string;
  url: string;
}

export type MainTab = 'home' | 'plan' | 'questionBank' | 'dailyTest' | 'history';

export type ActiveRoute =
  | { name: 'dashboard'; tab: MainTab }
  | { name: 'battle' }
  | { name: 'practice'; subjectId?: string; topicId?: string; title?: string }
  | {
      name: 'liveExam';
      slug: string;
      title: string;
      durationMinutes: number;
      negativeMark: number;
      isPracticeMode?: boolean;
      questions?: Question[];
    }
  | {
      name: 'knowledgeProfile';
      initialUniversityCode?: string;
      initialSubjectId?: string;
    }
  | {
      name: 'aiTutor';
      questionId?: string;
      topicId?: string;
      subjectId?: string;
      threadId?: string;
      initialMode?: AITutorMode;
    }
  | { name: 'serverGateway' }
  | { name: 'universityDetail'; universityCode: string; initialTab?: number }
  | { name: 'subjectDirectory'; subjectSlug: string; subjectTitle: string }
  | { name: 'modelTestCatalog' }
  | { name: 'mistakeVault' }
  | { name: 'streakDetail' }
  | { name: 'examReview'; historyId: string }
  | { name: 'notifications' }
  | { name: 'profile' }
  | { name: 'accountInfo' }
  | { name: 'notificationSettings' }
  | { name: 'learnerSupport' }
  | { name: 'reportedQuestions' }
  | { name: 'aboutUs' }
  | { name: 'communityLinks' }
  | { name: 'upgrade' }
  | { name: 'subscription' }
  | { name: 'editProfile'; initialStep?: number };

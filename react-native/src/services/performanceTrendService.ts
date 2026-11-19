import { mean } from 'd3-array';
import { scaleLinear, scalePoint } from 'd3-scale';
import { area as d3Area, curveMonotoneX, line as d3Line } from 'd3-shape';
import { QUESTION_BANK } from '../data/questionBank';
import {
  ExamHistoryItem,
  Question,
  QuestionTimingTelemetry,
  TopicAttemptRecord,
} from '../types';
import { storageService } from './storageService';

export interface SubjectMeta {
  subjectId: string;
  subjectName: string;
  shortLabel: string;
  color: string;
}

export const SUBJECT_TREND_PALETTE: Record<string, SubjectMeta> = {
  all: {
    subjectId: 'all',
    subjectName: 'All Subjects',
    shortLabel: 'All',
    color: '#F28C28',
  },
  higher_math: {
    subjectId: 'higher_math',
    subjectName: 'Higher Mathematics',
    shortLabel: 'Higher Math',
    color: '#2563EB',
  },
  quant_math: {
    subjectId: 'quant_math',
    subjectName: 'Quantitative Aptitude',
    shortLabel: 'Quant Math',
    color: '#7C3AED',
  },
  physics: {
    subjectId: 'physics',
    subjectName: 'Physics',
    shortLabel: 'Physics',
    color: '#059669',
  },
  chemistry: {
    subjectId: 'chemistry',
    subjectName: 'Chemistry',
    shortLabel: 'Chemistry',
    color: '#D97706',
  },
  english: {
    subjectId: 'english',
    subjectName: 'English Grammar & Reading',
    shortLabel: 'English',
    color: '#DB2777',
  },
};

export interface TrendPoint {
  sessionKey: string;
  label: string;
  fullDateLabel: string;
  timestampMs: number;
  accuracyPercent: number;
  correctCount: number;
  wrongCount: number;
  attemptCount: number;
  source: 'exam' | 'telemetry' | 'practice' | 'mixed';
}

export interface SubjectTrendSeries {
  subjectId: string;
  subjectName: string;
  shortLabel: string;
  color: string;
  points: TrendPoint[];
  latestAccuracy: number;
  averageAccuracy: number;
  deltaPercent: number;
  totalAttempts: number;
  totalCorrect: number;
  totalWrong: number;
}

export interface PerformanceTrendDataset {
  hasData: boolean;
  totalAttempts: number;
  totalMistakes: number;
  overallSeries: SubjectTrendSeries;
  subjectSeries: SubjectTrendSeries[];
  timelineKeys: string[];
  timelineLabels: Record<string, string>;
}

export interface PlottedTrendPoint {
  point: TrendPoint;
  x: number;
  y: number;
}

export interface RenderedD3Series {
  subjectId: string;
  subjectName: string;
  shortLabel: string;
  color: string;
  linePath: string;
  areaPath: string;
  plottedPoints: PlottedTrendPoint[];
}

export interface D3ChartGeometry {
  width: number;
  height: number;
  margin: { top: number; right: number; bottom: number; left: number };
  innerWidth: number;
  innerHeight: number;
  yTicks: { value: number; y: number; label: string }[];
  targetLineY: number;
  xTicks: { key: string; label: string; x: number }[];
  renderedSeries: RenderedD3Series[];
}

interface RawAttemptSample {
  questionId: string;
  subjectId: string;
  subjectName: string;
  isCorrect: boolean;
  timestampMs: number;
  sessionGroupHint?: string;
  source: 'exam' | 'telemetry' | 'practice';
}

const QUESTION_MAP = new Map<string, Question>(
  QUESTION_BANK.map((q) => [q.id, q])
);

const MONTH_SHORT = [
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

function normalizeSubjectId(
  rawSubjectId?: string,
  rawSubjectName?: string,
  questionId?: string
): SubjectMeta {
  const q = questionId ? QUESTION_MAP.get(questionId) : undefined;
  const candidateId = (rawSubjectId || q?.subjectId || '').trim().toLowerCase();
  if (candidateId && SUBJECT_TREND_PALETTE[candidateId]) {
    return SUBJECT_TREND_PALETTE[candidateId];
  }

  const nameLower = (rawSubjectName || q?.subjectName || '').toLowerCase();
  if (nameLower.includes('higher') || nameLower.includes('calculus')) {
    return SUBJECT_TREND_PALETTE.higher_math;
  }
  if (nameLower.includes('quant') || nameLower.includes('sat') || nameLower.includes('math')) {
    return SUBJECT_TREND_PALETTE.quant_math;
  }
  if (nameLower.includes('phys')) {
    return SUBJECT_TREND_PALETTE.physics;
  }
  if (nameLower.includes('chem')) {
    return SUBJECT_TREND_PALETTE.chemistry;
  }
  if (nameLower.includes('eng') || nameLower.includes('vocab') || nameLower.includes('grammar')) {
    return SUBJECT_TREND_PALETTE.english;
  }

  const fallbackName = rawSubjectName || q?.subjectName || 'General';
  const fallbackId =
    candidateId || fallbackName.toLowerCase().replace(/[^a-z0-9]+/g, '_');
  return {
    subjectId: fallbackId,
    subjectName: fallbackName,
    shortLabel: fallbackName.split(' ')[0] || 'General',
    color: '#0EA5E9',
  };
}

function formatDayKey(ts: number): string {
  const d = new Date(ts);
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function formatReadableDate(ts: number): string {
  const d = new Date(ts);
  const mon = MONTH_SHORT[d.getUTCMonth()] || 'Day';
  const day = d.getUTCDate();
  const hh = String(d.getUTCHours()).padStart(2, '0');
  const mm = String(d.getUTCMinutes()).padStart(2, '0');
  return `${mon} ${day}, ${hh}:${mm}`;
}

function formatShortDate(ts: number): string {
  const d = new Date(ts);
  const mon = MONTH_SHORT[d.getUTCMonth()] || 'Day';
  return `${mon} ${d.getUTCDate()}`;
}

function clampPercent(val: number): number {
  if (!Number.isFinite(val)) return 0;
  return Math.max(0, Math.min(100, Math.round(val)));
}

/**
 * Aggregates real exam submissions, topic practice attempts, and finger-telemetry
 * answer locks into chronological subject-wise accuracy percentages (0-100%).
 * Strictly zero fake/seeded records — returns `hasData: false` when empty.
 */
export function buildSubjectPerformanceTrends(input?: {
  examHistory?: ExamHistoryItem[];
  topicAttempts?: TopicAttemptRecord[];
  questionTelemetry?: QuestionTimingTelemetry[];
}): PerformanceTrendDataset {
  const examHistory = input?.examHistory ?? storageService.getExamHistory();
  const topicAttempts = input?.topicAttempts ?? storageService.getTopicAttempts();
  const questionTelemetry =
    input?.questionTelemetry ?? storageService.getQuestionTelemetryHistory();

  const samples: RawAttemptSample[] = [];
  const examLoggedSignatures = new Set<string>();

  // 1. Ingest completed exams (each exam is a clean chronological session bucket)
  const orderedExams = [...examHistory].sort(
    (a, b) => Date.parse(a.submittedAt) - Date.parse(b.submittedAt)
  );
  for (const exam of orderedExams) {
    const ts = Date.parse(exam.submittedAt) || Date.now();
    const bucketHint = `exam_${exam.id}`;
    for (const qId of exam.questionIds) {
      const picked = exam.userAnswers[qId];
      if (!picked) continue; // unanswered/skipped questions are tracked separately in deficit list
      const q = QUESTION_MAP.get(qId);
      if (!q) continue;
      const meta = normalizeSubjectId(q.subjectId, q.subjectName, q.id);
      const isCorrect = picked.toUpperCase() === q.correctOptionId.toUpperCase();
      samples.push({
        questionId: q.id,
        subjectId: meta.subjectId,
        subjectName: meta.subjectName,
        isCorrect,
        timestampMs: ts,
        sessionGroupHint: bucketHint,
        source: 'exam',
      });
      // Deduplicate against telemetry locks captured inside this same exam window
      examLoggedSignatures.add(`${q.id}_${Math.floor(ts / 600_000)}`);
    }
  }

  // 2. Ingest topic practice attempts
  for (const att of topicAttempts) {
    const ts = Date.parse(att.createdAt) || Date.now();
    const sig = `${att.questionId}_${Math.floor(ts / 600_000)}`;
    if (examLoggedSignatures.has(sig)) continue;
    examLoggedSignatures.add(sig);
    const meta = normalizeSubjectId(att.subjectId, undefined, att.questionId);
    samples.push({
      questionId: att.questionId,
      subjectId: meta.subjectId,
      subjectName: meta.subjectName,
      isCorrect: att.isCorrect,
      timestampMs: ts,
      source: 'practice',
    });
  }

  // 3. Ingest direct finger-telemetry locks (1v1 Duels, Practice Drills, Live Exam locks)
  for (const tel of questionTelemetry) {
    const ts = tel.answerLockedAtMs || Date.parse(tel.recordedAt) || Date.now();
    const sig = `${tel.questionId}_${Math.floor(ts / 600_000)}`;
    if (examLoggedSignatures.has(sig)) continue;
    examLoggedSignatures.add(sig);
    const meta = normalizeSubjectId(undefined, tel.subjectName, tel.questionId);
    samples.push({
      questionId: tel.questionId,
      subjectId: meta.subjectId,
      subjectName: meta.subjectName,
      isCorrect: tel.isCorrect,
      timestampMs: ts,
      source: 'telemetry',
    });
  }

  if (samples.length === 0) {
    const emptyOverall: SubjectTrendSeries = {
      ...SUBJECT_TREND_PALETTE.all,
      points: [],
      latestAccuracy: 0,
      averageAccuracy: 0,
      deltaPercent: 0,
      totalAttempts: 0,
      totalCorrect: 0,
      totalWrong: 0,
    };
    return {
      hasData: false,
      totalAttempts: 0,
      totalMistakes: 0,
      overallSeries: emptyOverall,
      subjectSeries: [],
      timelineKeys: [],
      timelineLabels: {},
    };
  }

  // Sort chronologically
  samples.sort((a, b) => a.timestampMs - b.timestampMs);

  // Group into ordered chronological session buckets
  interface SessionBucket {
    key: string;
    timestampMs: number;
    dayKey: string;
    samples: RawAttemptSample[];
  }

  const buckets: SessionBucket[] = [];
  const examBucketIndex = new Map<string, SessionBucket>();

  for (const sample of samples) {
    if (sample.sessionGroupHint) {
      let existing = examBucketIndex.get(sample.sessionGroupHint);
      if (!existing) {
        existing = {
          key: sample.sessionGroupHint,
          timestampMs: sample.timestampMs,
          dayKey: formatDayKey(sample.timestampMs),
          samples: [],
        };
        examBucketIndex.set(sample.sessionGroupHint, existing);
        buckets.push(existing);
      }
      existing.samples.push(sample);
      continue;
    }

    const dayKey = formatDayKey(sample.timestampMs);
    const last = buckets[buckets.length - 1];
    const canJoinLast =
      last &&
      !last.key.startsWith('exam_') &&
      last.dayKey === dayKey &&
      sample.timestampMs - last.timestampMs <= 15 * 60 * 1000 &&
      last.samples.length < 6;

    if (canJoinLast) {
      last.samples.push(sample);
      last.timestampMs = sample.timestampMs;
    } else {
      buckets.push({
        key: `sess_${buckets.length + 1}_${sample.timestampMs}`,
        timestampMs: sample.timestampMs,
        dayKey,
        samples: [sample],
      });
    }
  }

  buckets.sort((a, b) => a.timestampMs - b.timestampMs);

  // Keep up to the 12 most recent chronological checkpoints for crisp readability
  const recentBuckets = buckets.slice(-12);
  const distinctDays = new Set(recentBuckets.map((b) => b.dayKey));
  const spansMultipleDays = distinctDays.size > 1;
  const dayCounters = new Map<string, number>();

  const timelineKeys: string[] = [];
  const timelineLabels: Record<string, string> = {};

  const bucketLabels = new Map<string, string>();
  recentBuckets.forEach((b, idx) => {
    const countOnDay = (dayCounters.get(b.dayKey) || 0) + 1;
    dayCounters.set(b.dayKey, countOnDay);
    const label = spansMultipleDays
      ? countOnDay > 1
        ? `${formatShortDate(b.timestampMs)} #${countOnDay}`
        : formatShortDate(b.timestampMs)
      : `S${idx + 1}`;
    timelineKeys.push(b.key);
    timelineLabels[b.key] = label;
    bucketLabels.set(b.key, label);
  });

  // Build overall + per-subject series
  const subjectPointsMap = new Map<string, TrendPoint[]>();
  const overallPoints: TrendPoint[] = [];

  for (const bucket of recentBuckets) {
    const label = bucketLabels.get(bucket.key) || 'S1';
    const fullDateLabel = formatReadableDate(bucket.timestampMs);
    const sources = new Set(bucket.samples.map((s) => s.source));
    const bucketSource: TrendPoint['source'] =
      sources.size === 1 ? Array.from(sources)[0] : 'mixed';

    const totalCorrect = bucket.samples.filter((s) => s.isCorrect).length;
    const totalCount = bucket.samples.length;
    overallPoints.push({
      sessionKey: bucket.key,
      label,
      fullDateLabel,
      timestampMs: bucket.timestampMs,
      accuracyPercent: clampPercent((totalCorrect / totalCount) * 100),
      correctCount: totalCorrect,
      wrongCount: totalCount - totalCorrect,
      attemptCount: totalCount,
      source: bucketSource,
    });

    const perSubject = new Map<string, RawAttemptSample[]>();
    for (const s of bucket.samples) {
      const arr = perSubject.get(s.subjectId) || [];
      arr.push(s);
      perSubject.set(s.subjectId, arr);
    }

    perSubject.forEach((list, subjectId) => {
      const right = list.filter((x) => x.isCorrect).length;
      const count = list.length;
      const pts = subjectPointsMap.get(subjectId) || [];
      pts.push({
        sessionKey: bucket.key,
        label,
        fullDateLabel,
        timestampMs: bucket.timestampMs,
        accuracyPercent: clampPercent((right / count) * 100),
        correctCount: right,
        wrongCount: count - right,
        attemptCount: count,
        source: bucketSource,
      });
      subjectPointsMap.set(subjectId, pts);
    });
  }

  const summarizeSeries = (
    meta: SubjectMeta,
    points: TrendPoint[]
  ): SubjectTrendSeries => {
    const totalAttempts = points.reduce((acc, p) => acc + p.attemptCount, 0);
    const totalCorrect = points.reduce((acc, p) => acc + p.correctCount, 0);
    const totalWrong = points.reduce((acc, p) => acc + p.wrongCount, 0);
    const latestAccuracy =
      points.length > 0 ? points[points.length - 1].accuracyPercent : 0;
    const firstAccuracy = points.length > 0 ? points[0].accuracyPercent : 0;
    const avgVal = mean(points, (p) => p.accuracyPercent) ?? 0;

    return {
      ...meta,
      points,
      latestAccuracy,
      averageAccuracy: clampPercent(avgVal),
      deltaPercent: points.length >= 2 ? latestAccuracy - firstAccuracy : 0,
      totalAttempts,
      totalCorrect,
      totalWrong,
    };
  };

  const overallSeries = summarizeSeries(SUBJECT_TREND_PALETTE.all, overallPoints);
  const subjectSeries: SubjectTrendSeries[] = Array.from(subjectPointsMap.entries())
    .map(([subjectId, pts]) => {
      const meta = normalizeSubjectId(subjectId);
      return summarizeSeries(meta, pts);
    })
    .sort((a, b) => b.totalAttempts - a.totalAttempts);

  return {
    hasData: true,
    totalAttempts: overallSeries.totalAttempts,
    totalMistakes: overallSeries.totalWrong,
    overallSeries,
    subjectSeries,
    timelineKeys,
    timelineLabels,
  };
}

/**
 * Pure D3 scale + path geometry calculator (using `d3-scale` + `d3-shape`).
 * Produces responsive SVG coordinates and smooth `curveMonotoneX` paths
 * consumable by `react-native-svg` across Android, iOS, and Web.
 */
export function computeD3TrendGeometry(params: {
  seriesList: SubjectTrendSeries[];
  timelineKeys: string[];
  timelineLabels: Record<string, string>;
  width: number;
  height: number;
}): D3ChartGeometry {
  const width = Math.max(260, Math.round(params.width));
  const height = Math.max(180, Math.round(params.height));
  const margin = { top: 18, right: 20, bottom: 34, left: 40 };
  const innerWidth = Math.max(120, width - margin.left - margin.right);
  const innerHeight = Math.max(100, height - margin.top - margin.bottom);

  const yScale = scaleLinear().domain([0, 100]).range([innerHeight, 0]);
  const yTickValues = [0, 25, 50, 75, 100];
  const yTicks = yTickValues.map((value) => ({
    value,
    y: Number(yScale(value).toFixed(2)),
    label: `${value}%`,
  }));

  const targetLineY = Number(yScale(80).toFixed(2));

  const domainKeys =
    params.timelineKeys.length > 0 ? params.timelineKeys : ['empty_1', 'empty_2'];

  const xScale = scalePoint<string>()
    .domain(domainKeys)
    .range([0, innerWidth])
    .padding(domainKeys.length === 1 ? 0.5 : 0.12);

  const xTicks =
    params.timelineKeys.length > 0
      ? params.timelineKeys.map((key) => ({
          key,
          label: params.timelineLabels[key] || key,
          x: Number((xScale(key) ?? innerWidth / 2).toFixed(2)),
        }))
      : [];

  const lineGenerator = d3Line<PlottedTrendPoint>()
    .x((d) => d.x)
    .y((d) => d.y)
    .curve(curveMonotoneX);

  const areaGenerator = d3Area<PlottedTrendPoint>()
    .x((d) => d.x)
    .y0(innerHeight)
    .y1((d) => d.y)
    .curve(curveMonotoneX);

  const renderedSeries: RenderedD3Series[] = params.seriesList.map((series) => {
    const plottedPoints: PlottedTrendPoint[] = series.points.map((point) => {
      const rawX = xScale(point.sessionKey);
      const x = Number((rawX ?? innerWidth / 2).toFixed(2));
      const y = Number(yScale(clampPercent(point.accuracyPercent)).toFixed(2));
      return { point, x, y };
    });

    const linePath =
      plottedPoints.length >= 2 ? lineGenerator(plottedPoints) || '' : '';
    const areaPath =
      plottedPoints.length >= 2 ? areaGenerator(plottedPoints) || '' : '';

    return {
      subjectId: series.subjectId,
      subjectName: series.subjectName,
      shortLabel: series.shortLabel,
      color: series.color,
      linePath,
      areaPath,
      plottedPoints,
    };
  });

  return {
    width,
    height,
    margin,
    innerWidth,
    innerHeight,
    yTicks,
    targetLineY,
    xTicks,
    renderedSeries,
  };
}

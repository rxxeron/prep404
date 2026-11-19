import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  AppState,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CheckCircle,
  Clock,
  Devices,
  Eye,
  FileText,
  Flag,
  GridFour,
  LockKey,
  SquaresFour,
  WifiHigh,
  WifiSlash,
  XCircle,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { DEFAULT_LEADERBOARD, MODEL_TESTS_CATALOG } from '../data/questionBank';
import {
  adjustExamSessionDuration,
  buildExamDetails,
  computeElapsedSeconds,
  computeRemainingSeconds,
  createExamSessionTiming,
  ExamSessionTiming,
  formatSecondsHMS,
  getDailyWindowStatus,
  scoreAndPersistExam,
  summarizeExamProgress,
} from '../services/examService';
import { storageService } from '../services/storageService';
import { extractTouchPoint } from '../services/dataLoggingService';
import {
  lockQuestionAnswerTelemetry,
  recordQuestionFingerActivity,
  recordStudySessionComplete,
  recordStudySessionStart,
  startQuestionTelemetry,
} from '../services/telemetryService';
import { ExamSubmissionResult, Question, QuestionTimingTelemetry } from '../types';
import { AppPalette, PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import { MathText } from '../components/MathText';
import { ProgressRing } from '../components/ProgressRing';
import { useNetworkStatus } from '../utils/useNetworkStatus';
import {
  BottomSheetModal,
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';

const ACTIVE_EXAM_STORAGE_PREFIX = 'prep404_active_exam_v1_';

interface PersistedActiveExamSession {
  mode: 'inApp' | 'omrBubble';
  viewStyle: 'focus' | 'sheet';
  activeIdx: number;
  sessionTiming: ExamSessionTiming;
  answers: Record<string, string>;
  flaggedIds: Record<string, boolean>;
}

function loadActiveExamSession(slug: string): PersistedActiveExamSession | null {
  try {
    if (typeof window === 'undefined' || !window.sessionStorage) return null;
    const raw = window.sessionStorage.getItem(`${ACTIVE_EXAM_STORAGE_PREFIX}${slug}`);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as PersistedActiveExamSession;
    if (
      !parsed ||
      !parsed.sessionTiming ||
      typeof parsed.sessionTiming.deadlineMs !== 'number'
    ) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function saveActiveExamSession(slug: string, data: PersistedActiveExamSession): void {
  try {
    if (typeof window === 'undefined' || !window.sessionStorage) return;
    window.sessionStorage.setItem(
      `${ACTIVE_EXAM_STORAGE_PREFIX}${slug}`,
      JSON.stringify(data)
    );
  } catch {
    // Ignore storage quota errors
  }
}

function clearActiveExamSession(slug: string): void {
  try {
    if (typeof window === 'undefined' || !window.sessionStorage) return;
    window.sessionStorage.removeItem(`${ACTIVE_EXAM_STORAGE_PREFIX}${slug}`);
  } catch {
    // Ignore storage errors
  }
}

/**
 * Isolated 1Hz Daily Window Status Ticker.
 * Prevents DailyExamArenaScreen leaderboard and past drills from re-rendering every second.
 */
const DailyWindowStatusRow = React.memo<{ palette: AppPalette }>(({ palette }) => {
  const [status, setStatus] = useState(() => getDailyWindowStatus());

  useEffect(() => {
    const sync = () => setStatus(getDailyWindowStatus());
    const id = setInterval(sync, 1000);
    const sub = AppState.addEventListener('change', (nextState) => {
      if (nextState === 'active') sync();
    });
    return () => {
      clearInterval(id);
      sub.remove();
    };
  }, []);

  return (
    <View style={styles.cardTopRow}>
      <Text
        style={[
          styles.liveTag,
          { color: status.isOpen ? palette.success : palette.primary },
        ]}
      >
        {status.label}
      </Text>
      <Text style={[styles.monoMetric, { color: palette.text }]}>
        {status.countdownText}
      </Text>
    </View>
  );
});

/**
 * Isolated 1Hz Wall-Clock Exam Countdown HUD.
 * Computes remaining time from monotonic/wall-clock deadlineMs so:
 * 1) 1Hz ticks NEVER re-render LiveModelTestScreen or question components.
 * 2) Backgrounding and restoring the app immediately syncs true remaining time via React Native AppState.
 */
const ExamCountdownTimer = React.memo<{
  deadlineMs: number;
  onExpire: () => void;
  palette: AppPalette;
}>(({ deadlineMs, onExpire, palette }) => {
  const [secondsLeft, setSecondsLeft] = useState(() =>
    computeRemainingSeconds(deadlineMs)
  );
  const expiredFiredRef = useRef(false);
  const onExpireRef = useRef(onExpire);
  onExpireRef.current = onExpire;

  useEffect(() => {
    expiredFiredRef.current = false;

    const syncClock = () => {
      const rem = computeRemainingSeconds(deadlineMs, Date.now());
      setSecondsLeft((prev) => (prev === rem ? prev : rem));
      if (rem <= 0 && !expiredFiredRef.current) {
        expiredFiredRef.current = true;
        onExpireRef.current();
      }
    };

    syncClock();
    const id = setInterval(syncClock, 1000);

    const appStateSub = AppState.addEventListener('change', (nextState) => {
      if (nextState === 'active') {
        syncClock();
      }
    });

    return () => {
      clearInterval(id);
      appStateSub.remove();
    };
  }, [deadlineMs]);

  const isTimerLow = secondsLeft <= 60;
  const formatted = formatSecondsHMS(secondsLeft);

  return (
    <View
      accessibilityLabel={`Time remaining ${formatted}`}
      style={styles.timerRow}
    >
      <Clock
        size={16}
        color={isTimerLow ? palette.danger : palette.primary}
        weight="bold"
      />
      <Text
        style={[
          styles.hudTimer,
          { color: isTimerLow ? palette.danger : palette.primary },
        ]}
      >
        {formatted}
      </Text>
    </View>
  );
});

/**
 * Isolated Remaining Time Readout inside the Submit Confirmation Modal.
 */
const SubmitModalRemainingBanner = React.memo<{
  deadlineMs: number;
  palette: AppPalette;
}>(({ deadlineMs, palette }) => {
  const [secondsLeft, setSecondsLeft] = useState(() =>
    computeRemainingSeconds(deadlineMs)
  );

  useEffect(() => {
    const sync = () => setSecondsLeft(computeRemainingSeconds(deadlineMs));
    sync();
    const id = setInterval(sync, 1000);
    return () => clearInterval(id);
  }, [deadlineMs]);

  return (
    <Text style={[styles.monoSmall, { color: palette.textMuted, marginTop: -6 }]}>
      Time remaining: {formatSecondsHMS(secondsLeft)}
    </Text>
  );
});

/**
 * Isolated Progress Bar — only re-renders when answeredCount or totalCount changes.
 */
const MemoExamProgressBar = React.memo<{
  answeredCount: number;
  totalCount: number;
  fillColor: string;
  trackColor: string;
}>(({ answeredCount, totalCount, fillColor, trackColor }) => {
  const pct = totalCount > 0 ? (answeredCount / totalCount) * 100 : 0;
  return (
    <View style={[styles.progressTrack, { backgroundColor: trackColor }]}>
      <View
        style={[
          styles.progressFill,
          {
            width: `${pct}%`,
            backgroundColor: fillColor,
          },
        ]}
      />
    </View>
  );
});

/**
 * Isolated HUD Question Navigator Trigger — only re-renders when answeredCount or flaggedCount changes.
 */
const MemoHudNavigatorTrigger = React.memo<{
  answeredCount: number;
  totalCount: number;
  flaggedCount: number;
  onOpen: () => void;
  palette: AppPalette;
}>(({ answeredCount, totalCount, flaggedCount, onOpen, palette }) => (
  <TouchableOpacity
    onPress={onOpen}
    accessibilityRole="button"
    accessibilityLabel={`Open question navigator, ${answeredCount} of ${totalCount} answered${flaggedCount > 0 ? `, ${flaggedCount} flagged` : ''}`}
    style={[styles.viewToggle, { borderColor: palette.borderStrong }]}
  >
    <SquaresFour size={14} color={palette.text} weight="regular" />
    <Text style={[styles.hudCount, { color: palette.text }]}>
      {answeredCount}/{totalCount}
    </Text>
    {flaggedCount > 0 && (
      <View style={styles.hudFlagInline}>
        <Flag size={11} color={palette.amber} weight="fill" />
        <Text style={[styles.hudFlagCount, { color: palette.amber }]}>
          {flaggedCount}
        </Text>
      </View>
    )}
  </TouchableOpacity>
));

/**
 * Isolated Question Stepper Bubble — only re-renders when this specific question's
 * current/answered/flagged state changes.
 */
const MemoNavBubble = React.memo<{
  index: number;
  isCurrent: boolean;
  isAnswered: boolean;
  isFlagged: boolean;
  onSelectIndex: (idx: number) => void;
  palette: AppPalette;
}>(({ index, isCurrent, isAnswered, isFlagged, onSelectIndex, palette }) => (
  <TouchableOpacity
    onPress={() => onSelectIndex(index)}
    accessibilityRole="button"
    accessibilityLabel={`Question ${index + 1}${isFlagged ? ', flagged' : ''}${isAnswered ? ', locked' : ''}`}
    style={[
      styles.navBubble,
      {
        backgroundColor: isCurrent
          ? palette.text
          : isFlagged
            ? palette.warningSoft
            : isAnswered
              ? palette.creamTint
              : palette.surface,
        borderColor: isCurrent
          ? palette.text
          : isFlagged
            ? palette.amber
            : isAnswered
              ? palette.primary
              : palette.border,
      },
    ]}
  >
    <Text
      style={{
        fontFamily: TYPE_FONTS.mono,
        color: isCurrent
          ? palette.bg
          : isFlagged
            ? palette.amber
            : isAnswered
              ? palette.primary
              : palette.text,
        fontSize: 12.5,
        fontWeight: '700',
      }}
    >
      {index + 1}
    </Text>
    {isFlagged && (
      <View style={[styles.navFlagDot, { backgroundColor: palette.amber }]} />
    )}
  </TouchableOpacity>
));

/**
 * Isolated OMR Bubble Row — selecting a bubble on Q1 permanently locks Q1 and records Read->Think->Lock telemetry.
 */
const MemoOmrQuestionRow = React.memo<{
  question: Question;
  index: number;
  isLast: boolean;
  selectedOption: string | undefined;
  isFlagged: boolean;
  telemetry?: QuestionTimingTelemetry;
  onSelectOption: (questionId: string, optionId: string) => void;
  onToggleFlag: (questionId: string) => void;
  onPreviewQuestion: (question: Question) => void;
  palette: AppPalette;
}>(
  ({
    question,
    index,
    isLast,
    selectedOption,
    isFlagged,
    telemetry,
    onSelectOption,
    onToggleFlag,
    onPreviewQuestion,
    palette,
  }) => {
    const isLocked = Boolean(selectedOption);
    return (
      <HairlineRow
        isLast={isLast}
        highlightedBg={isFlagged ? palette.warningSoft : undefined}
        left={
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
            <TouchableOpacity
              onPress={(e) => {
                recordQuestionFingerActivity(question.id, {
                  kind: 'option_inspect',
                  ...extractTouchPoint(e),
                });
                onPreviewQuestion(question);
              }}
              accessibilityRole="button"
              accessibilityLabel={`Preview question ${index + 1}`}
              style={styles.omrQTrigger}
            >
              <Text
                style={{
                  fontFamily: TYPE_FONTS.mono,
                  color: palette.primary,
                  fontWeight: '700',
                  fontSize: 13.5,
                }}
              >
                Q{String(index + 1).padStart(2, '0')}
              </Text>
              <Eye size={14} color={palette.primary} weight="regular" />
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => onToggleFlag(question.id)}
              accessibilityRole="button"
              accessibilityLabel={`${isFlagged ? 'Unflag' : 'Flag'} question ${index + 1}`}
              style={[
                styles.flagIconBtn,
                {
                  borderColor: isFlagged ? palette.amber : palette.border,
                  backgroundColor: isFlagged ? palette.warningSoft : palette.surfaceMuted,
                },
              ]}
            >
              <Flag
                size={13}
                color={isFlagged ? palette.amber : palette.textMuted}
                weight={isFlagged ? 'fill' : 'regular'}
              />
            </TouchableOpacity>
            {isLocked && (
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 3 }}>
                <LockKey size={12} color={palette.primary} weight="fill" />
                <Text
                  style={{
                    fontFamily: TYPE_FONTS.mono,
                    fontSize: 10.5,
                    fontWeight: '700',
                    color:
                      telemetry?.behaviorClass === 'impulse_guess'
                        ? palette.danger
                        : palette.primary,
                  }}
                >
                  {telemetry
                    ? `${(telemetry.totalTimeMs / 1000).toFixed(1)}s`
                    : 'LOCKED'}
                </Text>
              </View>
            )}
          </View>
        }
        right={
          <View style={{ flexDirection: 'row', gap: 8 }}>
            {['A', 'B', 'C', 'D'].map((letter) => {
              const filled = selectedOption === letter;
              return (
                <TouchableOpacity
                  key={letter}
                  disabled={isLocked && !filled}
                  onPressIn={(e) =>
                    recordQuestionFingerActivity(question.id, {
                      kind: 'press_in',
                      optionId: letter,
                      ...extractTouchPoint(e),
                    })
                  }
                  onPress={() => onSelectOption(question.id, letter)}
                  accessibilityRole="button"
                  accessibilityLabel={`Question ${index + 1} bubble ${letter}${isLocked ? ' locked' : ''}`}
                  style={[
                    styles.bubble,
                    {
                      backgroundColor: filled
                        ? PREP404_COLORS.plum
                        : palette.surface,
                      borderColor: filled
                        ? PREP404_COLORS.plum
                        : palette.borderStrong,
                      opacity: isLocked && !filled ? 0.38 : 1,
                    },
                  ]}
                >
                  <Text
                    style={{
                      fontFamily: TYPE_FONTS.mono,
                      color: filled ? '#FFFFFF' : palette.text,
                      fontWeight: '700',
                      fontSize: 13,
                    }}
                  >
                    {letter}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        }
      />
    );
  }
);

/**
 * Isolated List-Mode Question Card — selecting an option permanently locks that question.
 */
const MemoListQuestionCard = React.memo<{
  question: Question;
  index: number;
  selectedOption: string | undefined;
  isFlagged: boolean;
  telemetry?: QuestionTimingTelemetry;
  onSelectOption: (questionId: string, optionId: string) => void;
  onToggleFlag: (questionId: string) => void;
  palette: AppPalette;
}>(
  ({
    question,
    index,
    selectedOption,
    isFlagged,
    telemetry,
    onSelectOption,
    onToggleFlag,
    palette,
  }) => {
    const isLocked = Boolean(selectedOption);
    return (
      <EditorialCard>
        <View style={styles.cardTopRow}>
          <Text style={[styles.monoSmall, { color: palette.textMuted, flex: 1 }]}>
            Q{index + 1} · {question.subjectName}
          </Text>
          {isLocked && (
            <View
              style={[
                styles.reviewFlagTag,
                {
                  backgroundColor:
                    telemetry?.behaviorClass === 'impulse_guess'
                      ? palette.dangerSoft
                      : palette.creamTint,
                  borderColor:
                    telemetry?.behaviorClass === 'impulse_guess'
                      ? palette.danger
                      : palette.primary,
                },
              ]}
            >
              <LockKey
                size={11}
                color={
                  telemetry?.behaviorClass === 'impulse_guess'
                    ? palette.danger
                    : palette.primary
                }
                weight="fill"
              />
              <Text
                style={{
                  fontFamily: TYPE_FONTS.mono,
                  fontSize: 10.5,
                  fontWeight: '700',
                  color:
                    telemetry?.behaviorClass === 'impulse_guess'
                      ? palette.danger
                      : palette.primary,
                }}
              >
                {telemetry
                  ? `LOCKED · R ${(telemetry.readTimeMs / 1000).toFixed(1)}s · T ${(telemetry.thinkTimeMs / 1000).toFixed(1)}s`
                  : 'LOCKED'}
              </Text>
            </View>
          )}
          <TouchableOpacity
            onPress={() => onToggleFlag(question.id)}
            accessibilityRole="button"
            accessibilityLabel={`${isFlagged ? 'Unflag' : 'Flag'} question ${index + 1}`}
            accessibilityState={{ selected: isFlagged }}
            style={[
              styles.flagToggleBtn,
              {
                borderColor: isFlagged ? palette.amber : palette.borderStrong,
                backgroundColor: isFlagged ? palette.warningSoft : palette.surfaceMuted,
              },
            ]}
          >
            <Flag
              size={14}
              color={isFlagged ? palette.amber : palette.textMuted}
              weight={isFlagged ? 'fill' : 'regular'}
            />
            <Text
              style={{
                fontSize: 12,
                fontWeight: '700',
                color: isFlagged ? palette.amber : palette.textMuted,
              }}
            >
              {isFlagged ? 'Flagged' : 'Flag'}
            </Text>
          </TouchableOpacity>
        </View>
        <MathText
          text={question.text}
          style={{ color: palette.text, fontSize: 15, fontWeight: '700', lineHeight: 22 }}
        />
        {question.options.map((opt) => {
          const chosen = selectedOption === opt.id;
          return (
            <TouchableOpacity
              key={opt.id}
              disabled={isLocked && !chosen}
              onPressIn={(e) =>
                recordQuestionFingerActivity(question.id, {
                  kind: 'press_in',
                  optionId: opt.id,
                  ...extractTouchPoint(e),
                })
              }
              onPress={() => onSelectOption(question.id, opt.id)}
              style={[
                styles.optBtn,
                {
                  borderColor: chosen ? palette.primary : palette.border,
                  backgroundColor: chosen ? palette.creamTint : palette.surface,
                  opacity: isLocked && !chosen ? 0.5 : 1,
                },
              ]}
            >
              <View
                style={[
                  styles.optLetterBox,
                  {
                    backgroundColor: chosen
                      ? palette.primary
                      : palette.surfaceMuted,
                  },
                ]}
              >
                <Text
                  style={{
                    fontFamily: TYPE_FONTS.mono,
                    fontWeight: '700',
                    color: chosen ? palette.primaryInk : palette.text,
                    fontSize: 13,
                  }}
                >
                  {opt.id}
                </Text>
              </View>
              <MathText
                text={opt.text}
                style={{ color: palette.text, fontSize: 14, flex: 1 }}
              />
              {chosen && (
                <LockKey size={16} color={palette.primary} weight="fill" />
              )}
            </TouchableOpacity>
          );
        })}
      </EditorialCard>
    );
  }
);

export const DailyExamArenaScreen: React.FC = () => {
  const { profile, palette, navigate } = useApp();
  const [uniFilter, setUniFilter] = useState('ALL');

  const track = uniFilter === 'ALL' ? 'NSU' : uniFilter;

  const leaderboard = useMemo(() => {
    const rows = [...DEFAULT_LEADERBOARD];
    const latest = storageService.getExamHistory().find((h) => h.isDailyLive);
    if (latest) {
      rows.push({
        rank: 0,
        name: profile?.name || 'You',
        college: profile?.institutionName || 'Your College',
        universityTrack: latest.track,
        score: latest.score,
        totalMarks: latest.totalQuestions,
        timeTakenSeconds: latest.timeTakenSeconds,
        xp: Math.round(latest.score * 220),
        isCurrentUser: true,
      });
    }
    return rows
      .sort((a, b) => b.score - a.score)
      .map((r, i) => ({ ...r, rank: i + 1 }));
  }, [profile]);

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.filterRow}>
          {['ALL', 'NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP'].map((u) => {
            const active = uniFilter === u;
            return (
              <TouchableOpacity
                key={u}
                onPress={() => setUniFilter(u)}
                style={[
                  styles.filterTab,
                  {
                    backgroundColor: active ? palette.text : palette.surface,
                    borderColor: active ? palette.text : palette.border,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.filterTabText,
                    { color: active ? palette.bg : palette.textMuted },
                  ]}
                >
                  {u}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      <EditorialCard highlighted>
        <DailyWindowStatusRow palette={palette} />

        <Text style={[styles.arenaTitle, { color: palette.text }]}>
          {track} Daily Ranked Sprint
        </Text>
        <Text style={{ color: palette.textMuted, fontSize: 13 }}>
          1,420 Candidates Today · +250 Streak XP · 1-Tap Answer Lock + Finger Telemetry
        </Text>

        <View style={styles.arenaStats}>
          <View style={[styles.arenaStatBox, { backgroundColor: palette.surfaceMuted }]}>
            <Text style={[styles.arenaStatVal, { color: palette.text }]}>25</Text>
            <Text style={[styles.arenaStatLbl, { color: palette.textMuted }]}>MCQs</Text>
          </View>
          <View style={[styles.arenaStatBox, { backgroundColor: palette.surfaceMuted }]}>
            <Text style={[styles.arenaStatVal, { color: palette.text }]}>25m</Text>
            <Text style={[styles.arenaStatLbl, { color: palette.textMuted }]}>Timer</Text>
          </View>
          <View style={[styles.arenaStatBox, { backgroundColor: palette.surfaceMuted }]}>
            <Text style={[styles.arenaStatVal, { color: palette.success }]}>0</Text>
            <Text style={[styles.arenaStatLbl, { color: palette.textMuted }]}>Neg</Text>
          </View>
        </View>

        <ScalePressable
          onPress={() =>
            navigate({
              name: 'liveExam',
              slug: `daily-${track.toLowerCase()}-live`,
              title: `${track} Daily Ranked Live Test`,
              durationMinutes: 25,
              negativeMark: 0,
            })
          }
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.btnText, { color: palette.primaryInk }]}>
            Attempt Daily Live Exam
          </Text>
        </ScalePressable>
      </EditorialCard>

      <EditorialCard style={styles.listCard}>
        <Text style={[styles.h2, { color: palette.text, paddingBottom: 4 }]}>
          National & Track Leaderboard
        </Text>
        {leaderboard.map((e, index) => (
          <HairlineRow
            key={`${e.name}-${e.rank}`}
            isLast={index === leaderboard.length - 1}
            highlightedBg={e.isCurrentUser ? palette.creamTint : undefined}
            left={
              <View style={styles.lbLead}>
                <Text style={[styles.lbRank, { color: palette.primary }]}>#{e.rank}</Text>
                <View style={{ flex: 1 }}>
                  <Text style={{ color: palette.text, fontWeight: '700', fontSize: 13.5 }}>
                    {e.name} {e.isCurrentUser ? '(You)' : ''}
                  </Text>
                  <Text style={{ color: palette.textMuted, fontSize: 12 }}>
                    {e.college} · {e.universityTrack}
                  </Text>
                </View>
              </View>
            }
            right={
              <Text style={[styles.lbScore, { color: palette.primary }]}>
                {e.score}/{e.totalMarks}
              </Text>
            }
          />
        ))}
      </EditorialCard>

      <EditorialCard style={styles.listCard}>
        <Text style={[styles.h2, { color: palette.text, paddingBottom: 4 }]}>
          Past Daily Drills
        </Text>
        {MODEL_TESTS_CATALOG.slice(0, 3).map((d, idx) => (
          <HairlineRow
            key={d.id}
            isLast={idx === 2}
            onPress={() =>
              navigate({
                name: 'liveExam',
                slug: d.slug,
                title: `${d.title} (Practice)`,
                durationMinutes: d.durationMinutes,
                negativeMark: 0,
                isPracticeMode: true,
              })
            }
            left={
              <View>
                <Text style={{ color: palette.text, fontWeight: '700', fontSize: 13.5 }}>
                  {d.title}
                </Text>
                <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                  {d.questionCount} Qs · {d.durationMinutes} min · 0 Neg
                </Text>
              </View>
            }
            right={
              <Text style={{ color: palette.primary, fontWeight: '700', fontSize: 12.5 }}>
                Practice →
              </Text>
            }
          />
        ))}
      </EditorialCard>
    </ScrollView>
  );
};

export const LiveModelTestScreen: React.FC<{
  slug: string;
  title: string;
  durationMinutes: number;
  negativeMark: number;
  isPracticeMode?: boolean;
  initialQuestions?: Question[];
}> = ({
  slug,
  title,
  durationMinutes,
  negativeMark,
  isPracticeMode = false,
  initialQuestions,
}) => {
  const { profile, palette, goBack, showToast } = useApp();
  const exam = useMemo(
    () =>
      buildExamDetails({
        slug,
        title,
        durationMinutes,
        negativeMark: 0,
        initialQuestions,
      }),
    [slug, title, durationMinutes, negativeMark, initialQuestions]
  );

  const persistedSession = useMemo(() => loadActiveExamSession(slug), [slug]);

  const [phase, setPhase] = useState<'mode' | 'test' | 'result'>(() =>
    persistedSession ? 'test' : 'mode'
  );
  const [mode, setMode] = useState<'inApp' | 'omrBubble'>(
    () => persistedSession?.mode ?? 'inApp'
  );
  const [viewStyle, setViewStyle] = useState<'focus' | 'sheet'>(
    () => persistedSession?.viewStyle ?? 'focus'
  );
  const [activeIdx, setActiveIdx] = useState<number>(
    () => persistedSession?.activeIdx ?? 0
  );
  const [sessionTiming, setSessionTiming] = useState<ExamSessionTiming>(() =>
    persistedSession?.sessionTiming ??
    createExamSessionTiming(exam.durationMinutes * 60)
  );
  const [answers, setAnswers] = useState<Record<string, string>>(
    () => persistedSession?.answers ?? {}
  );
  const [flaggedIds, setFlaggedIds] = useState<Record<string, boolean>>(
    () => persistedSession?.flaggedIds ?? {}
  );
  const [lockedTelemetry, setLockedTelemetry] = useState<
    Record<string, QuestionTimingTelemetry>
  >({});
  const [result, setResult] = useState<ExamSubmissionResult | null>(null);
  const [omrPreviewQ, setOmrPreviewQ] = useState<Question | null>(null);
  const [navModalOpen, setNavModalOpen] = useState(false);
  const [navFilter, setNavFilter] = useState<'all' | 'flagged' | 'unanswered'>('all');
  const [submitModalOpen, setSubmitModalOpen] = useState(false);
  const isOnline = useNetworkStatus();

  const focusQ = exam.questions[activeIdx] || exam.questions[0];

  // Start question telemetry clock whenever active question or exam view changes
  useEffect(() => {
    if (phase !== 'test') return;
    const screenSource = mode === 'omrBubble' ? 'omr_exam' : 'live_exam';
    if (mode === 'inApp' && viewStyle === 'focus' && focusQ) {
      startQuestionTelemetry({
        questionId: focusQ.id,
        questionText: focusQ.text,
        topicId: focusQ.topicId,
        subjectName: focusQ.subjectName,
        universityCode: focusQ.universityTags?.[0],
        sourceScreen: screenSource,
      });
    } else {
      for (const q of exam.questions) {
        if (!answers[q.id]) {
          startQuestionTelemetry({
            questionId: q.id,
            questionText: q.text,
            topicId: q.topicId,
            subjectName: q.subjectName,
            universityCode: q.universityTags?.[0],
            sourceScreen: screenSource,
          });
        }
      }
    }
  }, [phase, mode, viewStyle, focusQ?.id, exam.questions]);

  useEffect(() => {
    if (omrPreviewQ) {
      startQuestionTelemetry({
        questionId: omrPreviewQ.id,
        questionText: omrPreviewQ.text,
        topicId: omrPreviewQ.topicId,
        subjectName: omrPreviewQ.subjectName,
        universityCode: omrPreviewQ.universityTags?.[0],
        sourceScreen: 'omr_sheet',
      });
    }
  }, [omrPreviewQ?.id]);

  // Persist active exam state so backgrounding/tab eviction never resets exam time or answers
  useEffect(() => {
    if (phase === 'test') {
      saveActiveExamSession(slug, {
        mode,
        viewStyle,
        activeIdx,
        sessionTiming,
        answers,
        flaggedIds,
      });
    } else if (phase === 'result') {
      clearActiveExamSession(slug);
    }
  }, [phase, slug, mode, viewStyle, activeIdx, sessionTiming, answers, flaggedIds]);

  const handleSelectOption = useCallback(
    (questionId: string, optionId: string) => {
      if (answers[questionId]) {
        showToast('Answer permanently locked on first tap.');
        return;
      }
      const targetQuestion = exam.questions.find((q) => q.id === questionId);
      if (targetQuestion) {
        const telemetryEvent = lockQuestionAnswerTelemetry({
          question: targetQuestion,
          selectedOptionId: optionId,
          mode: mode === 'omrBubble' ? 'omr_exam' : 'live_exam',
        });
        setLockedTelemetry((prev) => ({
          ...prev,
          [questionId]: telemetryEvent,
        }));
      }
      setAnswers((prev) => {
        if (prev[questionId]) return prev;
        return { ...prev, [questionId]: optionId };
      });
    },
    [answers, exam.questions, mode, showToast]
  );

  const handleToggleFlag = useCallback((questionId: string) => {
    setFlaggedIds((prev) => ({
      ...prev,
      [questionId]: !prev[questionId],
    }));
  }, []);

  const handleModeChange = useCallback(
    (nextMode: 'inApp' | 'omrBubble') => {
      setMode((prevMode) => {
        if (prevMode === nextMode) return prevMode;
        const nextTotalSeconds =
          nextMode === 'omrBubble'
            ? (exam.durationMinutes + 15) * 60
            : exam.durationMinutes * 60;
        setSessionTiming((prevTiming) =>
          adjustExamSessionDuration(prevTiming, nextTotalSeconds)
        );
        return nextMode;
      });
    },
    [exam.durationMinutes]
  );

  const submitExam = useCallback(
    (forceExpired = false) => {
      const elapsedSeconds = forceExpired
        ? sessionTiming.totalSeconds
        : computeElapsedSeconds(
            sessionTiming.startedAtMs,
            sessionTiming.totalSeconds,
            Date.now()
          );
      clearActiveExamSession(slug);
      recordStudySessionComplete();
      const { result: res } = scoreAndPersistExam({
        exam,
        userAnswers: answers,
        timeTakenSeconds: elapsedSeconds,
        candidateName: profile?.name || 'Candidate',
        mode,
        isPractice: isPracticeMode,
      });
      setSubmitModalOpen(false);
      setNavModalOpen(false);
      setResult(res);
      setPhase('result');
    },
    [sessionTiming, slug, exam, answers, profile?.name, mode, isPracticeMode]
  );

  const handleTimerExpire = useCallback(() => {
    submitExam(true);
  }, [submitExam]);

  const handleOpenNavModal = useCallback(() => {
    setNavModalOpen(true);
  }, []);

  const progress = useMemo(
    () => summarizeExamProgress(exam.questions, answers, flaggedIds),
    [exam.questions, answers, flaggedIds]
  );

  const filteredNavIndices = useMemo(() => {
    if (navFilter === 'flagged') return progress.flaggedIndices;
    if (navFilter === 'unanswered') return progress.unansweredIndices;
    return exam.questions.map((_, i) => i);
  }, [navFilter, progress.flaggedIndices, progress.unansweredIndices, exam.questions]);

  const jumpToQuestion = useCallback(
    (idx: number) => {
      setNavModalOpen(false);
      if (mode === 'omrBubble') {
        const target = exam.questions[idx];
        if (target) setOmrPreviewQ(target);
        return;
      }
      setActiveIdx(idx);
      if (viewStyle === 'sheet') {
        setViewStyle('focus');
      }
    },
    [mode, exam.questions, viewStyle]
  );

  if (phase === 'mode') {
    return (
      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
      >
        <EditorialCard>
          <Text style={[styles.arenaTitle, { color: palette.text }]}>
            {exam.title}
          </Text>
          <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
            {exam.questionCount} MCQs · {exam.durationMinutes} min · Zero Negative Marking (0.00) · 1-Tap Answer Lock
          </Text>

          <TouchableOpacity
            onPress={() => {
              const totalSecs = exam.durationMinutes * 60;
              recordStudySessionStart();
              setMode('inApp');
              setSessionTiming(createExamSessionTiming(totalSecs));
              setActiveIdx(0);
              setPhase('test');
            }}
            accessibilityRole="button"
            accessibilityLabel="Start In-App Digital Mode"
            style={[
              styles.modeCard,
              {
                borderColor: palette.primary,
                backgroundColor: palette.creamTint,
              },
            ]}
          >
            <Devices size={22} color={palette.primary} weight="duotone" />
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={{ color: palette.text, fontWeight: '700', fontSize: 15 }}>
                In-App Digital Mode
              </Text>
              <Text style={{ color: palette.textMuted, fontSize: 12.5 }}>
                {exam.durationMinutes} min · Instant answer lock + finger timing telemetry
              </Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => {
              const totalSecs = (exam.durationMinutes + 15) * 60;
              recordStudySessionStart();
              setMode('omrBubble');
              setSessionTiming(createExamSessionTiming(totalSecs));
              setPhase('test');
            }}
            accessibilityRole="button"
            accessibilityLabel="Start Software OMR Bubble Sheet"
            style={[
              styles.modeCard,
              {
                borderColor: palette.borderStrong,
                backgroundColor: palette.surfaceMuted,
              },
            ]}
          >
            <FileText size={22} color={palette.secondary} weight="duotone" />
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={{ color: palette.text, fontWeight: '700', fontSize: 15 }}>
                Software OMR Bubble Sheet
              </Text>
              <Text style={{ color: palette.textMuted, fontSize: 12.5 }}>
                {exam.durationMinutes + 15} min (+15m bubble transfer · permanent ink shade)
              </Text>
            </View>
          </TouchableOpacity>
        </EditorialCard>
      </ScrollView>
    );
  }

  if (phase === 'result' && result) {
    const accuracy =
      exam.questionCount > 0
        ? Math.round((result.correctCount / exam.questionCount) * 100)
        : 0;
    return (
      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
      >
        <EditorialCard highlighted>
          <View style={styles.resultTop}>
            <View style={{ flex: 1, gap: 4 }}>
              <Text style={[styles.liveTag, { color: palette.success }]}>
                {result.isPractice ? 'Practice Complete' : `National Rank #${result.rank}`}
              </Text>
              <Text style={[styles.arenaTitle, { color: palette.text }]}>
                {result.score.toFixed(2)} / {result.totalMarks}
              </Text>
              <Text style={{ color: palette.textMuted, fontSize: 13 }}>
                Completed in {formatSecondsHMS(result.timeTakenSeconds)} · Zero Negative Penalty
              </Text>
            </View>
            <ProgressRing
              percent={accuracy}
              size={76}
              strokeWidth={7}
              color={palette.success}
              trackColor={palette.border}
              textColor={palette.text}
              labelColor={palette.textMuted}
              label="Acc"
            />
          </View>

          <View style={styles.arenaStats}>
            <View style={[styles.arenaStatBox, { backgroundColor: palette.successSoft }]}>
              <Text style={[styles.arenaStatVal, { color: palette.success }]}>
                {result.correctCount}
              </Text>
              <Text style={[styles.arenaStatLbl, { color: palette.success }]}>Right</Text>
            </View>
            <View style={[styles.arenaStatBox, { backgroundColor: palette.dangerSoft }]}>
              <Text style={[styles.arenaStatVal, { color: palette.danger }]}>
                {result.wrongCount}
              </Text>
              <Text style={[styles.arenaStatLbl, { color: palette.danger }]}>Wrong</Text>
            </View>
            <View style={[styles.arenaStatBox, { backgroundColor: palette.surfaceMuted }]}>
              <Text style={[styles.arenaStatVal, { color: palette.text }]}>
                {result.unansweredCount}
              </Text>
              <Text style={[styles.arenaStatLbl, { color: palette.textMuted }]}>
                Skipped
              </Text>
            </View>
          </View>

          <ScalePressable
            onPress={goBack}
            style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
          >
            <Text style={[styles.btnText, { color: palette.primaryInk }]}>
              Finish Review
            </Text>
          </ScalePressable>
        </EditorialCard>

        {exam.questions.map((q, idx) => {
          const picked = answers[q.id];
          const isRight = picked?.toUpperCase() === q.correctOptionId.toUpperCase();
          const wasFlagged = Boolean(flaggedIds[q.id]);
          const qTel = lockedTelemetry[q.id];
          return (
            <EditorialCard key={q.id}>
              <View style={styles.cardTopRow}>
                <View style={styles.stateInline}>
                  <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                    Q{idx + 1} · {q.subjectName}
                  </Text>
                  {qTel && (
                    <Text
                      style={{
                        fontFamily: TYPE_FONTS.mono,
                        fontSize: 10.5,
                        fontWeight: '700',
                        color:
                          qTel.behaviorClass === 'impulse_guess'
                            ? palette.danger
                            : palette.primary,
                      }}
                    >
                      · R {(qTel.readTimeMs / 1000).toFixed(1)}s / T {(qTel.thinkTimeMs / 1000).toFixed(1)}s
                    </Text>
                  )}
                  {wasFlagged && (
                    <View
                      style={[
                        styles.reviewFlagTag,
                        { backgroundColor: palette.warningSoft, borderColor: palette.amber },
                      ]}
                    >
                      <Flag size={11} color={palette.amber} weight="fill" />
                      <Text style={{ fontSize: 11, fontWeight: '700', color: palette.amber }}>
                        Flagged
                      </Text>
                    </View>
                  )}
                </View>
                <View style={styles.stateInline}>
                  {picked ? (
                    isRight ? (
                      <CheckCircle size={15} color={palette.success} weight="fill" />
                    ) : (
                      <XCircle size={15} color={palette.danger} weight="fill" />
                    )
                  ) : null}
                  <Text
                    style={{
                      fontSize: 12,
                      fontWeight: '700',
                      color: !picked
                        ? palette.textMuted
                        : isRight
                          ? palette.success
                          : palette.danger,
                    }}
                  >
                    {!picked
                      ? `Skipped (Ans: ${q.correctOptionId})`
                      : isRight
                        ? `Correct (${q.correctOptionId})`
                        : `Picked ${picked} · Ans ${q.correctOptionId}`}
                  </Text>
                </View>
              </View>
              <MathText
                text={q.text}
                style={{ color: palette.text, fontSize: 14.5, fontWeight: '700', lineHeight: 21 }}
              />
              <View
                style={[
                  styles.explainBox,
                  { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
                ]}
              >
                <MathText
                  text={q.explanation}
                  style={{ color: palette.textMuted, fontSize: 13, lineHeight: 19 }}
                />
              </View>
            </EditorialCard>
          );
        })}
      </ScrollView>
    );
  }

  const focusLocked = Boolean(focusQ && answers[focusQ.id]);
  const focusTelemetry = focusQ ? lockedTelemetry[focusQ.id] : undefined;

  return (
    <View style={styles.flexFull}>
      {/* Sticky Exam HUD preserving essential exam controls with isolated timer & progress */}
      <View
        style={[
          styles.hudBar,
          { backgroundColor: palette.surface, borderBottomColor: palette.border },
        ]}
      >
        <ExamCountdownTimer
          deadlineMs={sessionTiming.deadlineMs}
          onExpire={handleTimerExpire}
          palette={palette}
        />

        <View style={styles.hudActions}>
          <MemoHudNavigatorTrigger
            answeredCount={progress.answeredCount}
            totalCount={exam.questionCount}
            flaggedCount={progress.flaggedCount}
            onOpen={handleOpenNavModal}
            palette={palette}
          />

          {mode === 'inApp' && (
            <TouchableOpacity
              onPress={() => setViewStyle(viewStyle === 'focus' ? 'sheet' : 'focus')}
              accessibilityRole="button"
              accessibilityLabel="Switch focus or list view"
              style={[styles.viewToggle, { borderColor: palette.border }]}
            >
              <GridFour size={14} color={palette.text} weight="regular" />
              <Text style={{ color: palette.text, fontSize: 12, fontWeight: '700' }}>
                {viewStyle === 'focus' ? 'List' : 'Focus'}
              </Text>
            </TouchableOpacity>
          )}

          <TouchableOpacity
            onPress={() => setSubmitModalOpen(true)}
            accessibilityRole="button"
            accessibilityLabel="Submit examination"
            style={[styles.submitBtn, { backgroundColor: palette.success }]}
          >
            <Text style={{ color: '#FFFFFF', fontWeight: '700', fontSize: 12.5 }}>
              Submit
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <MemoExamProgressBar
        answeredCount={progress.answeredCount}
        totalCount={exam.questionCount}
        fillColor={palette.primary}
        trackColor={palette.surfaceMuted}
      />

      {/* Relevant Network Status Warning (only surfaced when offline during live Focus session) */}
      {!isOnline && (
        <View
          accessibilityRole="alert"
          style={[
            styles.networkAlertBar,
            {
              backgroundColor: palette.warningSoft,
              borderBottomColor: palette.amber,
            },
          ]}
        >
          <WifiSlash size={15} color={palette.amber} weight="bold" />
          <Text style={[styles.networkAlertText, { color: palette.text }]}>
            Offline — answers saved locally. Reconnect before final ranked submission.
          </Text>
        </View>
      )}

      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
        onScrollBeginDrag={(e) => {
          if (focusQ) {
            recordQuestionFingerActivity(focusQ.id, {
              kind: 'scroll',
              ...extractTouchPoint(e),
            });
          }
        }}
      >
        {/* Mode Switcher during active test */}
        <SegmentedControl
          value={mode}
          onChange={handleModeChange}
          options={[
            { id: 'inApp', label: 'Question Cards' },
            { id: 'omrBubble', label: 'Software OMR Sheet' },
          ]}
        />

        {mode === 'omrBubble' ? (
          <EditorialCard style={styles.listCard}>
            {exam.questions.map((q, idx) => (
              <MemoOmrQuestionRow
                key={q.id}
                question={q}
                index={idx}
                isLast={idx === exam.questions.length - 1}
                selectedOption={answers[q.id]}
                isFlagged={Boolean(flaggedIds[q.id])}
                telemetry={lockedTelemetry[q.id]}
                onSelectOption={handleSelectOption}
                onToggleFlag={handleToggleFlag}
                onPreviewQuestion={setOmrPreviewQ}
                palette={palette}
              />
            ))}
          </EditorialCard>
        ) : viewStyle === 'focus' && focusQ ? (
          <>
            <ScrollView horizontal showsHorizontalScrollIndicator={false}>
              <View style={styles.navStrip}>
                {exam.questions.map((q, idx) => (
                  <MemoNavBubble
                    key={q.id}
                    index={idx}
                    isCurrent={idx === activeIdx}
                    isAnswered={Boolean(answers[q.id])}
                    isFlagged={Boolean(flaggedIds[q.id])}
                    onSelectIndex={setActiveIdx}
                    palette={palette}
                  />
                ))}
              </View>
            </ScrollView>

            <EditorialCard>
              <View style={styles.cardTopRow}>
                <Text style={[styles.monoSmall, { color: palette.textMuted, flex: 1 }]}>
                  Question {activeIdx + 1} of {exam.questionCount} · {focusQ.subjectName}
                </Text>
                <TouchableOpacity
                  onPress={() => handleToggleFlag(focusQ.id)}
                  accessibilityRole="button"
                  accessibilityLabel={`${flaggedIds[focusQ.id] ? 'Unflag' : 'Flag'} question ${activeIdx + 1}`}
                  accessibilityState={{ selected: Boolean(flaggedIds[focusQ.id]) }}
                  style={[
                    styles.flagToggleBtn,
                    {
                      borderColor: flaggedIds[focusQ.id]
                        ? palette.amber
                        : palette.borderStrong,
                      backgroundColor: flaggedIds[focusQ.id]
                        ? palette.warningSoft
                        : palette.surfaceMuted,
                    },
                  ]}
                >
                  <Flag
                    size={14}
                    color={flaggedIds[focusQ.id] ? palette.amber : palette.textMuted}
                    weight={flaggedIds[focusQ.id] ? 'fill' : 'regular'}
                  />
                  <Text
                    style={{
                      fontSize: 12,
                      fontWeight: '700',
                      color: flaggedIds[focusQ.id] ? palette.amber : palette.textMuted,
                    }}
                  >
                    {flaggedIds[focusQ.id] ? 'Flagged' : 'Flag'}
                  </Text>
                </TouchableOpacity>
              </View>

              {focusLocked && (
                <View
                  style={[
                    styles.syncNotice,
                    {
                      backgroundColor:
                        focusTelemetry?.behaviorClass === 'impulse_guess'
                          ? palette.dangerSoft
                          : palette.creamTint,
                      borderColor:
                        focusTelemetry?.behaviorClass === 'impulse_guess'
                          ? palette.danger
                          : palette.primary,
                    },
                  ]}
                >
                  <LockKey
                    size={15}
                    color={
                      focusTelemetry?.behaviorClass === 'impulse_guess'
                        ? palette.danger
                        : palette.primary
                    }
                    weight="fill"
                  />
                  <Text
                    style={{
                      fontFamily: TYPE_FONTS.mono,
                      fontSize: 11.5,
                      fontWeight: '700',
                      color: palette.text,
                      flex: 1,
                    }}
                  >
                    {focusTelemetry
                      ? `ANSWER LOCKED (${answers[focusQ.id]}) · Read ${(focusTelemetry.readTimeMs / 1000).toFixed(1)}s · Think ${(focusTelemetry.thinkTimeMs / 1000).toFixed(1)}s · ${focusTelemetry.behaviorClass === 'impulse_guess' ? 'IMPULSE LOCK (<2.5s)' : 'DELIBERATE'}`
                      : `ANSWER LOCKED (${answers[focusQ.id]}) · Permanent 1-Tap Commit`}
                  </Text>
                </View>
              )}

              <MathText
                text={focusQ.text}
                style={{ color: palette.text, fontSize: 16, fontWeight: '700', lineHeight: 24 }}
              />

              <View style={{ gap: 10 }}>
                {focusQ.options.map((opt) => {
                  const chosen = answers[focusQ.id] === opt.id;
                  return (
                    <TouchableOpacity
                      key={opt.id}
                      disabled={focusLocked && !chosen}
                      onPressIn={(e) =>
                        recordQuestionFingerActivity(focusQ.id, {
                          kind: 'press_in',
                          optionId: opt.id,
                          ...extractTouchPoint(e),
                        })
                      }
                      onPress={() => handleSelectOption(focusQ.id, opt.id)}
                      style={[
                        styles.optBtn,
                        {
                          borderColor: chosen ? palette.primary : palette.border,
                          backgroundColor: chosen ? palette.creamTint : palette.surface,
                          opacity: focusLocked && !chosen ? 0.5 : 1,
                        },
                      ]}
                    >
                      <View
                        style={[
                          styles.optLetterBox,
                          {
                            backgroundColor: chosen
                              ? palette.primary
                              : palette.surfaceMuted,
                          },
                        ]}
                      >
                        <Text
                          style={{
                            fontFamily: TYPE_FONTS.mono,
                            fontWeight: '700',
                            color: chosen ? palette.primaryInk : palette.text,
                            fontSize: 13,
                          }}
                        >
                          {opt.id}
                        </Text>
                      </View>
                      <MathText
                        text={opt.text}
                        style={{ color: palette.text, fontSize: 14, flex: 1 }}
                      />
                      {chosen && (
                        <LockKey size={16} color={palette.primary} weight="fill" />
                      )}
                    </TouchableOpacity>
                  );
                })}
              </View>

              <View style={styles.focusFooter}>
                <TouchableOpacity
                  disabled={activeIdx === 0}
                  onPress={() => setActiveIdx((i) => Math.max(0, i - 1))}
                  style={[
                    styles.navStepBtn,
                    { borderColor: palette.borderStrong, opacity: activeIdx === 0 ? 0.4 : 1 },
                  ]}
                >
                  <Text style={{ color: palette.text, fontWeight: '700' }}>← Previous</Text>
                </TouchableOpacity>
                <ScalePressable
                  disabled={activeIdx >= exam.questions.length - 1}
                  onPress={() =>
                    setActiveIdx((i) => Math.min(exam.questions.length - 1, i + 1))
                  }
                  containerStyle={{ flex: 1 }}
                  style={[
                    styles.navStepBtn,
                    {
                      backgroundColor: PREP404_COLORS.plum,
                      borderColor: PREP404_COLORS.plum,
                    },
                  ]}
                >
                  <Text style={{ color: '#FFFFFF', fontWeight: '700' }}>Next →</Text>
                </ScalePressable>
              </View>
            </EditorialCard>
          </>
        ) : (
          exam.questions.map((q, idx) => (
            <MemoListQuestionCard
              key={q.id}
              question={q}
              index={idx}
              selectedOption={answers[q.id]}
              isFlagged={Boolean(flaggedIds[q.id])}
              telemetry={lockedTelemetry[q.id]}
              onSelectOption={handleSelectOption}
              onToggleFlag={handleToggleFlag}
              palette={palette}
            />
          ))
        )}
      </ScrollView>

      {/* OMR Question Booklet Preview Modal */}
      <BottomSheetModal
        visible={Boolean(omrPreviewQ)}
        onClose={() => setOmrPreviewQ(null)}
        title="Question Booklet Preview"
      >
        {omrPreviewQ && (
          <>
            <View style={styles.cardTopRow}>
              <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                {omrPreviewQ.subjectName}
              </Text>
              <TouchableOpacity
                onPress={() => handleToggleFlag(omrPreviewQ.id)}
                accessibilityRole="button"
                accessibilityLabel={flaggedIds[omrPreviewQ.id] ? 'Unflag question' : 'Flag question'}
                style={[
                  styles.flagToggleBtn,
                  {
                    borderColor: flaggedIds[omrPreviewQ.id]
                      ? palette.amber
                      : palette.borderStrong,
                    backgroundColor: flaggedIds[omrPreviewQ.id]
                      ? palette.warningSoft
                      : palette.surfaceMuted,
                  },
                ]}
              >
                <Flag
                  size={14}
                  color={flaggedIds[omrPreviewQ.id] ? palette.amber : palette.textMuted}
                  weight={flaggedIds[omrPreviewQ.id] ? 'fill' : 'regular'}
                />
                <Text
                  style={{
                    fontSize: 12,
                    fontWeight: '700',
                    color: flaggedIds[omrPreviewQ.id] ? palette.amber : palette.textMuted,
                  }}
                >
                  {flaggedIds[omrPreviewQ.id] ? 'Flagged' : 'Flag'}
                </Text>
              </TouchableOpacity>
            </View>
            <MathText
              text={omrPreviewQ.text}
              style={{ color: palette.text, fontSize: 15.5, fontWeight: '700', lineHeight: 22 }}
            />
            {omrPreviewQ.options.map((opt) => {
              const omrLocked = Boolean(answers[omrPreviewQ.id]);
              const omrChosen = answers[omrPreviewQ.id] === opt.id;
              return (
                <TouchableOpacity
                  key={opt.id}
                  disabled={omrLocked && !omrChosen}
                  onPressIn={(e) =>
                    recordQuestionFingerActivity(omrPreviewQ.id, {
                      kind: 'press_in',
                      optionId: opt.id,
                      ...extractTouchPoint(e),
                    })
                  }
                  onPress={() => {
                    handleSelectOption(omrPreviewQ.id, opt.id);
                    setOmrPreviewQ(null);
                  }}
                  style={[
                    styles.optBtn,
                    {
                      borderColor: omrChosen ? palette.primary : palette.border,
                      backgroundColor: omrChosen ? palette.creamTint : palette.surface,
                      opacity: omrLocked && !omrChosen ? 0.5 : 1,
                    },
                  ]}
                >
                  <Text
                    style={{
                      fontFamily: TYPE_FONTS.mono,
                      fontWeight: '700',
                      color: palette.primary,
                    }}
                  >
                    {opt.id}.
                  </Text>
                  <MathText
                    text={opt.text}
                    style={{ color: palette.text, fontSize: 14, flex: 1 }}
                  />
                  {omrChosen && (
                    <LockKey size={15} color={palette.primary} weight="fill" />
                  )}
                </TouchableOpacity>
              );
            })}
          </>
        )}
      </BottomSheetModal>

      {/* Unified Question Navigator Sheet */}
      <BottomSheetModal
        visible={navModalOpen}
        onClose={() => setNavModalOpen(false)}
        title="Question Navigator"
        subtitle={`${progress.answeredCount} answered · ${progress.flaggedCount} flagged · ${progress.unansweredCount} remaining`}
      >
        <SegmentedControl
          value={navFilter}
          onChange={setNavFilter}
          options={[
            { id: 'all', label: `All (${exam.questionCount})` },
            { id: 'flagged', label: `Flagged (${progress.flaggedCount})` },
            { id: 'unanswered', label: `Skipped (${progress.unansweredCount})` },
          ]}
        />

        <View style={styles.legendRow}>
          <View style={styles.legendItem}>
            <View style={[styles.legendSwatch, { backgroundColor: palette.text }]} />
            <Text style={[styles.legendText, { color: palette.textMuted }]}>Current</Text>
          </View>
          <View style={styles.legendItem}>
            <View
              style={[
                styles.legendSwatch,
                { backgroundColor: palette.creamTint, borderWidth: 1, borderColor: palette.primary },
              ]}
            />
            <Text style={[styles.legendText, { color: palette.textMuted }]}>Answered</Text>
          </View>
          <View style={styles.legendItem}>
            <View
              style={[
                styles.legendSwatch,
                { backgroundColor: palette.warningSoft, borderWidth: 1, borderColor: palette.amber },
              ]}
            />
            <Text style={[styles.legendText, { color: palette.textMuted }]}>Flagged</Text>
          </View>
        </View>

        {filteredNavIndices.length === 0 ? (
          <Text style={{ color: palette.textMuted, fontSize: 13, textAlign: 'center', paddingVertical: 14 }}>
            No questions match this filter.
          </Text>
        ) : (
          <View style={styles.navGrid}>
            {filteredNavIndices.map((idx) => {
              const q = exam.questions[idx];
              const isCur = idx === activeIdx && mode === 'inApp';
              const isAnswered = Boolean(answers[q.id]);
              const isFlagged = Boolean(flaggedIds[q.id]);
              return (
                <TouchableOpacity
                  key={q.id}
                  onPress={() => jumpToQuestion(idx)}
                  accessibilityRole="button"
                  accessibilityLabel={`Jump to question ${idx + 1}${isFlagged ? ', flagged' : ''}`}
                  style={[
                    styles.navGridTile,
                    {
                      backgroundColor: isCur
                        ? palette.text
                        : isFlagged
                          ? palette.warningSoft
                          : isAnswered
                            ? palette.creamTint
                            : palette.surfaceMuted,
                      borderColor: isCur
                        ? palette.text
                        : isFlagged
                          ? palette.amber
                          : isAnswered
                            ? palette.primary
                            : palette.borderStrong,
                    },
                  ]}
                >
                  <Text
                    style={{
                      fontFamily: TYPE_FONTS.mono,
                      fontWeight: '700',
                      fontSize: 13,
                      color: isCur
                        ? palette.bg
                        : isFlagged
                          ? palette.amber
                          : isAnswered
                            ? palette.primary
                            : palette.text,
                    }}
                  >
                    {idx + 1}
                  </Text>
                  {isFlagged && (
                    <View
                      style={[styles.navFlagDot, { backgroundColor: palette.amber }]}
                    />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </BottomSheetModal>

      {/* Safe Submit Examination Confirmation Sheet */}
      <BottomSheetModal
        visible={submitModalOpen}
        onClose={() => setSubmitModalOpen(false)}
        title="Submit Examination?"
      >
        {submitModalOpen && (
          <SubmitModalRemainingBanner
            deadlineMs={sessionTiming.deadlineMs}
            palette={palette}
          />
        )}

        <View style={styles.arenaStats}>
          <View style={[styles.arenaStatBox, { backgroundColor: palette.creamTint }]}>
            <Text style={[styles.arenaStatVal, { color: palette.primary }]}>
              {progress.answeredCount}
            </Text>
            <Text style={[styles.arenaStatLbl, { color: palette.text }]}>Answered</Text>
          </View>
          <View
            style={[
              styles.arenaStatBox,
              {
                backgroundColor:
                  progress.flaggedCount > 0 ? palette.warningSoft : palette.surfaceMuted,
              },
            ]}
          >
            <Text
              style={[
                styles.arenaStatVal,
                { color: progress.flaggedCount > 0 ? palette.amber : palette.text },
              ]}
            >
              {progress.flaggedCount}
            </Text>
            <Text
              style={[
                styles.arenaStatLbl,
                { color: progress.flaggedCount > 0 ? palette.amber : palette.textMuted },
              ]}
            >
              Flagged
            </Text>
          </View>
          <View style={[styles.arenaStatBox, { backgroundColor: palette.surfaceMuted }]}>
            <Text style={[styles.arenaStatVal, { color: palette.text }]}>
              {progress.unansweredCount}
            </Text>
            <Text style={[styles.arenaStatLbl, { color: palette.textMuted }]}>
              Unanswered
            </Text>
          </View>
        </View>

        {!isPracticeMode && (
          <View
            style={[
              styles.syncNotice,
              {
                backgroundColor: isOnline ? palette.successSoft : palette.warningSoft,
                borderColor: isOnline ? palette.success : palette.amber,
              },
            ]}
          >
            {isOnline ? (
              <WifiHigh size={15} color={palette.success} weight="bold" />
            ) : (
              <WifiSlash size={15} color={palette.amber} weight="bold" />
            )}
            <Text style={{ color: palette.text, fontSize: 12.5, fontWeight: '600', flex: 1 }}>
              {isOnline
                ? 'Online — ranked leaderboard submission ready'
                : 'Offline — score will save locally until reconnected'}
            </Text>
          </View>
        )}

        {progress.flaggedCount > 0 && (
          <TouchableOpacity
            onPress={() => {
              setSubmitModalOpen(false);
              jumpToQuestion(progress.flaggedIndices[0]);
            }}
            accessibilityRole="button"
            accessibilityLabel="Review flagged questions"
            style={[
              styles.reviewFlagBtn,
              { borderColor: palette.amber, backgroundColor: palette.warningSoft },
            ]}
          >
            <Flag size={15} color={palette.amber} weight="fill" />
            <Text style={{ color: palette.amber, fontWeight: '700', fontSize: 13 }}>
              Review {progress.flaggedCount} Flagged Question{progress.flaggedCount > 1 ? 's' : ''}
            </Text>
          </TouchableOpacity>
        )}

        <View style={styles.focusFooter}>
          <TouchableOpacity
            onPress={() => setSubmitModalOpen(false)}
            accessibilityRole="button"
            accessibilityLabel="Return to exam"
            style={[styles.navStepBtn, { borderColor: palette.borderStrong }]}
          >
            <Text style={{ color: palette.text, fontWeight: '700' }}>Keep Reviewing</Text>
          </TouchableOpacity>
          <ScalePressable
            onPress={() => submitExam(false)}
            accessibilityLabel="Confirm submit examination"
            containerStyle={{ flex: 1 }}
            style={[
              styles.navStepBtn,
              { backgroundColor: palette.success, borderColor: palette.success },
            ]}
          >
            <Text style={{ color: '#FFFFFF', fontWeight: '700' }}>Confirm Submit</Text>
          </ScalePressable>
        </View>
      </BottomSheetModal>
    </View>
  );
};

const styles = StyleSheet.create({
  flexFull: { flex: 1 },
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  filterRow: { flexDirection: 'row', gap: 8 },
  filterTab: {
    paddingHorizontal: 14,
    minHeight: 38,
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: 'center',
  },
  filterTabText: { fontSize: 12.5, fontWeight: '700' },
  cardTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  liveTag: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  monoMetric: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 13,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  monoSmall: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  arenaTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 20,
    fontWeight: '800',
  },
  arenaStats: { flexDirection: 'row', gap: 8 },
  arenaStatBox: {
    flex: 1,
    borderRadius: 12,
    paddingVertical: 10,
    alignItems: 'center',
    gap: 2,
  },
  arenaStatVal: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 17,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  arenaStatLbl: { fontSize: 11.5, fontWeight: '600' },
  primaryBtn: {
    borderRadius: RADII.md,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  btnText: { fontFamily: TYPE_FONTS.display, fontWeight: '700', fontSize: 14 },
  listCard: { paddingVertical: 8 },
  h2: { fontFamily: TYPE_FONTS.display, fontSize: 16, fontWeight: '700' },
  lbLead: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  lbRank: {
    fontFamily: TYPE_FONTS.mono,
    width: 32,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  lbScore: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 13.5,
    fontVariant: ['tabular-nums'],
  },
  modeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    borderWidth: 1.5,
    borderRadius: RADII.lg,
    padding: 16,
    minHeight: 68,
  },
  resultTop: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  stateInline: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  explainBox: { padding: 14, borderRadius: 12, borderWidth: 1 },
  hudBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 14,
    height: 54,
    borderBottomWidth: 1,
    gap: 8,
  },
  hudActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  timerRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  hudTimer: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 15,
    fontVariant: ['tabular-nums'],
  },
  hudCount: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  hudFlagInline: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    marginLeft: 2,
  },
  hudFlagCount: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  viewToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    borderWidth: 1,
    borderRadius: 9,
    paddingHorizontal: 10,
    minHeight: 38,
  },
  submitBtn: {
    paddingHorizontal: 14,
    minHeight: 38,
    borderRadius: 10,
    justifyContent: 'center',
  },
  progressTrack: { height: 4, width: '100%' },
  progressFill: { height: '100%' },
  networkAlertBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    paddingVertical: 9,
    borderBottomWidth: 1,
  },
  networkAlertText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '600',
    flex: 1,
  },
  navStrip: { flexDirection: 'row', gap: 8 },
  navBubble: {
    width: 40,
    height: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  navFlagDot: {
    position: 'absolute',
    top: 3,
    right: 3,
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  flagToggleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    borderWidth: 1,
    borderRadius: 9,
    paddingHorizontal: 10,
    minHeight: 36,
  },
  flagIconBtn: {
    width: 34,
    height: 34,
    borderRadius: 9,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  reviewFlagTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  omrQTrigger: { flexDirection: 'row', alignItems: 'center', gap: 6, minHeight: 40 },
  bubble: {
    width: 38,
    height: 38,
    borderRadius: 19,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1.5,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    minHeight: 54,
  },
  optLetterBox: {
    width: 30,
    height: 30,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
  },
  focusFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
    marginTop: 4,
  },
  navStepBtn: {
    flex: 1,
    borderWidth: 1,
    borderRadius: RADII.md,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
  },
  legendRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 14,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  legendSwatch: {
    width: 12,
    height: 12,
    borderRadius: 3,
  },
  legendText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    fontWeight: '600',
  },
  navGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  navGridTile: {
    width: 44,
    height: 44,
    borderRadius: 10,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  syncNotice: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  reviewFlagBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderWidth: 1,
    borderRadius: RADII.md,
    minHeight: 44,
    paddingHorizontal: 14,
  },
});

import React, { useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  BookmarkSimple,
  CheckCircle,
  Flag,
  Lightbulb,
  LockKey,
  Robot,
  XCircle,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { QUESTION_BANK } from '../data/questionBank';
import {
  createInitialFSRSState,
  FSRSRating,
  reviewFSRSCard,
} from '../algorithms/fsrs';
import { storageService } from '../services/storageService';
import { extractTouchPoint } from '../services/dataLoggingService';
import {
  lockQuestionAnswerTelemetry,
  recordQuestionFingerActivity,
  startQuestionTelemetry,
} from '../services/telemetryService';
import { QuestionTimingTelemetry } from '../types';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import { MathText } from '../components/MathText';
import {
  BottomSheetModal,
  EditorialCard,
  ScalePressable,
} from '../components/DesignPrimitives';

interface PracticeScreenProps {
  initialSubjectId?: string;
  initialTopicId?: string;
  title?: string;
}

const FILTERS = [
  { id: 'all', label: 'All Topics' },
  { id: 'bookmarked', label: 'Saved' },
  { id: 'higher_math', label: 'Higher Math' },
  { id: 'quant_math', label: 'Quant' },
  { id: 'physics', label: 'Physics' },
  { id: 'chemistry', label: 'Chemistry' },
  { id: 'biology', label: 'Biology' },
  { id: 'english', label: 'English' },
];

export const PracticeScreen: React.FC<PracticeScreenProps> = ({
  initialSubjectId = 'all',
  initialTopicId,
  title,
}) => {
  const { palette, showToast, navigate } = useApp();
  const [filter, setFilter] = useState(
    FILTERS.some((f) => f.id === initialSubjectId) ? initialSubjectId : 'all'
  );
  const [topicFilter, setTopicFilter] = useState<string | undefined>(initialTopicId);
  const [idx, setIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [telemetryByQ, setTelemetryByQ] = useState<
    Record<string, QuestionTimingTelemetry>
  >({});
  const [, setQuestionOpenedAtMs] = useState<number>(() => Date.now());
  const [bookmarks, setBookmarks] = useState(() => storageService.getBookmarks());
  const [fsrsCards, setFsrsCards] = useState(() => storageService.getFsrsCards());

  const [hintOpen, setHintOpen] = useState(false);
  const [hintStep, setHintStep] = useState(0);
  const [reportOpen, setReportOpen] = useState(false);
  const [reportReason, setReportReason] = useState('Wrong Answer Key');

  const questions = useMemo(() => {
    if (topicFilter) {
      const byTopic = QUESTION_BANK.filter((q) => q.topicId === topicFilter);
      if (byTopic.length > 0) return byTopic;
    }
    if (filter === 'bookmarked') {
      return QUESTION_BANK.filter((q) => bookmarks.includes(q.id));
    }
    if (filter === 'all') return QUESTION_BANK;
    return QUESTION_BANK.filter(
      (q) =>
        q.subjectId === filter ||
        q.subjectName.toLowerCase().includes(filter.replace('_', ' '))
    );
  }, [filter, topicFilter, bookmarks]);

  const activeQ = questions[idx] || questions[0];
  const pick = activeQ ? answers[activeQ.id] : undefined;
  const activeTelemetry = activeQ ? telemetryByQ[activeQ.id] : undefined;

  useEffect(() => {
    if (activeQ && !answers[activeQ.id]) {
      startQuestionTelemetry({
        questionId: activeQ.id,
        questionText: activeQ.text,
        topicId: activeQ.topicId,
        subjectName: activeQ.subjectName,
        universityCode: activeQ.universityTags?.[0],
        sourceScreen: 'practice',
      });
    }
  }, [activeQ?.id]);

  const handleSelectOption = (optionId: string) => {
    if (!activeQ) return;
    if (answers[activeQ.id]) {
      showToast('Answer permanently locked on first tap.');
      return;
    }
    const isCorrect = optionId.toUpperCase() === activeQ.correctOptionId.toUpperCase();
    const telEvent = lockQuestionAnswerTelemetry({
      question: activeQ,
      selectedOptionId: optionId,
      mode: 'practice',
    });
    setTelemetryByQ((prev) => ({ ...prev, [activeQ.id]: telEvent }));
    const elapsedSec = Math.min(
      140,
      Math.max(1, Math.round(telEvent.totalTimeMs / 1000))
    );
    storageService.addTopicAttempt({
      id: `att_prac_${Date.now()}`,
      questionId: activeQ.id,
      subjectId: activeQ.subjectId,
      topicId: activeQ.topicId || 'calculus_limits',
      selectedOptionId: optionId,
      correctOptionId: activeQ.correctOptionId,
      isCorrect,
      timeSpentSeconds: elapsedSec,
      negativePenalty: 0,
      createdAt: new Date().toISOString(),
    });
    setAnswers((p) => ({ ...p, [activeQ.id]: optionId }));
  };

  const rateCard = (rating: FSRSRating) => {
    if (!activeQ) return;
    const prev = fsrsCards[activeQ.id] || createInitialFSRSState();
    const { state, intervalDays } = reviewFSRSCard(prev, rating);
    storageService.saveFsrsCard(activeQ.id, state);
    setFsrsCards(storageService.getFsrsCards());
    showToast(`FSRS scheduled: next review in ${intervalDays}d`);
    if (idx < questions.length - 1) {
      setIdx((i) => i + 1);
      setQuestionOpenedAtMs(Date.now());
    }
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
      onScrollBeginDrag={(e) => {
        if (activeQ) {
          recordQuestionFingerActivity(activeQ.id, {
            kind: 'scroll',
            ...extractTouchPoint(e),
          });
        }
      }}
    >
      {/* Header Progress */}
      <View style={styles.rowBetween}>
        <Text style={[styles.h1, { color: palette.text, flex: 1 }]} numberOfLines={1}>
          {title || 'Adaptive FSRS Practice'}
        </Text>
        {questions.length > 0 && (
          <Text style={[styles.counter, { color: palette.primary }]}>
            {idx + 1} / {questions.length}
          </Text>
        )}
      </View>

      {questions.length > 0 && (
        <View style={[styles.progressTrack, { backgroundColor: palette.surfaceMuted }]}>
          <View
            style={[
              styles.progressFill,
              {
                width: `${((idx + 1) / questions.length) * 100}%`,
                backgroundColor: palette.primary,
              },
            ]}
          />
        </View>
      )}

      {/* Topic Filter Strip */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.filterRow}>
          {FILTERS.map((f) => {
            const active = filter === f.id && !topicFilter;
            return (
              <TouchableOpacity
                key={f.id}
                onPress={() => {
                  setTopicFilter(undefined);
                  setFilter(f.id);
                  setIdx(0);
                  setQuestionOpenedAtMs(Date.now());
                }}
                style={[
                  styles.filterTab,
                  {
                    backgroundColor: active ? palette.text : palette.surface,
                    borderColor: active ? palette.text : palette.border,
                  },
                ]}
              >
                <Text
                  style={{
                    color: active ? palette.bg : palette.textMuted,
                    fontSize: 12.5,
                    fontWeight: '700',
                  }}
                >
                  {f.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      {!activeQ ? (
        <EditorialCard>
          <Text style={{ color: palette.textMuted, textAlign: 'center', paddingVertical: 20 }}>
            No questions match this filter yet. Bookmark cards to build a revision deck.
          </Text>
        </EditorialCard>
      ) : (
        <EditorialCard>
          <View style={styles.rowBetween}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              {activeQ.subjectName} · {activeQ.topicName}
            </Text>
            <View style={styles.toolActions}>
              <TouchableOpacity
                onPress={() =>
                  navigate({
                    name: 'aiTutor',
                    questionId: activeQ.id,
                    topicId: activeQ.topicId,
                    subjectId: activeQ.subjectId,
                  })
                }
                accessibilityRole="button"
                accessibilityLabel="Open AETHER AI Engine"
                style={[styles.iconBox, { backgroundColor: palette.creamTint }]}
              >
                <Robot size={17} color={palette.primary} weight="duotone" />
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => {
                  setHintStep(0);
                  setHintOpen(true);
                }}
                accessibilityRole="button"
                accessibilityLabel="Show AETHER AI Step"
                style={[styles.iconBox, { backgroundColor: palette.warningSoft }]}
              >
                <Lightbulb size={17} color={palette.amber} weight="duotone" />
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => {
                  const next = storageService.toggleBookmark(activeQ.id);
                  setBookmarks(next);
                  showToast(next.includes(activeQ.id) ? 'Saved to bookmarks' : 'Removed');
                }}
                accessibilityRole="button"
                accessibilityLabel="Bookmark question"
                style={[styles.iconBox, { backgroundColor: palette.surfaceMuted }]}
              >
                <BookmarkSimple
                  size={17}
                  color={
                    bookmarks.includes(activeQ.id)
                      ? palette.primary
                      : palette.textMuted
                  }
                  weight={bookmarks.includes(activeQ.id) ? 'fill' : 'regular'}
                />
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => setReportOpen(true)}
                accessibilityRole="button"
                accessibilityLabel="Report question issue"
                style={[styles.iconBox, { backgroundColor: palette.surfaceMuted }]}
              >
                <Flag size={17} color={palette.textMuted} weight="regular" />
              </TouchableOpacity>
            </View>
          </View>

          {activeQ.passage && (
            <View
              style={[
                styles.passageBox,
                { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
              ]}
            >
              <MathText
                text={activeQ.passage}
                style={{ color: palette.text, fontSize: 13.5, lineHeight: 20 }}
              />
            </View>
          )}

          <MathText
            text={activeQ.text}
            style={{ color: palette.text, fontSize: 16, fontWeight: '700', lineHeight: 24 }}
          />

          {pick && (
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 6,
                paddingHorizontal: 10,
                paddingVertical: 7,
                borderRadius: 9,
                borderWidth: 1,
                backgroundColor:
                  activeTelemetry?.behaviorClass === 'impulse_guess'
                    ? palette.dangerSoft
                    : palette.creamTint,
                borderColor:
                  activeTelemetry?.behaviorClass === 'impulse_guess'
                    ? palette.danger
                    : palette.primary,
              }}
            >
              <LockKey
                size={14}
                color={
                  activeTelemetry?.behaviorClass === 'impulse_guess'
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
                {activeTelemetry
                  ? `LOCKED (${pick}) · Read ${(activeTelemetry.readTimeMs / 1000).toFixed(1)}s · Think ${(activeTelemetry.thinkTimeMs / 1000).toFixed(1)}s · ${activeTelemetry.behaviorClass === 'impulse_guess' ? 'IMPULSE LOCK (<2.5s)' : 'DELIBERATE'}`
                  : `LOCKED (${pick}) · Permanent 1-Tap Answer Commit`}
              </Text>
            </View>
          )}

          <View style={styles.optList}>
            {activeQ.options.map((opt) => {
              const selected = pick === opt.id;
              const isCorrect =
                opt.id.toUpperCase() === activeQ.correctOptionId.toUpperCase();
              let borderColor = palette.border;
              let bgColor = palette.surface;
              if (pick) {
                if (isCorrect) {
                  borderColor = palette.success;
                  bgColor = palette.successSoft;
                } else if (selected) {
                  borderColor = palette.danger;
                  bgColor = palette.dangerSoft;
                }
              }
              return (
                <TouchableOpacity
                  key={opt.id}
                  disabled={Boolean(pick)}
                  onPressIn={(e) =>
                    recordQuestionFingerActivity(activeQ.id, {
                      kind: 'press_in',
                      optionId: opt.id,
                      ...extractTouchPoint(e),
                    })
                  }
                  onPress={() => handleSelectOption(opt.id)}
                  accessibilityRole="button"
                  accessibilityLabel={`Option ${opt.id}`}
                  style={[
                    styles.optBtn,
                    {
                      borderColor,
                      backgroundColor: bgColor,
                      opacity: pick && !selected && !isCorrect ? 0.55 : 1,
                    },
                  ]}
                >
                  <View
                    style={[
                      styles.optBadge,
                      {
                        backgroundColor: pick
                          ? isCorrect
                            ? palette.success
                            : selected
                              ? palette.danger
                              : palette.surfaceMuted
                          : palette.surfaceMuted,
                      },
                    ]}
                  >
                    <Text
                      style={{
                        fontFamily: TYPE_FONTS.mono,
                        fontWeight: '700',
                        color:
                          pick && (isCorrect || selected) ? '#FFFFFF' : palette.text,
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
                  {pick && isCorrect && (
                    <CheckCircle size={18} color={palette.success} weight="fill" />
                  )}
                  {pick && selected && !isCorrect && (
                    <XCircle size={18} color={palette.danger} weight="fill" />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>

          {pick && (
            <View style={styles.feedbackBlock}>
              <View
                style={[
                  styles.solutionBox,
                  { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
                ]}
              >
                <View style={styles.rowBetween}>
                  <Text style={[styles.solLabel, { color: palette.primary }]}>
                    Step-by-Step Solution
                  </Text>
                  <TouchableOpacity
                    onPress={() =>
                      navigate({
                        name: 'aiTutor',
                        questionId: activeQ.id,
                        topicId: activeQ.topicId,
                        subjectId: activeQ.subjectId,
                      })
                    }
                    accessibilityRole="button"
                    accessibilityLabel="Discuss with AETHER AI Engine"
                  >
                    <Text style={{ color: palette.primary, fontSize: 12, fontWeight: '700' }}>
                      Ask AETHER AI →
                    </Text>
                  </TouchableOpacity>
                </View>
                <MathText
                  text={activeQ.explanation}
                  style={{ color: palette.text, fontSize: 13.5, lineHeight: 20 }}
                />
              </View>

              <Text style={{ color: palette.textMuted, fontSize: 12.5, fontWeight: '700' }}>
                How did this recall feel? (FSRS-4.5):
              </Text>
              <View style={styles.fsrsRow}>
                {[
                  { r: FSRSRating.again, l: 'Again', sub: '<10m', c: palette.danger },
                  { r: FSRSRating.hard, l: 'Hard', sub: '1d', c: palette.amber },
                  { r: FSRSRating.good, l: 'Good', sub: '3d', c: palette.success },
                  { r: FSRSRating.easy, l: 'Easy', sub: '6d', c: palette.info },
                ].map((b) => (
                  <TouchableOpacity
                    key={b.l}
                    onPress={() => rateCard(b.r)}
                    style={[
                      styles.fsrsBtn,
                      { borderColor: b.c, backgroundColor: palette.surface },
                    ]}
                  >
                    <Text style={{ color: b.c, fontWeight: '700', fontSize: 12.5 }}>
                      {b.l}
                    </Text>
                    <Text
                      style={{
                        fontFamily: TYPE_FONTS.mono,
                        color: palette.textMuted,
                        fontSize: 10.5,
                        fontWeight: '600',
                      }}
                    >
                      {b.sub}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}

          <View style={styles.rowBetween}>
            <TouchableOpacity
              disabled={idx === 0}
              onPress={() => {
                setIdx((i) => Math.max(0, i - 1));
                setQuestionOpenedAtMs(Date.now());
              }}
              style={[
                styles.navBtn,
                { borderColor: palette.borderStrong, opacity: idx === 0 ? 0.4 : 1 },
              ]}
            >
              <Text style={{ color: palette.text, fontSize: 13.5, fontWeight: '700' }}>
                ← Prev
              </Text>
            </TouchableOpacity>
            <ScalePressable
              disabled={idx >= questions.length - 1}
              onPress={() => {
                setIdx((i) => Math.min(questions.length - 1, i + 1));
                setQuestionOpenedAtMs(Date.now());
              }}
              style={[
                styles.navBtn,
                {
                  backgroundColor: PREP404_COLORS.plum,
                  borderColor: PREP404_COLORS.plum,
                },
              ]}
            >
              <Text style={{ color: '#FFFFFF', fontSize: 13.5, fontWeight: '700' }}>
                Next →
              </Text>
            </ScalePressable>
          </View>
        </EditorialCard>
      )}

      {/* AETHER AI Step Bottom Sheet */}
      <BottomSheetModal
        visible={hintOpen}
        onClose={() => setHintOpen(false)}
        title={`AETHER AI Step #${hintStep + 1}`}
        subtitle="Direct step-by-step breakdown before full solution"
      >
        <MathText
          text={
            activeQ?.hints?.[hintStep] ||
            'Identify the given constraints and formula first.'
          }
          style={{ color: palette.text, fontSize: 14.5, lineHeight: 21 }}
        />
        <View style={styles.rowBetween}>
          {activeQ?.hints && hintStep < activeQ.hints.length - 1 ? (
            <TouchableOpacity onPress={() => setHintStep((s) => s + 1)}>
              <Text style={{ color: palette.primary, fontWeight: '700', fontSize: 13.5 }}>
                Reveal Next Step
              </Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              onPress={() => {
                setHintOpen(false);
                if (activeQ) {
                  navigate({
                    name: 'aiTutor',
                    questionId: activeQ.id,
                    topicId: activeQ.topicId,
                    subjectId: activeQ.subjectId,
                  });
                }
              }}
            >
              <Text style={{ color: palette.primary, fontWeight: '700', fontSize: 13.5 }}>
                Open AETHER AI Engine →
              </Text>
            </TouchableOpacity>
          )}
          <ScalePressable
            onPress={() => setHintOpen(false)}
            style={[styles.closeBtn, { backgroundColor: palette.primary }]}
          >
            <Text style={{ color: palette.primaryInk, fontWeight: '700', fontSize: 13.5 }}>
              Got It
            </Text>
          </ScalePressable>
        </View>
      </BottomSheetModal>

      {/* Report Bottom Sheet */}
      <BottomSheetModal
        visible={reportOpen}
        onClose={() => setReportOpen(false)}
        title="Report Question Issue"
        subtitle="Flag incorrect keys, typos, or unclear formatting"
      >
        <TextInput
          value={reportReason}
          onChangeText={setReportReason}
          style={[
            styles.input,
            {
              color: palette.text,
              borderColor: palette.border,
              backgroundColor: palette.surfaceMuted,
            },
          ]}
        />
        <ScalePressable
          onPress={() => {
            if (activeQ) {
              storageService.addReportedQuestion({
                id: `rep_${Date.now()}`,
                questionId: activeQ.id,
                questionPreview: activeQ.text,
                reason: reportReason,
                status: 'submitted',
                createdAt: new Date().toISOString(),
              });
            }
            setReportOpen(false);
            showToast('Question reported!');
          }}
          style={[styles.closeBtn, { backgroundColor: palette.danger, alignItems: 'center' }]}
        >
          <Text style={{ color: '#FFFFFF', fontWeight: '700', fontSize: 13.5 }}>
            Submit Report
          </Text>
        </ScalePressable>
      </BottomSheetModal>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
  h1: { fontFamily: TYPE_FONTS.display, fontSize: 19, fontWeight: '800' },
  counter: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 13,
    fontVariant: ['tabular-nums'],
  },
  progressTrack: { height: 5, borderRadius: 3, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 3 },
  filterRow: { flexDirection: 'row', gap: 8 },
  filterTab: {
    paddingHorizontal: 14,
    minHeight: 38,
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: 'center',
  },
  kicker: { fontFamily: TYPE_FONTS.mono, fontSize: 12, fontWeight: '700', flex: 1 },
  toolActions: { flexDirection: 'row', gap: 8 },
  iconBox: {
    width: 40,
    height: 40,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  passageBox: { padding: 14, borderRadius: 12, borderWidth: 1 },
  optList: { gap: 10 },
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
  optBadge: {
    width: 30,
    height: 30,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
  },
  feedbackBlock: { gap: 10, marginTop: 4 },
  solutionBox: { padding: 14, borderRadius: 12, borderWidth: 1, gap: 6 },
  solLabel: { fontSize: 12.5, fontWeight: '700' },
  fsrsRow: { flexDirection: 'row', gap: 8 },
  fsrsBtn: {
    flex: 1,
    borderWidth: 1.5,
    borderRadius: 12,
    minHeight: 50,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  navBtn: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 18,
    height: 44,
    justifyContent: 'center',
  },
  closeBtn: {
    paddingHorizontal: 18,
    height: 44,
    borderRadius: RADII.md,
    justifyContent: 'center',
  },
  input: { borderWidth: 1, borderRadius: RADII.md, padding: 12, minHeight: 46 },
});

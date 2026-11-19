import React, { useMemo, useState } from 'react';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import {
  CaretRight,
  CheckCircle,
  Fire,
  Robot,
  ShieldWarning,
  XCircle,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { QUESTION_BANK } from '../data/questionBank';
import { computeMistakeVault } from '../services/examService';
import { storageService } from '../services/storageService';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { MathText } from '../components/MathText';
import { ProgressRing } from '../components/ProgressRing';
import { SubjectAccuracyTrendChart } from '../components/SubjectAccuracyTrendChart';
import {
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';
import { buildSubjectPerformanceTrends } from '../services/performanceTrendService';
import { KnowledgeProfileScreen } from './KnowledgeProfileScreen';

export const ExamHistoryScreen: React.FC = () => {
  const { palette, navigate } = useApp();
  const [tab, setTab] = useState<'mastery' | 'analytics' | 'scripts'>('mastery');
  const history = storageService.getExamHistory();

  const stats = useMemo(() => {
    const right = history.reduce((a, b) => a + b.correctCount, 0);
    const wrong = history.reduce((a, b) => a + b.wrongCount, 0);
    const skipped = history.reduce((a, b) => a + b.unansweredCount, 0);
    const acc =
      right + wrong > 0 ? Math.round((right / (right + wrong)) * 100) : 0;
    return { exams: history.length, right, wrong, skipped, acc };
  }, [history]);

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={styles.heroRow}>
          <View style={{ flex: 1, gap: 4 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              LEARNER INTELLIGENCE · PHASE 1
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              360° Mastery & Analytics
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              {stats.exams} Tests Completed · {stats.right} Correct · FSRS-4.5 Active
            </Text>
          </View>
          <ProgressRing
            percent={stats.acc}
            size={76}
            strokeWidth={7}
            color={palette.success}
            trackColor={palette.border}
            textColor={palette.text}
            labelColor={palette.textMuted}
            label="Accuracy"
          />
        </View>
      </EditorialCard>

      <EditorialCard style={{ paddingVertical: 4 }}>
        <HairlineRow
          onPress={() => navigate({ name: 'aiTutor' })}
          accessibilityLabel="Open AETHER AI Engine and Conversation Vault"
          left={
            <View style={styles.rowInline}>
              <View
                style={[
                  styles.iconBox,
                  { backgroundColor: palette.creamTint },
                ]}
              >
                <Robot size={18} color={palette.primary} weight="duotone" />
              </View>
              <View style={{ flex: 1, gap: 2 }}>
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  AETHER AI Engine & Telemetry Vault
                </Text>
                <Text style={[styles.rowSub, { color: palette.textMuted }]}>
                  Direct solver, 15s shortcuts & Read→Think→Lock finger telemetry
                </Text>
              </View>
            </View>
          }
          right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
        />
        <HairlineRow
          isLast
          onPress={() => navigate({ name: 'mistakeVault' })}
          accessibilityLabel="Mistake and Weak Topic Vault"
          left={
            <View style={styles.rowInline}>
              <View
                style={[
                  styles.iconBox,
                  { backgroundColor: palette.dangerSoft },
                ]}
              >
                <ShieldWarning size={18} color={palette.danger} weight="duotone" />
              </View>
              <View style={{ flex: 1, gap: 2 }}>
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  Mistake & Weak Topic Vault
                </Text>
                <Text style={[styles.rowSub, { color: palette.textMuted }]}>
                  Launch 1-click adaptive re-tests on missed topics
                </Text>
              </View>
            </View>
          }
          right={<CaretRight size={18} color={palette.textMuted} weight="bold" />}
        />
      </EditorialCard>

      <SegmentedControl
        value={tab}
        onChange={setTab}
        options={[
          { id: 'mastery', label: '360° Mastery' },
          { id: 'analytics', label: 'KPIs' },
          { id: 'scripts', label: `Scripts (${history.length})` },
        ]}
      />

      {tab === 'mastery' ? (
        <KnowledgeProfileScreen embedded />
      ) : tab === 'analytics' ? (
        <View style={styles.kpiGrid}>
          {(
            [
              ['Exams Taken', String(stats.exams), palette.secondary],
              ['Accuracy Rate', `${stats.acc}%`, palette.primary],
              ['Total Correct', String(stats.right), palette.success],
              ['Total Wrong', String(stats.wrong), palette.danger],
            ] as const
          ).map(([label, value, accent]) => (
            <EditorialCard key={label} style={styles.kpiCard}>
              <Text style={[styles.kpiLabel, { color: palette.textMuted }]}>
                {label}
              </Text>
              <Text style={[styles.kpiValue, { color: accent }]}>{value}</Text>
            </EditorialCard>
          ))}
        </View>
      ) : history.length === 0 ? (
        <EditorialCard>
          <Text style={[styles.emptyText, { color: palette.textMuted }]}>
            Complete a model test or daily sprint to unlock script reviews.
          </Text>
        </EditorialCard>
      ) : (
        <EditorialCard style={{ paddingVertical: 4 }}>
          {history.map((h, idx) => (
            <HairlineRow
              key={h.id}
              isLast={idx === history.length - 1}
              onPress={() => navigate({ name: 'examReview', historyId: h.id })}
              left={
                <View style={{ gap: 2 }}>
                  <Text style={[styles.rowTitle, { color: palette.text }]}>
                    {h.title}
                  </Text>
                  <Text style={[styles.rowSub, { color: palette.textMuted }]}>
                    {h.track} · {h.mode === 'omrBubble' ? 'OMR Sheet' : 'Digital'}
                  </Text>
                </View>
              }
              right={
                <View style={styles.rowInline}>
                  <Text style={[styles.scoreMono, { color: palette.text }]}>
                    {h.score}/{h.totalQuestions}
                  </Text>
                  <CaretRight size={18} color={palette.textMuted} weight="bold" />
                </View>
              }
            />
          ))}
        </EditorialCard>
      )}
    </ScrollView>
  );
};

export const ExamScriptReviewScreen: React.FC<{ historyId: string }> = ({
  historyId,
}) => {
  const { palette, navigate } = useApp();
  const item = storageService
    .getExamHistory()
    .find((h) => h.id === historyId);
  if (!item) return null;
  const qMap = new Map(QUESTION_BANK.map((q) => [q.id, q]));

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.primary }]}>
          SCRIPT REVIEW · {item.track}
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          {item.title}
        </Text>
        <Text style={[styles.scoreSubMono, { color: palette.textMuted }]}>
          Score {item.score}/{item.totalQuestions} · {item.correctCount} Correct ·{' '}
          {item.wrongCount} Wrong · {item.unansweredCount} Skipped
        </Text>
      </EditorialCard>

      {item.questionIds.map((id, idx) => {
        const q = qMap.get(id);
        if (!q) return null;
        const picked = item.userAnswers[id];
        const isRight =
          picked?.toUpperCase() === q.correctOptionId.toUpperCase();
        return (
          <EditorialCard key={id}>
            <View style={styles.rowBetween}>
              <Text style={[styles.kicker, { color: palette.textMuted }]}>
                Q{idx + 1} · {q.subjectName}
              </Text>
              <View style={styles.inlineIcon}>
                {picked ? (
                  isRight ? (
                    <CheckCircle size={15} color={palette.success} weight="fill" />
                  ) : (
                    <XCircle size={15} color={palette.danger} weight="fill" />
                  )
                ) : null}
                <Text
                  style={[
                    styles.statusText,
                    {
                      color: !picked
                        ? palette.textMuted
                        : isRight
                          ? palette.success
                          : palette.danger,
                    },
                  ]}
                >
                  {!picked
                    ? `Skipped (Ans ${q.correctOptionId})`
                    : isRight
                      ? `Correct (${q.correctOptionId})`
                      : `Picked ${picked} · Ans ${q.correctOptionId}`}
                </Text>
              </View>
            </View>
            <MathText
              text={q.text}
              style={{
                color: palette.text,
                fontFamily: TYPE_FONTS.body,
                fontSize: 14.5,
                fontWeight: '700',
                lineHeight: 21,
              }}
            />
            <View
              style={[
                styles.explainBox,
                {
                  backgroundColor: palette.surfaceMuted,
                  borderColor: palette.border,
                },
              ]}
            >
              <MathText
                text={q.explanation}
                style={{
                  color: palette.textMuted,
                  fontSize: 13,
                  lineHeight: 19,
                }}
              />
            </View>
            <TouchableOpacity
              onPress={() =>
                navigate({
                  name: 'aiTutor',
                  questionId: q.id,
                  topicId: q.topicId,
                  subjectId: q.subjectId,
                })
              }
              accessibilityRole="button"
              accessibilityLabel={`Ask AETHER AI Engine about Question ${idx + 1}`}
            >
              <Text style={[styles.linkAction, { color: palette.primary }]}>
                Ask AETHER AI Engine →
              </Text>
            </TouchableOpacity>
          </EditorialCard>
        );
      })}
    </ScrollView>
  );
};

export const MistakeVaultScreen: React.FC = () => {
  const { palette, navigate } = useApp();
  const vault = useMemo(() => computeMistakeVault(), []);
  const performanceTrends = useMemo(() => buildSubjectPerformanceTrends(), []);

  const launchReTest = () => {
    const qs = [...vault.mistakes, ...vault.skipped];
    navigate({
      name: 'liveExam',
      slug: 'adaptive-retest',
      title: 'Mistake Vault Adaptive Re-Test',
      durationMinutes: 15,
      negativeMark: 0,
      isPracticeMode: true,
      questions: qs.length > 0 ? qs : QUESTION_BANK.slice(0, 8),
    });
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.danger }]}>
          REMEDIATION VAULT
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          Mistake & Revision Vault
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Target high-deficit chapters immediately with an adaptive practice set.
        </Text>
        <ScalePressable
          onPress={launchReTest}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Launch 1-Click Adaptive Re-Test
          </Text>
        </ScalePressable>
      </EditorialCard>

      <EditorialCard>
        <SubjectAccuracyTrendChart dataset={performanceTrends} />
      </EditorialCard>

      {vault.weakTopics.length === 0 ? (
        <EditorialCard>
          <Text style={[styles.emptyText, { color: palette.textMuted }]}>
            No weak topics logged yet. Attempt model exams to identify focus areas.
          </Text>
        </EditorialCard>
      ) : (
        <EditorialCard style={{ paddingVertical: 4 }}>
          {vault.weakTopics.map((wt, idx) => (
            <HairlineRow
              key={wt.topicId}
              isLast={idx === vault.weakTopics.length - 1}
              left={
                <View style={{ gap: 2 }}>
                  <Text style={[styles.rowTitle, { color: palette.text }]}>
                    #{wt.rank} {wt.topicName}
                  </Text>
                  <Text style={[styles.rowSub, { color: palette.textMuted }]}>
                    {wt.wrongCount} Wrong · {wt.skippedCount} Skipped
                  </Text>
                </View>
              }
              right={
                <Text style={[styles.deficitMono, { color: palette.danger }]}>
                  Deficit {wt.deficitScore}
                </Text>
              }
            />
          ))}
        </EditorialCard>
      )}
    </ScrollView>
  );
};

export const StudyStreakDetailScreen: React.FC = () => {
  const { profile, palette } = useApp();
  const days = profile?.studyStreakDays ?? 0;

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={styles.heroRow}>
          <View
            style={[
              styles.iconBoxLarge,
              { backgroundColor: palette.warningSoft },
            ]}
          >
            <Fire size={26} color={palette.amber} weight="fill" />
          </View>
          <View style={{ flex: 1, gap: 3 }}>
            <Text style={[styles.kicker, { color: palette.amber }]}>
              DAILY CONSISTENCY
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              {days} Day Study Streak
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              1.5x XP Multiplier Active · Keep reviewing daily cards
            </Text>
          </View>
        </View>
      </EditorialCard>

      <EditorialCard style={{ paddingVertical: 4 }}>
        {[3, 7, 14, 30, 60].map((target, idx, arr) => {
          const unlocked = days >= target;
          return (
            <HairlineRow
              key={target}
              isLast={idx === arr.length - 1}
              left={
                <Text style={[styles.rowTitle, { color: palette.text }]}>
                  {target} Days Streak Milestone
                </Text>
              }
              right={
                <View style={styles.inlineIcon}>
                  {unlocked && (
                    <CheckCircle size={16} color={palette.success} weight="fill" />
                  )}
                  <Text
                    style={[
                      styles.statusText,
                      {
                        color: unlocked ? palette.success : palette.textMuted,
                      },
                    ]}
                  >
                    {unlocked ? 'Unlocked' : `${target - days}d to go`}
                  </Text>
                </View>
              }
            />
          );
        })}
      </EditorialCard>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  heroRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  kicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  title: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 20,
    fontWeight: '800',
  },
  subText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    lineHeight: 19,
  },
  scoreSubMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  rowInline: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  iconBox: {
    width: 40,
    height: 40,
    borderRadius: RADII.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBoxLarge: {
    width: 52,
    height: 52,
    borderRadius: RADII.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowTitle: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 14,
    fontWeight: '700',
  },
  rowSub: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
  },
  kpiGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  kpiCard: { width: '48.2%', gap: 6 },
  kpiLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '600',
  },
  kpiValue: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 24,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  scoreMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 13,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  deficitMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  emptyText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    textAlign: 'center',
    paddingVertical: 16,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  inlineIcon: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  statusText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '700',
  },
  explainBox: {
    padding: 12,
    borderRadius: RADII.md,
    borderWidth: 1,
  },
  primaryBtn: {
    borderRadius: RADII.md,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  primaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '700',
    fontSize: 14.5,
  },
  linkAction: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 12.5,
    fontWeight: '700',
  },
});

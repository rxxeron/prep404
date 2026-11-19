import React, { useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CalendarBlank,
  CheckCircle,
  Clock,
  Fingerprint,
  LockSimple,
  Play,
  Robot,
  ShieldCheck,
  Sparkle,
  Target,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import {
  PHASE_1_UNIVERSITY_CODES,
  getUniversityBlueprint,
} from '../data/universities';
import { synthesizeAetherPersonalPlan } from '../services/admissionPlanService';
import { storageService } from '../services/storageService';
import { DisciplineCategory, RoadmapMilestone } from '../types';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import {
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';

/**
 * Pure React Native AETHER AI Personalized Countdown Roadmap, Custom Syllabus & Unified Personal Exam screen.
 * Replaces static 5/10/15/30/60-day S-curves with exact admission countdown + personal telemetry calibration.
 */
export const RoadmapScreen: React.FC = () => {
  const { palette, profile, navigate, showToast } = useApp();
  const [selectedUni, setSelectedUni] = useState<string>(
    Object.keys(profile?.targetSelections || {})[0]?.toUpperCase() || 'NSU'
  );
  const [activeTab, setActiveTab] = useState<'countdown' | 'syllabus'>('countdown');
  const [completedIds, setCompletedIds] = useState<string[]>(() =>
    storageService.getCompletedRoadmapIds()
  );

  const selectedDepts = Object.values(profile?.targetSelections || {}).flat();
  const category: DisciplineCategory = selectedDepts.some((d) =>
    ['BBA', 'ECO', 'ACT', 'FIN', 'MKT'].includes(d.toUpperCase())
  )
    ? 'business'
    : selectedDepts.some((d) => ['PHARM', 'BIO', 'MIC'].includes(d.toUpperCase()))
    ? 'pharmacy'
    : selectedDepts.some((d) => ['LAW', 'LLB', 'ENG'].includes(d.toUpperCase()))
    ? 'lawAndArts'
    : 'engineering';

  const blueprint = useMemo(
    () => getUniversityBlueprint(selectedUni, category),
    [selectedUni, category]
  );

  const personalPlan = useMemo(
    () =>
      synthesizeAetherPersonalPlan({
        universityCode: selectedUni,
        category,
        completedIds,
      }),
    [selectedUni, category, completedIds]
  );

  const completedCount = personalPlan.milestones.filter(
    (m) => m.status === 'completed'
  ).length;

  const launchUnifiedPersonalExam = () => {
    const exam = personalPlan.unifiedPersonalExam;
    navigate({
      name: 'liveExam',
      slug: exam.slug,
      title: exam.title,
      durationMinutes: exam.durationMinutes,
      negativeMark: 0,
      isPracticeMode: false,
      questions: personalPlan.personalExamQuestions,
    });
  };

  const launchMilestone = (m: RoadmapMilestone) => {
    if (m.status === 'locked') {
      showToast('Complete the current active countdown step first.');
      return;
    }
    storageService.markRoadmapCompleted(m.id);
    setCompletedIds(storageService.getCompletedRoadmapIds());

    if (m.pillar === 'overall' || m.pillar === 'section') {
      navigate({
        name: 'liveExam',
        slug: `aether-${selectedUni.toLowerCase()}-${m.id}`,
        title: `${selectedUni} · ${m.title}`,
        durationMinutes: m.durationMinutes,
        negativeMark: 0,
        isPracticeMode: true,
        questions: personalPlan.personalExamQuestions.slice(0, m.questionCount),
      });
    } else {
      navigate({
        name: 'practice',
        topicId: m.topicId,
        title: m.title,
      });
    }
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Target University Switcher (All 7 Private Universities — 0 Negative Marking) */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.uniRow}
      >
        {PHASE_1_UNIVERSITY_CODES.map((code) => {
          const active = selectedUni === code;
          return (
            <TouchableOpacity
              key={code}
              onPress={() => setSelectedUni(code)}
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              accessibilityLabel={`${code} personalized countdown plan`}
              style={[
                styles.uniTab,
                {
                  borderColor: active ? palette.primary : palette.border,
                  backgroundColor: active ? palette.creamTint : palette.surface,
                },
              ]}
            >
              <Text
                style={[
                  styles.uniTabText,
                  { color: active ? palette.primary : palette.textMuted },
                ]}
              >
                {code}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* AETHER AI Dynamic Admission Countdown & Learner Evaluation Header */}
      <EditorialCard>
        <View style={styles.topBetween}>
          <View style={styles.kickerRow}>
            <Sparkle size={14} color={palette.primary} weight="fill" />
            <Text style={[styles.kicker, { color: palette.primary }]}>
              AETHER AI PERSONALIZED COUNTDOWN · {blueprint.universityCode}
            </Text>
          </View>
          <View
            style={[
              styles.countdownBadge,
              {
                backgroundColor: palette.creamTint,
                borderColor: palette.primary,
              },
            ]}
          >
            <CalendarBlank size={13} color={palette.primary} weight="bold" />
            <Text style={[styles.countdownBadgeText, { color: palette.primary }]}>
              {personalPlan.daysRemaining} DAYS TO EXAM
            </Text>
          </View>
        </View>

        <Text style={[styles.heroTitle, { color: palette.text }]}>
          {blueprint.universityName} ({personalPlan.examDateFormatted})
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Evaluated Level: {personalPlan.learnerLevelLabel} · Seriousness{' '}
          {personalPlan.seriousnessScore}% ({personalPlan.seriousnessStatus}) · Zero
          Negative Marking (0.00)
        </Text>

        {/* Live Telemetry & Cut-Off Calibration Strip */}
        <View style={styles.metricsGrid}>
          <View
            style={[
              styles.metricTile,
              { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
            ]}
          >
            <Text style={[styles.metricValue, { color: palette.primary }]}>
              {personalPlan.daysRemaining}d
            </Text>
            <Text style={[styles.metricLabel, { color: palette.textMuted }]}>
              Days Left
            </Text>
          </View>
          <View
            style={[
              styles.metricTile,
              { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
            ]}
          >
            <Text style={[styles.metricValue, { color: palette.text }]}>
              {personalPlan.projectedScore}/{blueprint.totalQuestions}
            </Text>
            <Text style={[styles.metricLabel, { color: palette.textMuted }]}>
              Projected (Cut {personalPlan.cutOffScore})
            </Text>
          </View>
          <View
            style={[
              styles.metricTile,
              { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
            ]}
          >
            <Text
              style={[
                styles.metricValue,
                {
                  color:
                    personalPlan.seriousnessScore >= 80
                      ? palette.success
                      : palette.amber,
                },
              ]}
            >
              {personalPlan.seriousnessScore}%
            </Text>
            <Text style={[styles.metricLabel, { color: palette.textMuted }]}>
              Seriousness
            </Text>
          </View>
          <View
            style={[
              styles.metricTile,
              { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
            ]}
          >
            <Text style={[styles.metricValue, { color: PREP404_COLORS.plum }]}>
              {personalPlan.dailyStudyMinutes}m/d
            </Text>
            <Text style={[styles.metricLabel, { color: palette.textMuted }]}>
              Daily Quota ({personalPlan.dailyQuestionQuota} Qs)
            </Text>
          </View>
        </View>
      </EditorialCard>

      {/* ONE UNIFIED PERSONAL EXAM ACCESS CARD */}
      <EditorialCard
        style={{
          borderColor: palette.primary,
          backgroundColor: palette.creamTint,
        }}
      >
        <View style={styles.topBetween}>
          <View style={styles.kickerRow}>
            <Target size={15} color={palette.primary} weight="fill" />
            <Text style={[styles.kicker, { color: palette.primary }]}>
              ONE UNIFIED PERSONAL EXAM ACCESS · ONLY FOR YOU
            </Text>
          </View>
          <View
            style={[
              styles.lockTag,
              { backgroundColor: palette.surface, borderColor: palette.borderStrong },
            ]}
          >
            <LockSimple size={12} color={palette.text} weight="bold" />
            <Text style={[styles.lockTagText, { color: palette.text }]}>
              1-TAP ANSWER LOCK · 0 NEGATIVE
            </Text>
          </View>
        </View>

        <Text style={[styles.examCardTitle, { color: palette.text }]}>
          {personalPlan.unifiedPersonalExam.title}
        </Text>
        <Text style={[styles.subText, { color: palette.text }]}>
          {personalPlan.unifiedPersonalExam.calibrationSummary}
        </Text>

        <View style={styles.examMetaRow}>
          <Text style={[styles.monoBadge, { color: palette.textMuted }]}>
            {personalPlan.unifiedPersonalExam.questionCount} Personalized MCQs
          </Text>
          <Text style={[styles.monoBadge, { color: palette.textMuted }]}>
            · {personalPlan.unifiedPersonalExam.durationMinutes} Mins
          </Text>
          <Text style={[styles.monoBadge, { color: palette.success }]}>
            · Digital & Software OMR Ready
          </Text>
        </View>

        <View style={styles.ctaRow}>
          <ScalePressable
            onPress={launchUnifiedPersonalExam}
            accessibilityLabel="Launch Unified Personal Exam"
            containerStyle={{ flex: 1 }}
            style={[styles.primaryCta, { backgroundColor: palette.primary }]}
          >
            <Play size={15} color={palette.primaryInk} weight="fill" />
            <Text style={[styles.primaryCtaText, { color: palette.primaryInk }]}>
              Launch My Personal Exam
            </Text>
          </ScalePressable>

          <TouchableOpacity
            onPress={() =>
              navigate({
                name: 'knowledgeProfile',
                initialUniversityCode: selectedUni,
              })
            }
            accessibilityRole="button"
            accessibilityLabel="Inspect How AETHER AI Evaluates You"
            style={[
              styles.secondaryCta,
              {
                borderColor: palette.borderStrong,
                backgroundColor: palette.surface,
              },
            ]}
          >
            <Fingerprint size={16} color={palette.text} weight="bold" />
            <Text style={[styles.secondaryCtaText, { color: palette.text }]}>
              Evaluation
            </Text>
          </TouchableOpacity>
        </View>
      </EditorialCard>

      {/* Switch between Daily Countdown Execution & Custom Personalized Syllabus */}
      <SegmentedControl<'countdown' | 'syllabus'>
        value={activeTab}
        onChange={setActiveTab}
        options={[
          {
            id: 'countdown',
            label: `Countdown Plan (${completedCount}/${personalPlan.milestones.length})`,
          },
          {
            id: 'syllabus',
            label: `Custom Syllabus (${personalPlan.customSyllabus.length})`,
          },
        ]}
      />

      {activeTab === 'syllabus' ? (
        <EditorialCard style={{ gap: 12 }}>
          <View style={styles.topBetween}>
            <Text style={[styles.sectionTitle, { color: palette.text }]}>
              AETHER AI Custom Syllabus ({selectedUni})
            </Text>
            <TouchableOpacity
              onPress={() =>
                navigate({
                  name: 'aiTutor',
                  initialMode: 'study_planner',
                })
              }
              accessibilityRole="button"
              style={styles.inlineLink}
            >
              <Robot size={15} color={palette.primary} weight="bold" />
              <Text style={{ color: palette.primary, fontSize: 12, fontWeight: '700' }}>
                Ask AETHER AI
              </Text>
            </TouchableOpacity>
          </View>
          <Text style={[styles.subText, { color: palette.textMuted }]}>
            Weighted specifically for your current knowledge gaps, FSRS retention, and{' '}
            {personalPlan.daysRemaining}-day countdown to {blueprint.universityCode}.
          </Text>

          {personalPlan.customSyllabus.map((mod, idx) => {
            const isCritical = mod.priorityLevel === 'CRITICAL';
            return (
              <HairlineRow
                key={mod.id}
                isLast={idx === personalPlan.customSyllabus.length - 1}
                onPress={() =>
                  navigate({
                    name: 'practice',
                    topicId: mod.topicId,
                    title: `${selectedUni} · ${mod.title}`,
                  })
                }
                left={
                  <View style={{ flex: 1, gap: 4 }}>
                    <View style={styles.kickerRow}>
                      <View
                        style={[
                          styles.priorityChip,
                          {
                            backgroundColor: isCritical
                              ? palette.dangerSoft
                              : palette.warningSoft,
                          },
                        ]}
                      >
                        <Text
                          style={{
                            fontFamily: TYPE_FONTS.mono,
                            fontSize: 10,
                            fontWeight: '700',
                            color: isCritical ? palette.danger : palette.amber,
                          }}
                        >
                          {mod.priorityLevel} · {mod.weightPercent}% WEIGHT
                        </Text>
                      </View>
                      <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                        {mod.subjectName} · ~{mod.estimatedHours}h
                      </Text>
                    </View>
                    <Text style={[styles.stepTitle, { color: palette.text }]}>
                      {mod.title}
                    </Text>
                    <Text style={[styles.subText, { color: palette.textMuted }]}>
                      {mod.rationale}
                    </Text>
                  </View>
                }
                right={
                  <View style={{ alignItems: 'flex-end', gap: 2 }}>
                    <Text style={[styles.monoValue, { color: palette.primary }]}>
                      {mod.currentMasteryPercent}% → {mod.targetMasteryPercent}%
                    </Text>
                    <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                      Drill →
                    </Text>
                  </View>
                }
              />
            );
          })}
        </EditorialCard>
      ) : (
        <View style={{ gap: 10 }}>
          {personalPlan.milestones.map((m) => {
            const isDone = m.status === 'completed';
            const isActive = m.status === 'active';
            const borderColor = isActive
              ? palette.primary
              : isDone
                ? palette.success
                : palette.border;

            return (
              <EditorialCard
                key={m.id}
                style={{
                  borderColor,
                  backgroundColor: isActive ? palette.creamTint : palette.surface,
                }}
              >
                <TouchableOpacity
                  onPress={() => launchMilestone(m)}
                  accessibilityRole="button"
                  accessibilityLabel={`${m.title}, ${m.status}`}
                  style={styles.milestoneRow}
                >
                  <View
                    style={[
                      styles.stepBadge,
                      {
                        backgroundColor: isDone
                          ? palette.successSoft
                          : isActive
                            ? palette.primary
                            : palette.surfaceMuted,
                      },
                    ]}
                  >
                    {isDone ? (
                      <CheckCircle size={18} color={palette.success} weight="fill" />
                    ) : isActive ? (
                      <Play size={16} color={palette.primaryInk} weight="fill" />
                    ) : (
                      <Text style={[styles.stepIndexText, { color: palette.textMuted }]}>
                        {m.index}
                      </Text>
                    )}
                  </View>

                  <View style={{ flex: 1, gap: 3 }}>
                    <View style={styles.topBetween}>
                      <Text style={[styles.monoSmall, { color: palette.primary }]}>
                        STEP {m.index} · {m.subjectTag.toUpperCase()}
                      </Text>
                      <View style={styles.kickerRow}>
                        <Clock size={12} color={palette.textMuted} />
                        <Text style={[styles.monoSmall, { color: palette.textMuted }]}>
                          {m.questionCount} Qs · {m.durationMinutes}m
                        </Text>
                      </View>
                    </View>
                    <Text style={[styles.stepTitle, { color: palette.text }]}>
                      {m.title}
                    </Text>
                    <Text style={[styles.subText, { color: palette.textMuted }]}>
                      {m.subtitle}
                    </Text>
                    {isDone && m.accuracyPercent !== undefined && (
                      <View style={styles.kickerRow}>
                        <ShieldCheck size={13} color={palette.success} weight="fill" />
                        <Text
                          style={[
                            styles.monoSmall,
                            { color: palette.success, fontWeight: '700' },
                          ]}
                        >
                          Verified {m.accuracyPercent}% Accuracy · +{m.xpReward} XP
                        </Text>
                      </View>
                    )}
                  </View>
                </TouchableOpacity>
              </EditorialCard>
            );
          })}
        </View>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  uniRow: { flexDirection: 'row', gap: 8 },
  uniTab: {
    paddingHorizontal: 14,
    minHeight: 38,
    borderRadius: 10,
    borderWidth: 1.5,
    justifyContent: 'center',
  },
  uniTabText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '700',
  },
  topBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
  },
  kickerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  kicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  countdownBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 8,
    borderWidth: 1,
  },
  countdownBadgeText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
  },
  heroTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 19,
    fontWeight: '800',
  },
  subText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    lineHeight: 18,
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 4,
  },
  metricTile: {
    flex: 1,
    minWidth: 76,
    borderWidth: 1,
    borderRadius: 10,
    paddingVertical: 8,
    paddingHorizontal: 8,
    alignItems: 'center',
    gap: 2,
  },
  metricValue: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 14.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  metricLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 10.5,
    fontWeight: '600',
    textAlign: 'center',
  },
  lockTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 7,
    borderWidth: 1,
  },
  lockTagText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10,
    fontWeight: '700',
  },
  examCardTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 17,
    fontWeight: '800',
  },
  examMetaRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  monoBadge: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
  },
  ctaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginTop: 4,
  },
  primaryCta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
    height: 44,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
  },
  primaryCtaText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13.5,
    fontWeight: '700',
  },
  secondaryCta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    height: 44,
    borderRadius: RADII.md,
    borderWidth: 1.5,
    paddingHorizontal: 12,
  },
  secondaryCtaText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13,
    fontWeight: '700',
  },
  sectionTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 16,
    fontWeight: '700',
  },
  inlineLink: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  priorityChip: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 5,
  },
  stepTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14.5,
    fontWeight: '700',
  },
  monoSmall: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '600',
  },
  monoValue: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '700',
  },
  milestoneRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  stepBadge: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  stepIndexText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 13,
    fontWeight: '700',
  },
});

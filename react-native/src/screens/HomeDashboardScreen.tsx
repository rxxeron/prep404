import React, { useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  Brain,
  CaretRight,
  Check,
  Clock,
  Play,
  Robot,
  ShieldWarning,
  Sword,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { getUniversityBlueprint, UNIVERSITY_CATALOG } from '../data/universities';
import { synthesizeAetherPersonalPlan } from '../services/admissionPlanService';
import { getDailyWindowStatus } from '../services/examService';
import { storageService } from '../services/storageService';
import { computeCandidateSeriousnessProfile } from '../services/telemetryService';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import { UniversityLogo } from '../components/UniversityLogo';
import { ProgressRing } from '../components/ProgressRing';
import { EditorialCard, ScalePressable } from '../components/DesignPrimitives';

const WEEK_DAYS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

export const HomeDashboardScreen: React.FC = () => {
  const { profile, palette, strings, navigate } = useApp();
  const [windowStatus, setWindowStatus] = useState(() => getDailyWindowStatus());
  const [selectedIdx, setSelectedIdx] = useState(0);

  useEffect(() => {
    const id = setInterval(() => setWindowStatus(getDailyWindowStatus()), 1000);
    return () => clearInterval(id);
  }, []);

  const targets = useMemo(() => {
    const selections = profile?.targetSelections || {
      brac: ['brac_cse'],
      nsu: ['nsu_cse'],
    };
    const list = Object.entries(selections)
      .map(([uniId, discIds]) => {
        const uni = UNIVERSITY_CATALOG.find(
          (u) => u.id === uniId || u.code.toLowerCase() === uniId.toLowerCase()
        );
        if (!uni) return null;
        const discs = uni.disciplines.filter((d) => discIds.includes(d.id));
        const daysLeft = Math.max(
          1,
          Math.ceil(
            (new Date(uni.estimatedExamDate).getTime() - Date.now()) / 86400000
          )
        );
        return {
          uni,
          discs: discs.length ? discs : [uni.disciplines[0]],
          daysLeft,
        };
      })
      .filter((x): x is NonNullable<typeof x> => Boolean(x));
    return list.length > 0
      ? list
      : [
          {
            uni: UNIVERSITY_CATALOG[5],
            discs: [UNIVERSITY_CATALOG[5].disciplines[0]],
            daysLeft: 45,
          },
        ];
  }, [profile]);

  const active = targets[selectedIdx] || targets[0];
  const blueprint = getUniversityBlueprint(
    active.uni.code,
    active.discs[0]?.category || 'engineering'
  );
  const history = storageService.getExamHistory();
  const telemetryCount = storageService.getQuestionTelemetryHistory().length;
  const fsrsCount = Object.keys(storageService.getFsrsCards()).length;
  const streakDays = profile?.studyStreakDays ?? 0;
  const seriousness = useMemo(
    () => computeCandidateSeriousnessProfile(),
    [history.length, telemetryCount]
  );
  const personalPlan = useMemo(
    () =>
      synthesizeAetherPersonalPlan({
        universityCode: active.uni.code,
        category: active.discs[0]?.category || 'engineering',
        completedIds: storageService.getCompletedRoadmapIds(),
      }),
    [active.uni.code, active.discs, history.length, telemetryCount]
  );

  const readinessPercent = personalPlan.overallMasteryPercent;

  const firstName =
    profile?.name?.split(' ')[0] || (strings.isBangla ? 'শিক্ষার্থী' : 'Candidate');

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Asymmetric Editorial Summary + 7-Day Streak */}
      <EditorialCard>
        <View style={styles.summaryTop}>
          <View style={styles.summaryCopy}>
            <Text style={[styles.kickerText, { color: palette.textSubtle }]}>
              {profile?.academicBatch || "HSC '25"} · {profile?.institutionName || 'Dhaka College'}
            </Text>
            <Text style={[styles.greetingTitle, { color: palette.text }]}>
              {strings.isBangla ? `স্বাগতম, ${firstName}` : `Hello, ${firstName}`}
            </Text>
            <Text style={[styles.summaryMeta, { color: palette.textMuted }]}>
              {active.uni.code} · {personalPlan.daysRemaining}d{'\u00A0'}to exam · {telemetryCount}{'\u00A0'}locks · Seriousness {seriousness.seriousnessScore}% · {fsrsCount}{'\u00A0'}FSRS
            </Text>
          </View>
          <ProgressRing
            percent={readinessPercent}
            size={76}
            strokeWidth={7}
            color={palette.primary}
            trackColor={palette.border}
            textColor={palette.text}
            labelColor={palette.textMuted}
            label={strings.isBangla ? 'প্রস্তুতি' : 'Ready'}
          />
        </View>

        <TouchableOpacity
          onPress={() => navigate({ name: 'streakDetail' })}
          accessibilityRole="button"
          accessibilityLabel={`Study streak, ${streakDays} days`}
          style={[styles.streakBox, { borderTopColor: palette.border }]}
        >
          <View style={styles.rowBetween}>
            <Text style={[styles.streakHeading, { color: palette.text }]}>
              {strings.isBangla ? '৭ দিনের অধ্যয়ন ধারা' : '7-Day Study Streak'}
            </Text>
            <Text style={[styles.streakValue, { color: palette.success }]}>
              {streakDays} {strings.isBangla ? 'দিন' : 'days'} →
            </Text>
          </View>

          <View style={styles.streakRow}>
            {WEEK_DAYS.map((day, idx) => {
              const completedCount = Math.min(7, Math.max(0, streakDays));
              const isDone = idx < completedCount;
              const isToday = idx === completedCount;
              return (
                <View
                  key={`${day}-${idx}`}
                  style={[
                    styles.dayCell,
                    {
                      backgroundColor: isDone
                        ? palette.successSoft
                        : isToday
                          ? palette.creamTint
                          : palette.surfaceMuted,
                      borderColor: isToday ? palette.primary : 'transparent',
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.dayText,
                      {
                        color: isDone
                          ? palette.success
                          : isToday
                            ? palette.primary
                            : palette.textMuted,
                      },
                    ]}
                  >
                    {day}
                  </Text>
                  {isDone ? (
                    <Check size={12} color={palette.success} weight="bold" />
                  ) : (
                    <Text
                      style={{
                        fontSize: 11,
                        fontWeight: '700',
                        color: isToday ? palette.primary : palette.textSubtle,
                      }}
                    >
                      {isToday ? 'Now' : '—'}
                    </Text>
                  )}
                </View>
              );
            })}
          </View>
        </TouchableOpacity>
      </EditorialCard>

      {/* Single Focal Primary CTA Card: One Unified Personal Exam Access */}
      <EditorialCard highlighted>
        <View style={styles.focalContent}>
          <Text style={[styles.focalLabel, { color: palette.primary }]}>
            AETHER AI PERSONALIZED EXAM · {personalPlan.daysRemaining} DAYS TO {active.uni.code}
          </Text>
          <Text style={[styles.focalTitle, { color: palette.text }]}>
            {personalPlan.unifiedPersonalExam.title}
          </Text>
          <Text style={[styles.focalSub, { color: palette.textMuted }]}>
            {personalPlan.unifiedPersonalExam.calibrationSummary}
          </Text>
        </View>
        <ScalePressable
          onPress={() =>
            navigate({
              name: 'liveExam',
              slug: personalPlan.unifiedPersonalExam.slug,
              title: personalPlan.unifiedPersonalExam.title,
              durationMinutes: personalPlan.unifiedPersonalExam.durationMinutes,
              negativeMark: 0,
              isPracticeMode: false,
              questions: personalPlan.personalExamQuestions,
            })
          }
          accessibilityLabel="Launch Unified Personal Exam"
          style={[styles.primaryCta, { backgroundColor: palette.primary }]}
        >
          <Play size={16} color={palette.primaryInk} weight="fill" />
          <Text style={[styles.primaryCtaText, { color: palette.primaryInk }]}>
            Launch My Personal Exam ({personalPlan.unifiedPersonalExam.questionCount} Qs · 1-Tap Lock)
          </Text>
        </ScalePressable>
      </EditorialCard>

      {/* Target Universities Carousel */}
      <View style={styles.sectionHead}>
        <Text style={[styles.sectionTitle, { color: palette.text }]}>
          {strings.yourUniversities}
        </Text>
        <TouchableOpacity
          onPress={() => navigate({ name: 'editProfile', initialStep: 2 })}
          style={styles.textAction}
        >
          <Text style={[styles.linkText, { color: palette.primary }]}>Manage</Text>
        </TouchableOpacity>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.carouselRow}>
          {targets.map(({ uni, discs, daysLeft }, idx) => {
            const selected = idx === selectedIdx;
            return (
              <TouchableOpacity
                key={uni.id}
                onPress={() => setSelectedIdx(idx)}
                accessibilityRole="button"
                accessibilityLabel={`${uni.code}, ${daysLeft} days left`}
                style={[
                  styles.uniCard,
                  {
                    backgroundColor: palette.surface,
                    borderColor: selected ? palette.primary : palette.border,
                  },
                ]}
              >
                <View style={styles.uniTop}>
                  <UniversityLogo code={uni.code} size="md" />
                  <Text style={[styles.daysText, { color: palette.textMuted }]}>
                    {daysLeft}d · 0 neg
                  </Text>
                </View>
                <View>
                  <Text style={[styles.uniCode, { color: palette.text }]}>{uni.code}</Text>
                  <Text
                    style={[styles.uniName, { color: palette.textMuted }]}
                    numberOfLines={1}
                  >
                    {discs[0]?.name}
                  </Text>
                </View>
                <TouchableOpacity
                  onPress={() =>
                    navigate({ name: 'universityDetail', universityCode: uni.code })
                  }
                  style={styles.uniExplore}
                >
                  <Text style={[styles.linkText, { color: palette.primary }]}>
                    Blueprint & Bank
                  </Text>
                  <CaretRight size={14} color={palette.primary} weight="bold" />
                </TouchableOpacity>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      {/* 2-Column Workspace Strip: 360° Knowledge Profile + AETHER AI Engine */}
      <View style={styles.toolGrid}>
        <TouchableOpacity
          onPress={() => navigate({ name: 'knowledgeProfile' })}
          accessibilityRole="button"
          accessibilityLabel="360 Degree Knowledge and Telemetry Profile"
          style={[
            styles.toolCard,
            { backgroundColor: palette.surface, borderColor: palette.border },
          ]}
        >
          <View style={[styles.toolIcon, { backgroundColor: palette.creamTint }]}>
            <Brain size={18} color={palette.primary} weight="duotone" />
          </View>
          <Text style={[styles.toolTitle, { color: palette.text }]}>
            360° Knowledge & Telemetry
          </Text>
          <Text style={[styles.toolSub, { color: palette.textMuted }]}>
            Finger timing · Seriousness {seriousness.seriousnessScore}%
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={() => navigate({ name: 'aiTutor' })}
          accessibilityRole="button"
          accessibilityLabel="AETHER AI Engine"
          style={[
            styles.toolCard,
            { backgroundColor: palette.surface, borderColor: palette.border },
          ]}
        >
          <View style={[styles.toolIcon, { backgroundColor: palette.infoSoft }]}>
            <Robot size={18} color={palette.info} weight="duotone" />
          </View>
          <Text style={[styles.toolTitle, { color: palette.text }]}>
            AETHER AI Engine
          </Text>
          <Text style={[styles.toolSub, { color: palette.textMuted }]}>
            Direct solver · 15s shortcuts
          </Text>
        </TouchableOpacity>
      </View>

      {/* 2-Column Workspace Strip: 1v1 Duel + Mistake Vault */}
      <View style={styles.toolGrid}>
        <TouchableOpacity
          onPress={() => navigate({ name: 'battle' })}
          accessibilityRole="button"
          accessibilityLabel="1v1 Quiz Duel"
          style={[
            styles.toolCard,
            { backgroundColor: palette.surface, borderColor: palette.border },
          ]}
        >
          <View style={[styles.toolIcon, { backgroundColor: palette.creamTint }]}>
            <Sword size={18} color={palette.primary} weight="duotone" />
          </View>
          <Text style={[styles.toolTitle, { color: palette.text }]}>1v1 Quiz Duel</Text>
          <Text style={[styles.toolSub, { color: palette.textMuted }]}>
            5-round 15s sprint
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          onPress={() => navigate({ name: 'mistakeVault' })}
          accessibilityRole="button"
          accessibilityLabel="Mistake Vault"
          style={[
            styles.toolCard,
            { backgroundColor: palette.surface, borderColor: palette.border },
          ]}
        >
          <View style={[styles.toolIcon, { backgroundColor: palette.dangerSoft }]}>
            <ShieldWarning size={18} color={palette.danger} weight="duotone" />
          </View>
          <Text style={[styles.toolTitle, { color: palette.text }]}>Mistake Vault</Text>
          <Text style={[styles.toolSub, { color: palette.textMuted }]}>
            Targeted weak-topic re-test
          </Text>
        </TouchableOpacity>
      </View>

      {/* Daily Ranked Live Test Card */}
      <EditorialCard>
        <View style={styles.rowBetween}>
          <Text
            style={[
              styles.statusText,
              { color: windowStatus.isOpen ? palette.success : palette.primary },
            ]}
          >
            {windowStatus.label}
          </Text>
          <View style={styles.timerRow}>
            <Clock size={14} color={palette.textMuted} weight="bold" />
            <Text style={[styles.timerText, { color: palette.text }]}>
              {windowStatus.countdownText}
            </Text>
          </View>
        </View>

        <Text style={[styles.cardTitle, { color: palette.text }]}>
          Today&apos;s {active.uni.code} Ranked Live Exam
        </Text>
        <Text style={[styles.cardSub, { color: palette.textMuted }]}>
          Daily 10 AM – 10 PM slot · 25 MCQs · Digital or Software OMR Sheet
        </Text>

        <ScalePressable
          onPress={() =>
            navigate({
              name: 'liveExam',
              slug: `daily-${active.uni.code.toLowerCase()}-live`,
              title: `${active.uni.code} Daily Ranked Live Test`,
              durationMinutes: 25,
              negativeMark: 0,
            })
          }
          accessibilityLabel="Enter Daily Exam"
          style={[styles.secondaryBtn, { backgroundColor: PREP404_COLORS.plum }]}
        >
          <Text style={styles.secondaryBtnText}>Enter Daily Exam</Text>
        </ScalePressable>
      </EditorialCard>

      {/* Program Exam Blueprint */}
      <EditorialCard>
        <View style={styles.rowBetween}>
          <Text style={[styles.cardTitle, { color: palette.text, flex: 1 }]}>
            {blueprint.universityCode} · {blueprint.programName}
          </Text>
          <Text style={[styles.metaRight, { color: palette.textMuted }]}>
            {blueprint.sections.reduce((acc, s) => acc + s.marks, 0)} Marks
          </Text>
        </View>

        <View style={styles.barsList}>
          {blueprint.sections.map((sec) => (
            <View key={sec.name} style={styles.barWrap}>
              <View style={styles.barHead}>
                <Text style={[styles.barName, { color: palette.text }]}>{sec.name}</Text>
                <Text style={[styles.barQty, { color: palette.textMuted }]}>
                  {sec.questionCount} Qs · {sec.weightPercent}%
                </Text>
              </View>
              <View style={[styles.barTrack, { backgroundColor: palette.surfaceMuted }]}>
                <View
                  style={[
                    styles.barFill,
                    { width: `${sec.weightPercent}%`, backgroundColor: sec.color },
                  ]}
                />
              </View>
            </View>
          ))}
        </View>
      </EditorialCard>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 32 },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  summaryTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 14,
  },
  summaryCopy: { flex: 1, gap: 3 },
  kickerText: { fontSize: 12, fontWeight: '600' },
  greetingTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 22,
    fontWeight: '800',
    letterSpacing: -0.3,
  },
  summaryMeta: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontVariant: ['tabular-nums'],
    marginTop: 2,
  },
  streakBox: {
    borderTopWidth: 1,
    paddingTop: 12,
    gap: 10,
  },
  streakHeading: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13.5,
    fontWeight: '700',
  },
  streakValue: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  streakRow: { flexDirection: 'row', gap: 6 },
  dayCell: {
    flex: 1,
    borderRadius: 10,
    borderWidth: 1,
    paddingVertical: 7,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 3,
    minHeight: 46,
  },
  dayText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
  },
  focalContent: { gap: 4 },
  focalLabel: { fontSize: 11.5, fontWeight: '700', letterSpacing: 0.2 },
  focalTitle: { fontFamily: TYPE_FONTS.display, fontSize: 17, fontWeight: '700' },
  focalSub: { fontSize: 13, lineHeight: 19 },
  primaryCta: {
    height: 48,
    borderRadius: RADII.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  primaryCtaText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14.5,
    fontWeight: '700',
  },
  sectionHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
  },
  sectionTitle: { fontFamily: TYPE_FONTS.display, fontSize: 16, fontWeight: '700' },
  textAction: { minHeight: 36, justifyContent: 'center', paddingHorizontal: 4 },
  linkText: { fontSize: 12.5, fontWeight: '700' },
  carouselRow: { flexDirection: 'row', gap: 10 },
  uniCard: {
    width: 178,
    borderRadius: RADII.lg,
    borderWidth: 1.5,
    padding: 14,
    gap: 10,
  },
  uniTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 6,
  },
  daysText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  uniCode: { fontFamily: TYPE_FONTS.display, fontSize: 15.5, fontWeight: '800' },
  uniName: { fontSize: 12, marginTop: 2 },
  uniExplore: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
    paddingTop: 2,
    minHeight: 28,
  },
  toolGrid: { flexDirection: 'row', gap: 10 },
  toolCard: {
    flex: 1,
    borderRadius: RADII.lg,
    borderWidth: 1,
    padding: 14,
    gap: 6,
    minHeight: 104,
  },
  toolIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  toolTitle: { fontFamily: TYPE_FONTS.display, fontSize: 14, fontWeight: '700' },
  toolSub: { fontSize: 12 },
  statusText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  timerRow: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  timerText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  cardTitle: { fontFamily: TYPE_FONTS.display, fontSize: 16, fontWeight: '700' },
  cardSub: { fontSize: 13, lineHeight: 19 },
  secondaryBtn: {
    borderRadius: RADII.md,
    height: 46,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  secondaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  metaRight: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  barsList: { gap: 10 },
  barWrap: { gap: 5 },
  barHead: { flexDirection: 'row', justifyContent: 'space-between', gap: 8 },
  barName: { fontSize: 13, fontWeight: '600', flex: 1 },
  barQty: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  barTrack: { height: 7, borderRadius: 4, overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 4 },
});

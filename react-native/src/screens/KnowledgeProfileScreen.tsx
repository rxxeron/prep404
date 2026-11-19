import React, { useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CaretDown,
  CaretUp,
  CheckCircle,
  Clock,
  LockKey,
  Play,
  Sparkle,
  Warning,
  WarningOctagon,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { PHASE_1_UNIVERSITY_CODES } from '../data/universities';
import {
  buildSubjectRadarData,
  computeLearnerKnowledgeProfile,
  computeUniversityReadiness,
  getQuadrantMetadata,
} from '../services/knowledgeProfileService';
import { computeCandidateSeriousnessProfile } from '../services/telemetryService';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import { SpeedAccuracyQuadrant, TopicMasteryNode } from '../types';
import {
  EditorialCard,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';
import { ProgressRing } from '../components/ProgressRing';
import { UniversityLogo } from '../components/UniversityLogo';
import { KnowledgeRadarChart } from '../components/KnowledgeRadarChart';

interface KnowledgeProfileScreenProps {
  initialUniversityCode?: string;
  initialSubjectId?: string;
  embedded?: boolean;
}

export const KnowledgeProfileScreen: React.FC<KnowledgeProfileScreenProps> = ({
  initialUniversityCode,
  initialSubjectId,
  embedded = false,
}) => {
  const { profile, palette, navigate } = useApp();

  const knowledge = useMemo(() => computeLearnerKnowledgeProfile(), []);
  const seriousness = useMemo(() => computeCandidateSeriousnessProfile(), []);

  const defaultUni = useMemo(() => {
    if (initialUniversityCode) {
      const up = initialUniversityCode.toUpperCase();
      if (up === 'BRAC') return 'BRACU';
      if ((PHASE_1_UNIVERSITY_CODES as readonly string[]).includes(up)) return up;
    }
    const keys = Object.keys(profile?.targetSelections || {});
    if (keys.length > 0) {
      const first = keys[0].toUpperCase();
      if (first === 'BRAC') return 'BRACU';
      if ((PHASE_1_UNIVERSITY_CODES as readonly string[]).includes(first)) {
        return first;
      }
    }
    return 'BRACU';
  }, [initialUniversityCode, profile]);

  const [selectedUni, setSelectedUni] = useState<string>(defaultUni);
  const [expandedSubjectId, setExpandedSubjectId] = useState<string>(
    initialSubjectId || 'higher_math'
  );
  const [quadrantFilter, setQuadrantFilter] = useState<
    'all' | SpeedAccuracyQuadrant
  >('all');

  const masteryBoost = 0;
  const simulatedSubjects = knowledge.subjects;
  const simulatedTopics = knowledge.topics;

  const activeProjection = useMemo(
    () =>
      computeUniversityReadiness(selectedUni, simulatedSubjects, simulatedTopics),
    [selectedUni, simulatedSubjects, simulatedTopics]
  );

  const radarData = useMemo(
    () => buildSubjectRadarData(simulatedSubjects, selectedUni),
    [simulatedSubjects, selectedUni]
  );

  const filteredTopics = useMemo(() => {
    const byUni = simulatedTopics.filter((t) =>
      t.universityRelevance.includes(selectedUni)
    );
    const pool = byUni.length > 0 ? byUni : simulatedTopics;
    if (quadrantFilter === 'all') return pool;
    return pool.filter((t) => t.quadrant === quadrantFilter);
  }, [simulatedTopics, selectedUni, quadrantFilter]);

  const quadrantCounts = useMemo(() => {
    const counts = {
      mastered_fast: 0,
      accurate_slow: 0,
      rushed_costly: 0,
      critical_deficit: 0,
    };
    for (const t of simulatedTopics) {
      counts[t.quadrant] += 1;
    }
    return counts;
  }, [simulatedTopics]);

  const renderTopicActionRow = (topic: TopicMasteryNode) => {
    const quadMeta = getQuadrantMetadata(topic.quadrant);
    const toneColor =
      quadMeta.tone === 'success'
        ? palette.success
        : quadMeta.tone === 'warning'
          ? palette.amber
          : quadMeta.tone === 'danger'
            ? palette.danger
            : palette.info;

    return (
      <View
        key={topic.topicId}
        style={[styles.topicBlock, { borderTopColor: palette.border }]}
      >
        <View style={styles.rowBetween}>
          <Text style={[styles.topicTitle, { color: palette.text, flex: 1 }]}>
            {topic.topicName}
          </Text>
          <Text style={[styles.quadStatusText, { color: toneColor }]}>
            {quadMeta.label}
          </Text>
        </View>

        <Text style={[styles.topicMetaMono, { color: palette.textMuted }]}>
          Mastery {topic.masteryScore}% · Acc {topic.accuracyPercent}% · FSRS R={topic.fsrsRetrievability}% (S={topic.fsrsStabilityDays}d) · {topic.avgTimeSeconds}s/{topic.targetTimeSeconds}s · 0 Neg
        </Text>

        {/* Dual Progress Bar: Topic Mastery + FSRS Memory Curve */}
        <View style={styles.dualBarGroup}>
          <View style={styles.barRow}>
            <Text style={[styles.barLabelMono, { color: palette.textSubtle }]}>
              MASTERY
            </Text>
            <View
              style={[styles.barTrack, { backgroundColor: palette.surfaceMuted }]}
            >
              <View
                style={[
                  styles.barFill,
                  {
                    width: `${topic.masteryScore}%`,
                    backgroundColor: toneColor,
                  },
                ]}
              />
            </View>
            <Text style={[styles.barPctMono, { color: palette.text }]}>
              {topic.masteryScore}%
            </Text>
          </View>

          <View style={styles.barRow}>
            <Text style={[styles.barLabelMono, { color: palette.textSubtle }]}>
              FSRS MEM
            </Text>
            <View
              style={[styles.barTrack, { backgroundColor: palette.surfaceMuted }]}
            >
              <View
                style={[
                  styles.barFill,
                  {
                    width: `${topic.fsrsRetrievability}%`,
                    backgroundColor: palette.primary,
                  },
                ]}
              />
            </View>
            <Text style={[styles.barPctMono, { color: palette.text }]}>
              {topic.fsrsRetrievability}%
            </Text>
          </View>
        </View>

        <Text style={[styles.prescriptionText, { color: palette.textMuted }]}>
          {quadMeta.prescription}
        </Text>

        <View style={styles.topicActionBtns}>
          <TouchableOpacity
            onPress={() =>
              navigate({
                name: 'practice',
                subjectId: topic.subjectId,
                topicId: topic.topicId,
                title: `${topic.topicName} Drill`,
              })
            }
            accessibilityRole="button"
            accessibilityLabel={`Practice ${topic.topicName}`}
            style={[
              styles.smallBtn,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.borderStrong,
              },
            ]}
          >
            <Play size={13} color={palette.text} weight="fill" />
            <Text style={[styles.smallBtnText, { color: palette.text }]}>
              Practice ({topic.dueCardCount} due)
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() =>
              navigate({
                name: 'aiTutor',
                topicId: topic.topicId,
                subjectId: topic.subjectId,
                initialMode:
                  topic.quadrant === 'rushed_costly' ||
                  topic.quadrant === 'critical_deficit'
                    ? 'mistake_diagnosis'
                    : 'aether_solver',
              })
            }
            accessibilityRole="button"
            accessibilityLabel={`Ask AETHER AI about ${topic.topicName}`}
            style={[
              styles.smallBtn,
              {
                backgroundColor: PREP404_COLORS.plum,
                borderColor: PREP404_COLORS.plum,
              },
            ]}
          >
            <Sparkle size={13} color="#FFFFFF" weight="fill" />
            <Text style={[styles.smallBtnText, { color: '#FFFFFF' }]}>
              Ask AETHER AI
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  const content = (
    <View style={embedded ? styles.embeddedWrap : styles.container}>
      {/* Top 360° Mastery & FSRS Memory Overview */}
      <EditorialCard>
        <View style={styles.heroRow}>
          <View style={{ flex: 1, gap: 4 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              360° LEARNER KNOWLEDGE PROFILE · {knowledge.leagueTier.greekSymbol}{' '}
              {knowledge.leagueTier.name.toUpperCase()}
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              {profile?.name || 'Tanvir Ahmed'} · Subject & Topic Mastery
            </Text>
            <Text style={[styles.subMetaMono, { color: palette.textMuted }]}>
              FSRS Retention {knowledge.overallRetrievabilityPercent}% ·{' '}
              {knowledge.dueCardsTotal} Due Today · Avg {knowledge.avgSolveSpeedSeconds}s/Q · Seriousness {seriousness.seriousnessScore}%
            </Text>
          </View>
          <ProgressRing
            percent={Math.min(100, knowledge.overallMasteryPercent + masteryBoost)}
            size={78}
            strokeWidth={7}
            color={palette.primary}
            trackColor={palette.border}
            textColor={palette.text}
            labelColor={palette.textMuted}
            label="Mastery"
          />
        </View>

        <View style={[styles.kpiStrip, { borderTopColor: palette.border }]}>
          <View style={styles.kpiCell}>
            <Text style={[styles.kpiLabel, { color: palette.textMuted }]}>
              FSRS Recall
            </Text>
            <Text style={[styles.kpiVal, { color: palette.success }]}>
              {knowledge.overallRetrievabilityPercent}%
            </Text>
          </View>
          <View style={styles.kpiCell}>
            <Text style={[styles.kpiLabel, { color: palette.textMuted }]}>
              Solve Pace
            </Text>
            <Text style={[styles.kpiVal, { color: palette.info }]}>
              {knowledge.avgSolveSpeedSeconds}s/Q
            </Text>
          </View>
          <View style={styles.kpiCell}>
            <Text style={[styles.kpiLabel, { color: palette.textMuted }]}>
              Seriousness
            </Text>
            <Text style={[styles.kpiVal, { color: palette.primary }]}>
              {seriousness.seriousnessScore}%
            </Text>
          </View>
          <View style={styles.kpiCell}>
            <Text style={[styles.kpiLabel, { color: palette.textMuted }]}>
              Due Cards
            </Text>
            <Text style={[styles.kpiVal, { color: palette.amber }]}>
              {knowledge.dueCardsTotal}
            </Text>
          </View>
        </View>
      </EditorialCard>

      {/* How AETHER AI Evaluates You — Finger & Phone Usage Telemetry */}
      <View style={styles.sectionHeaderRow}>
        <Text style={[styles.sectionHeading, { color: palette.text }]}>
          00. How AETHER AI Evaluates You (Live Telemetry)
        </Text>
        <Text style={[styles.sectionRightMono, { color: palette.primary }]}>
          FINGER + APP USAGE
        </Text>
      </View>

      <EditorialCard highlighted>
        <View style={styles.rowBetween}>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              CANDIDATE SERIOUSNESS & FINGER TIMING ENGINE
            </Text>
            <Text style={[styles.cardTitle, { color: palette.text }]}>
              {seriousness.statusLabel} ({seriousness.seriousnessScore}%)
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              Every answer locks permanently on first tap. AETHER AI tracks Read → Think → Answer Lock timing and phone focus.
            </Text>
          </View>
          <ProgressRing
            percent={seriousness.seriousnessScore}
            size={68}
            strokeWidth={6}
            color={
              seriousness.seriousnessScore >= 80
                ? palette.success
                : seriousness.seriousnessScore >= 60
                  ? palette.amber
                  : palette.danger
            }
            trackColor={palette.border}
            textColor={palette.text}
            labelColor={palette.textMuted}
            label="Focus"
          />
        </View>

        <View
          style={[
            styles.cutOffComparisonBox,
            { backgroundColor: palette.surfaceMuted, borderColor: palette.border },
          ]}
        >
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Avg Read
            </Text>
            <Text style={[styles.cutOffNum, { color: palette.text }]}>
              {seriousness.avgReadSeconds}s
            </Text>
          </View>
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Avg Think
            </Text>
            <Text style={[styles.cutOffNum, { color: palette.primary }]}>
              {seriousness.avgThinkSeconds}s
            </Text>
          </View>
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Impulse Locks
            </Text>
            <Text
              style={[
                styles.cutOffNum,
                {
                  color:
                    seriousness.impulseGuessRatePercent > 15
                      ? palette.danger
                      : palette.success,
                },
              ]}
            >
              {seriousness.impulseGuessRatePercent}%
            </Text>
          </View>
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              App Switches
            </Text>
            <Text style={[styles.cutOffNum, { color: palette.amber }]}>
              {seriousness.appSwitchInterrupts} ({seriousness.activeFocusMinutes}m)
            </Text>
          </View>
        </View>

        <View style={{ gap: 6 }}>
          {seriousness.evaluationNotes.map((note, idx) => (
            <Text
              key={`eval_note_${idx}`}
              style={[styles.prescriptionText, { color: palette.text }]}
            >
              • {note}
            </Text>
          ))}
        </View>

        {seriousness.recentTelemetry.length > 0 && (
          <View style={[styles.blockingBox, { borderTopColor: palette.border }]}>
            <Text style={[styles.kicker, { color: palette.textMuted }]}>
              RECENT PERMANENT ANSWER LOCKS (READ → THINK → LOCK)
            </Text>
            {seriousness.recentTelemetry.slice(0, 4).map((ev) => (
              <View key={ev.eventId} style={styles.blockingRow}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5, flex: 1 }}>
                  <LockKey
                    size={13}
                    color={
                      ev.behaviorClass === 'impulse_guess'
                        ? palette.danger
                        : palette.primary
                    }
                    weight="fill"
                  />
                  <Text
                    style={[styles.blockingTitle, { color: palette.text, flex: 1 }]}
                    numberOfLines={1}
                  >
                    {ev.questionId.toUpperCase()} · Opt {ev.selectedOptionId} (
                    {ev.isCorrect ? 'Right' : 'Wrong'})
                  </Text>
                </View>
                <Text
                  style={[
                    styles.blockingMono,
                    {
                      color:
                        ev.behaviorClass === 'impulse_guess'
                          ? palette.danger
                          : palette.textMuted,
                    },
                  ]}
                >
                  R {(ev.readTimeMs / 1000).toFixed(1)}s · T {(ev.thinkTimeMs / 1000).toFixed(1)}s ·{' '}
                  {ev.behaviorClass === 'impulse_guess' ? 'IMPULSE' : 'DELIBERATE'}
                </Text>
              </View>
            ))}
          </View>
        )}
      </EditorialCard>

      {/* Layer 1: Target University Cut-Off Probability & Gap Analysis (All 7 Phase 1 Universities) */}
      <View style={styles.sectionHeaderRow}>
        <Text style={[styles.sectionHeading, { color: palette.text }]}>
          01. Target University Cut-Off & Gap Analysis
        </Text>
        <Text style={[styles.sectionRightMono, { color: palette.textMuted }]}>
          PHASE 1 COHORT (7 UNIS · 0 NEG)
        </Text>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.uniSwitchRow}>
          {PHASE_1_UNIVERSITY_CODES.map((code) => {
            const active = selectedUni === code;
            const proj = computeUniversityReadiness(
              code,
              simulatedSubjects,
              simulatedTopics
            );
            const clears = proj.gapMarks >= 0;
            return (
              <TouchableOpacity
                key={code}
                onPress={() => setSelectedUni(code)}
                accessibilityRole="button"
                accessibilityLabel={`Inspect ${code} Cut-off Projection`}
                style={[
                  styles.uniPillBtn,
                  {
                    backgroundColor: active ? palette.text : palette.surface,
                    borderColor: active ? palette.text : palette.borderStrong,
                  },
                ]}
              >
                <UniversityLogo code={code} size="sm" />
                <View>
                  <Text
                    style={[
                      styles.uniPillCode,
                      { color: active ? palette.bg : palette.text },
                    ]}
                  >
                    {code}
                  </Text>
                  <Text
                    style={[
                      styles.uniPillGapMono,
                      {
                        color: active
                          ? palette.primary
                          : clears
                            ? palette.success
                            : palette.danger,
                      },
                    ]}
                  >
                    {proj.gapMarks >= 0
                      ? `+${proj.gapMarks}m`
                      : `${proj.gapMarks}m`}
                  </Text>
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </ScrollView>

      <EditorialCard>
        <View style={styles.rowBetween}>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              {activeProjection.universityCode} ADMISSION READINESS · ZERO NEGATIVE MARKING (0.00)
            </Text>
            <Text style={[styles.cardTitle, { color: palette.text }]}>
              {activeProjection.universityName}
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              {activeProjection.programName}
            </Text>
          </View>
          <ProgressRing
            percent={activeProjection.admissionProbabilityPercent}
            size={72}
            strokeWidth={6}
            color={
              activeProjection.gapMarks >= 0 ? palette.success : palette.amber
            }
            trackColor={palette.border}
            textColor={palette.text}
            labelColor={palette.textMuted}
            label="Chance"
          />
        </View>

        <View
          style={[
            styles.cutOffComparisonBox,
            {
              backgroundColor: palette.surfaceMuted,
              borderColor: palette.border,
            },
          ]}
        >
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Projected Score
            </Text>
            <Text style={[styles.cutOffNum, { color: palette.text }]}>
              {activeProjection.projectedScore}/{activeProjection.totalMarks}
            </Text>
          </View>
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Target Cut-Off ({activeProjection.cutOffPercent}%)
            </Text>
            <Text style={[styles.cutOffNum, { color: palette.primary }]}>
              {activeProjection.cutOffScore}/{activeProjection.totalMarks}
            </Text>
          </View>
          <View style={styles.cutOffCol}>
            <Text style={[styles.cutOffLabel, { color: palette.textMuted }]}>
              Net Cut-Off Gap
            </Text>
            <Text
              style={[
                styles.cutOffNum,
                {
                  color:
                    activeProjection.gapMarks >= 0
                      ? palette.success
                      : palette.danger,
                },
              ]}
            >
              {activeProjection.gapMarks >= 0
                ? `+${activeProjection.gapMarks}`
                : activeProjection.gapMarks}{' '}
              Marks
            </Text>
          </View>
        </View>

        {/* Real User Data Pipeline & AI Training Status */}
        <View style={[styles.blockingBox, { borderTopColor: palette.border }]}>
          <Text style={[styles.kicker, { color: palette.primary }]}>
            LIVE USER TELEMETRY → AETHER AI TRAINING PIPELINE (ZERO SIMULATED DATA)
          </Text>
          <Text style={[styles.prescriptionText, { color: palette.textMuted }]}>
            {knowledge.totalAttempts === 0 && seriousness.lockedAnswersCount === 0
              ? '0 questions locked so far. All scores start at 0 and build strictly from your real Practice, 1v1 Duel, and Exam locks.'
              : `Pipeline active: ${seriousness.lockedAnswersCount} permanent answer locks and ${knowledge.totalAttempts} topic attempts ingested into your personal mastery vector and JSONL training corpus.`}
          </Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
            <TouchableOpacity
              onPress={() =>
                navigate({
                  name: 'practice',
                  subjectId: activeProjection.topBlockingTopics[0]?.subjectId || 'higher_math',
                  topicId: activeProjection.topBlockingTopics[0]?.topicId || 'calculus_limits',
                  title: 'AETHER AI Calibration Drill',
                })
              }
              accessibilityRole="button"
              accessibilityLabel="Launch Live Calibration Drill"
              style={[
                styles.smallBtn,
                {
                  backgroundColor: palette.creamTint,
                  borderColor: palette.primary,
                },
              ]}
            >
              <Play size={13} color={palette.primary} weight="fill" />
              <Text style={[styles.smallBtnText, { color: palette.primary }]}>
                Lock Real Answers in Practice ({seriousness.lockedAnswersCount} Locked)
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              onPress={() => navigate({ name: 'serverGateway' })}
              accessibilityRole="button"
              accessibilityLabel="Inspect Server Pipeline and JSONL Training Corpus"
              style={[
                styles.smallBtn,
                {
                  backgroundColor: palette.surfaceMuted,
                  borderColor: palette.borderStrong,
                },
              ]}
            >
              <Sparkle size={13} color={palette.text} weight="fill" />
              <Text style={[styles.smallBtnText, { color: palette.text }]}>
                Server Pipeline & Training Corpus →
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Section-by-Section Readiness */}
        <View style={{ gap: 8 }}>
          {activeProjection.sectionReadiness.map((sec) => (
            <View key={sec.name} style={{ gap: 4 }}>
              <View style={styles.rowBetween}>
                <Text style={[styles.secName, { color: palette.text }]}>
                  {sec.name}
                </Text>
                <Text style={[styles.secMono, { color: palette.textMuted }]}>
                  Proj {sec.projectedMarks}/{sec.maxMarks} ({sec.masteryPercent}%)
                </Text>
              </View>
              <View
                style={[styles.barTrack, { backgroundColor: palette.surfaceMuted }]}
              >
                <View
                  style={[
                    styles.barFill,
                    {
                      width: `${sec.masteryPercent}%`,
                      backgroundColor: sec.color,
                    },
                  ]}
                />
              </View>
            </View>
          ))}
        </View>

        {/* Top Blocking Topics to Clear Cut-off */}
        <View
          style={[
            styles.blockingBox,
            { borderTopColor: palette.border },
          ]}
        >
          <Text style={[styles.kicker, { color: palette.textMuted }]}>
            PRIORITY CHAPTERS TO CLEAR {activeProjection.universityCode} CUT-OFF
          </Text>
          {activeProjection.topBlockingTopics.map((bt, idx) => (
            <View key={bt.topicId} style={styles.blockingRow}>
              <Text style={[styles.blockingTitle, { color: palette.text, flex: 1 }]}>
                0{idx + 1}. {bt.topicName} ({bt.subjectName})
              </Text>
              <Text style={[styles.blockingMono, { color: palette.danger }]}>
                {bt.masteryScore}% Mastery · {bt.avgTimeSeconds}s/Q
              </Text>
            </View>
          ))}

          <View style={styles.dualCtaRow}>
            <ScalePressable
              onPress={() =>
                navigate({
                  name: 'aiTutor',
                  initialMode: 'study_planner',
                  topicId: activeProjection.topBlockingTopics[0]?.topicId,
                })
              }
              accessibilityLabel={`Generate AETHER AI Gap Plan for ${activeProjection.universityCode}`}
              style={[
                styles.primaryBtn,
                { backgroundColor: palette.primary, flex: 1 },
              ]}
            >
              <Sparkle size={16} color={palette.primaryInk} weight="fill" />
              <Text
                style={[styles.primaryBtnText, { color: palette.primaryInk }]}
              >
                AETHER AI Cut-Off Gap Plan ({activeProjection.universityCode})
              </Text>
            </ScalePressable>
          </View>
        </View>
      </EditorialCard>

      {/* Layer 2: Subject & Topic Mastery Radar + FSRS Memory Curves */}
      <View style={styles.sectionHeaderRow}>
        <Text style={[styles.sectionHeading, { color: palette.text }]}>
          02. Subject & Topic Mastery Radar + FSRS Curves
        </Text>
        <Text style={[styles.sectionRightMono, { color: palette.textMuted }]}>
          PURE RN SVG SPIDER-WEB
        </Text>
      </View>

      <KnowledgeRadarChart
        data={radarData}
        universityCode={selectedUni}
      />

      {simulatedSubjects.map((subject) => {
        const isExpanded = expandedSubjectId === subject.subjectId;
        const statusColor =
          subject.status === 'mastered'
            ? palette.success
            : subject.status === 'on_track'
              ? palette.info
              : subject.status === 'at_risk'
                ? palette.amber
                : palette.danger;
        const statusLabel =
          subject.status === 'mastered'
            ? '● MASTERED'
            : subject.status === 'on_track'
              ? '● ON TRACK'
              : subject.status === 'at_risk'
                ? '▲ AT RISK'
                : '■ CRITICAL';

        return (
          <EditorialCard key={subject.subjectId}>
            <TouchableOpacity
              onPress={() =>
                setExpandedSubjectId((prev) =>
                  prev === subject.subjectId ? '' : subject.subjectId
                )
              }
              accessibilityRole="button"
              accessibilityLabel={`${subject.subjectName}, Mastery ${subject.masteryPercent}%`}
              style={styles.subjectHeaderTouch}
            >
              <View style={{ flex: 1, gap: 4 }}>
                <View style={styles.rowBetween}>
                  <Text style={[styles.cardTitle, { color: palette.text }]}>
                    {subject.subjectName}
                  </Text>
                  <Text style={[styles.quadStatusText, { color: statusColor }]}>
                    {statusLabel}
                  </Text>
                </View>
                <Text style={[styles.subMetaMono, { color: palette.textMuted }]}>
                  Mastery {subject.masteryPercent}% · FSRS Retention {subject.retentionPercent}% · Avg {subject.avgTimeSeconds}s/Q · 0 Neg
                </Text>
                <View
                  style={[
                    styles.barTrack,
                    { backgroundColor: palette.surfaceMuted, marginTop: 4 },
                  ]}
                >
                  <View
                    style={[
                      styles.barFill,
                      {
                        width: `${subject.masteryPercent}%`,
                        backgroundColor: statusColor,
                      },
                    ]}
                  />
                </View>
              </View>
              <View style={styles.chevronBox}>
                {isExpanded ? (
                  <CaretUp size={18} color={palette.textMuted} weight="bold" />
                ) : (
                  <CaretDown size={18} color={palette.textMuted} weight="bold" />
                )}
              </View>
            </TouchableOpacity>

            {isExpanded && (
              <View style={styles.topicsListWrap}>
                {subject.topics.map((topic) => renderTopicActionRow(topic))}
              </View>
            )}
          </EditorialCard>
        );
      })}

      {/* Layer 3: Speed vs. Accuracy & Impulse Lock Diagnostic Matrix */}
      <View style={styles.sectionHeaderRow}>
        <Text style={[styles.sectionHeading, { color: palette.text }]}>
          03. Speed vs. Accuracy & Impulse Lock Matrix
        </Text>
      </View>

      <EditorialCard>
        <View style={styles.quadSummaryGrid}>
          <TouchableOpacity
            onPress={() => setQuadrantFilter('rushed_costly')}
            style={[
              styles.quadMetricBox,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor:
                  quadrantFilter === 'rushed_costly'
                    ? palette.amber
                    : palette.border,
              },
            ]}
          >
            <Warning size={16} color={palette.amber} weight="fill" />
            <Text style={[styles.quadCountMono, { color: palette.amber }]}>
              {quadrantCounts.rushed_costly} Topics
            </Text>
            <Text style={[styles.quadBoxTitle, { color: palette.text }]}>
              Impulse Lock (&lt;2.5s)
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setQuadrantFilter('accurate_slow')}
            style={[
              styles.quadMetricBox,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor:
                  quadrantFilter === 'accurate_slow'
                    ? palette.info
                    : palette.border,
              },
            ]}
          >
            <Clock size={16} color={palette.info} weight="fill" />
            <Text style={[styles.quadCountMono, { color: palette.info }]}>
              {quadrantCounts.accurate_slow} Topics
            </Text>
            <Text style={[styles.quadBoxTitle, { color: palette.text }]}>
              Accurate · Slow Pace
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setQuadrantFilter('critical_deficit')}
            style={[
              styles.quadMetricBox,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor:
                  quadrantFilter === 'critical_deficit'
                    ? palette.danger
                    : palette.border,
              },
            ]}
          >
            <WarningOctagon size={16} color={palette.danger} weight="fill" />
            <Text style={[styles.quadCountMono, { color: palette.danger }]}>
              {quadrantCounts.critical_deficit} Topics
            </Text>
            <Text style={[styles.quadBoxTitle, { color: palette.text }]}>
              Critical Deficit
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setQuadrantFilter('mastered_fast')}
            style={[
              styles.quadMetricBox,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor:
                  quadrantFilter === 'mastered_fast'
                    ? palette.success
                    : palette.border,
              },
            ]}
          >
            <CheckCircle size={16} color={palette.success} weight="fill" />
            <Text style={[styles.quadCountMono, { color: palette.success }]}>
              {quadrantCounts.mastered_fast} Topics
            </Text>
            <Text style={[styles.quadBoxTitle, { color: palette.text }]}>
              Mastered & Fast
            </Text>
          </TouchableOpacity>
        </View>

        <SegmentedControl<'all' | SpeedAccuracyQuadrant>
          value={quadrantFilter}
          onChange={setQuadrantFilter}
          options={[
            { id: 'all', label: 'All' },
            { id: 'rushed_costly', label: 'Impulse' },
            { id: 'accurate_slow', label: 'Slow' },
            { id: 'critical_deficit', label: 'Deficit' },
            { id: 'mastered_fast', label: 'Mastered' },
          ]}
        />

        <View style={{ gap: 4 }}>
          {filteredTopics.length === 0 ? (
            <Text style={[styles.emptyFilterText, { color: palette.textMuted }]}>
              No topics in this diagnostic quadrant for {selectedUni}.
            </Text>
          ) : (
            filteredTopics.map((topic) => renderTopicActionRow(topic))
          )}
        </View>
      </EditorialCard>
    </View>
  );

  if (embedded) {
    return content;
  }

  return (
    <ScrollView
      contentContainerStyle={styles.scrollOuter}
      showsVerticalScrollIndicator={false}
    >
      {content}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollOuter: { paddingBottom: 36 },
  container: { padding: 16, gap: 14 },
  embeddedWrap: { gap: 14 },
  heroRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  kicker: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 0.4,
  },
  title: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 19,
    fontWeight: '800',
  },
  cardTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 16,
    fontWeight: '700',
  },
  subText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
  },
  subMetaMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontVariant: ['tabular-nums'],
  },
  kpiStrip: {
    flexDirection: 'row',
    borderTopWidth: 1,
    paddingTop: 12,
    marginTop: 4,
    gap: 8,
  },
  kpiCell: { flex: 1, gap: 2 },
  kpiLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 11.5,
    fontWeight: '600',
  },
  kpiVal: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 16,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
  },
  sectionHeading: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 15.5,
    fontWeight: '800',
  },
  sectionRightMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10.5,
    fontWeight: '700',
  },
  uniSwitchRow: {
    flexDirection: 'row',
    gap: 8,
    paddingVertical: 2,
  },
  uniPillBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: RADII.md,
    borderWidth: 1.5,
    minHeight: 46,
  },
  uniPillCode: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13.5,
    fontWeight: '800',
  },
  uniPillGapMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  cutOffComparisonBox: {
    flexDirection: 'row',
    borderRadius: RADII.md,
    borderWidth: 1,
    padding: 12,
    gap: 10,
  },
  cutOffCol: { flex: 1, gap: 3 },
  cutOffLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 11.5,
    fontWeight: '600',
  },
  cutOffNum: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 15.5,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  negImpactNote: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
  },
  secName: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    fontWeight: '600',
    flex: 1,
  },
  secMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  barTrack: {
    flex: 1,
    height: 7,
    borderRadius: 4,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    borderRadius: 4,
  },
  blockingBox: {
    borderTopWidth: 1,
    paddingTop: 12,
    gap: 8,
  },
  blockingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  blockingTitle: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    fontWeight: '700',
  },
  blockingMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  dualCtaRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 4,
  },
  primaryBtn: {
    height: 46,
    borderRadius: RADII.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingHorizontal: 14,
  },
  primaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13.5,
    fontWeight: '700',
  },
  subjectHeaderTouch: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  chevronBox: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  topicsListWrap: {
    marginTop: 4,
    gap: 4,
  },
  topicBlock: {
    borderTopWidth: 1,
    paddingTop: 12,
    paddingBottom: 6,
    gap: 7,
  },
  topicTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 14,
    fontWeight: '700',
  },
  quadStatusText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10.5,
    fontWeight: '700',
  },
  topicMetaMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontVariant: ['tabular-nums'],
  },
  dualBarGroup: {
    gap: 5,
  },
  barRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  barLabelMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10,
    fontWeight: '700',
    width: 58,
  },
  barPctMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '700',
    width: 34,
    textAlign: 'right',
    fontVariant: ['tabular-nums'],
  },
  prescriptionText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    lineHeight: 17,
  },
  topicActionBtns: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 2,
  },
  smallBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    minHeight: 38,
    borderRadius: RADII.sm,
    borderWidth: 1,
  },
  smallBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 12,
    fontWeight: '700',
  },
  quadSummaryGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  quadMetricBox: {
    width: '48.2%',
    borderRadius: RADII.md,
    borderWidth: 1.5,
    padding: 12,
    gap: 3,
  },
  quadCountMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 16,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  quadBoxTitle: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '700',
  },
  emptyFilterText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    textAlign: 'center',
    paddingVertical: 14,
  },
});

import React, { useEffect, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CheckCircle,
  LockKey,
  Sword,
  Trophy,
  WifiSlash,
  XCircle,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { pickQuestionsForExam } from '../data/questionBank';
import { shuffleQuestionOptions } from '../services/examService';
import { storageService } from '../services/storageService';
import { extractTouchPoint } from '../services/dataLoggingService';
import {
  lockQuestionAnswerTelemetry,
  recordQuestionFingerActivity,
  startQuestionTelemetry,
} from '../services/telemetryService';
import { BattlePhase, Question, QuestionTimingTelemetry } from '../types';
import { RADII, TYPE_FONTS } from '../theme/colors';
import { MathText } from '../components/MathText';
import { useNetworkStatus } from '../utils/useNetworkStatus';
import {
  EditorialCard,
  HairlineRow,
  ScalePressable,
} from '../components/DesignPrimitives';

const BOTS = [
  { name: 'Prep404 Speed Bot α', college: 'Notre Dame Dhaka' },
  { name: 'Prep404 Quant Bot β', college: 'Viqarunnisa Noon' },
];

export const BattleArenaScreen: React.FC = () => {
  const { profile, palette, showToast } = useApp();
  const [phase, setPhase] = useState<BattlePhase>('idle');
  const [track, setTrack] = useState('BRACU');
  const [roomCode, setRoomCode] = useState('P404X8');
  const [joinCode, setJoinCode] = useState('');
  const [questions, setQuestions] = useState<Question[]>([]);
  const [roundIdx, setRoundIdx] = useState(0);
  const [timer, setTimer] = useState(15);
  const [myScore, setMyScore] = useState(0);
  const [botScore, setBotScore] = useState(0);
  const [myPick, setMyPick] = useState<string | null>(null);
  const [roundTelemetry, setRoundTelemetry] =
    useState<QuestionTimingTelemetry | null>(null);
  const [botDone, setBotDone] = useState(false);
  const [revealed, setRevealed] = useState(false);
  const [opponent, setOpponent] = useState(BOTS[0]);
  const [history, setHistory] = useState(() => storageService.getBattleHistory());
  const isOnline = useNetworkStatus();

  const activeQ = questions[roundIdx];

  useEffect(() => {
    if (phase === 'playing' && activeQ) {
      startQuestionTelemetry({
        questionId: activeQ.id,
        questionText: activeQ.text,
        topicId: activeQ.topicId,
        subjectName: activeQ.subjectName,
        universityCode: track,
        sourceScreen: 'duel_1v1',
      });
      setRoundTelemetry(null);
    }
  }, [phase, activeQ?.id, roundIdx]);

  useEffect(() => {
    if (phase !== 'playing' || revealed) return;
    const tId = setInterval(() => {
      setTimer((p) => {
        if (p <= 1) {
          setRevealed(true);
          return 0;
        }
        return p - 1;
      });
    }, 1000);
    const botId = setTimeout(() => {
      if (!botDone) {
        setBotDone(true);
        if (Math.random() < 0.72) setBotScore((s) => s + 115);
      }
    }, 3200);
    return () => {
      clearInterval(tId);
      clearTimeout(botId);
    };
  }, [phase, revealed, roundIdx, botDone]);

  useEffect(() => {
    if (phase === 'playing' && myPick && botDone && !revealed) {
      const id = setTimeout(() => setRevealed(true), 400);
      return () => clearTimeout(id);
    }
  }, [phase, myPick, botDone, revealed]);

  const startDuel = (code?: string) => {
    setQuestions(pickQuestionsForExam(track, 5).map(shuffleQuestionOptions));
    setOpponent(BOTS[Math.floor(Math.random() * BOTS.length)]);
    if (code) setRoomCode(code);
    setRoundIdx(0);
    setTimer(15);
    setMyScore(0);
    setBotScore(0);
    setMyPick(null);
    setRoundTelemetry(null);
    setBotDone(false);
    setRevealed(false);
    setPhase('playing');
  };

  const nextRound = () => {
    if (roundIdx < questions.length - 1) {
      setRoundIdx((i) => i + 1);
      setTimer(15);
      setMyPick(null);
      setRoundTelemetry(null);
      setBotDone(false);
      setRevealed(false);
    } else {
      const outcome =
        myScore > botScore ? 'victory' : myScore < botScore ? 'defeat' : 'draw';
      storageService.addBattleHistory({
        id: `btl_${Date.now()}`,
        roomCode,
        track,
        opponentName: opponent.name,
        opponentCollege: opponent.college,
        yourScore: myScore,
        opponentScore: botScore,
        outcome,
        xpEarned: outcome === 'victory' ? 150 : 60,
        createdAt: new Date().toISOString(),
      });
      setHistory(storageService.getBattleHistory());
      setPhase('finished');
    }
  };

  if (phase === 'finished') {
    const won = myScore > botScore;
    const draw = myScore === botScore;
    return (
      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
      >
        <EditorialCard style={styles.resultCard}>
          <View style={styles.resultCenter}>
            <View
              style={[
                styles.iconBadgeLarge,
                {
                  backgroundColor: won
                    ? palette.successSoft
                    : draw
                      ? palette.creamTint
                      : palette.dangerSoft,
                },
              ]}
            >
              <Trophy
                size={28}
                color={
                  won
                    ? palette.success
                    : draw
                      ? palette.primary
                      : palette.danger
                }
                weight="duotone"
              />
            </View>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              DUEL COMPLETE · {track}
            </Text>
            <Text style={[styles.resultTitle, { color: palette.text }]}>
              {won ? 'Victory' : draw ? 'Match Draw' : 'Defeat'}
            </Text>
            <Text style={[styles.scorePair, { color: palette.text }]}>
              {myScore} — {botScore}
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              vs {opponent.name} · {opponent.college}
            </Text>
          </View>

          <View style={styles.actionStack}>
            <ScalePressable
              onPress={() => startDuel()}
              style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
            >
              <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
                Play Rematch
              </Text>
            </ScalePressable>
            <ScalePressable
              onPress={() => setPhase('idle')}
              style={[styles.outlineBtn, { borderColor: palette.borderStrong }]}
            >
              <Text style={[styles.outlineBtnText, { color: palette.text }]}>
                Return to Lobby
              </Text>
            </ScalePressable>
          </View>
        </EditorialCard>
      </ScrollView>
    );
  }

  if (phase === 'playing' && activeQ) {
    return (
      <ScrollView
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
      >
        {!isOnline && (
          <View
            accessibilityRole="alert"
            style={[
              styles.offlineBanner,
              {
                backgroundColor: palette.warningSoft,
                borderColor: palette.amber,
              },
            ]}
          >
            <WifiSlash size={15} color={palette.amber} weight="bold" />
            <Text style={[styles.offlineText, { color: palette.text }]}>
              Offline — live match sync paused until reconnected
            </Text>
          </View>
        )}
        <EditorialCard style={styles.hudCard}>
          <View style={styles.hudRow}>
            <View style={{ flex: 1, gap: 2 }}>
              <Text
                style={[styles.hudLabel, { color: palette.textMuted }]}
                numberOfLines={1}
              >
                {profile?.name || 'You'}
              </Text>
              <Text style={[styles.hudScore, { color: palette.primary }]}>
                {myScore}
              </Text>
            </View>

            <View
              style={[
                styles.timerBox,
                {
                  backgroundColor: palette.surfaceMuted,
                  borderColor: palette.border,
                },
              ]}
            >
              <Text
                style={[
                  styles.hudTimer,
                  { color: timer <= 5 ? palette.danger : palette.text },
                ]}
              >
                {timer}s
              </Text>
              <Text style={[styles.roundText, { color: palette.textMuted }]}>
                Round {roundIdx + 1}/{questions.length}
              </Text>
            </View>

            <View style={{ flex: 1, alignItems: 'flex-end', gap: 2 }}>
              <Text
                style={[styles.hudLabel, { color: palette.textMuted }]}
                numberOfLines={1}
              >
                {opponent.name}
              </Text>
              <Text style={[styles.hudScore, { color: palette.secondary }]}>
                {botScore}
              </Text>
            </View>
          </View>

          <View
            style={[styles.timerTrack, { backgroundColor: palette.surfaceMuted }]}
          >
            <View
              style={[
                styles.timerFill,
                {
                  width: `${(timer / 15) * 100}%`,
                  backgroundColor:
                    timer <= 5 ? palette.danger : palette.primary,
                },
              ]}
            />
          </View>
        </EditorialCard>

        <EditorialCard>
          <Text style={[styles.kicker, { color: palette.textMuted }]}>
            {activeQ.subjectName} · {track} · ZERO NEGATIVE MARKING
          </Text>
          <MathText
            text={activeQ.text}
            style={{
              color: palette.text,
              fontFamily: TYPE_FONTS.display,
              fontSize: 16,
              fontWeight: '700',
              lineHeight: 24,
            }}
          />

          {myPick && (
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 6,
                paddingHorizontal: 10,
                paddingVertical: 7,
                borderRadius: 9,
                borderWidth: 1,
                backgroundColor: palette.creamTint,
                borderColor: palette.primary,
              }}
            >
              <LockKey size={14} color={palette.primary} weight="fill" />
              <Text
                style={{
                  fontFamily: TYPE_FONTS.mono,
                  fontSize: 11.5,
                  fontWeight: '700',
                  color: palette.text,
                }}
              >
                {roundTelemetry
                  ? `LOCKED (${myPick}) · Read ${(roundTelemetry.readTimeMs / 1000).toFixed(1)}s · Think ${(roundTelemetry.thinkTimeMs / 1000).toFixed(1)}s`
                  : `LOCKED (${myPick})`}
              </Text>
            </View>
          )}

          <View style={styles.optionsList}>
            {activeQ.options.map((opt) => {
              const picked = myPick === opt.id;
              const correct =
                opt.id.toUpperCase() === activeQ.correctOptionId.toUpperCase();
              let border = palette.border;
              let bg = palette.surface;
              if (revealed) {
                if (correct) {
                  border = palette.success;
                  bg = palette.successSoft;
                } else if (picked) {
                  border = palette.danger;
                  bg = palette.dangerSoft;
                }
              } else if (picked) {
                border = palette.primary;
                bg = palette.creamTint;
              }
              return (
                <TouchableOpacity
                  key={opt.id}
                  disabled={Boolean(myPick) || revealed}
                  onPressIn={(e) =>
                    recordQuestionFingerActivity(activeQ.id, {
                      kind: 'press_in',
                      optionId: opt.id,
                      ...extractTouchPoint(e),
                    })
                  }
                  onPress={() => {
                    if (myPick) return;
                    const tel = lockQuestionAnswerTelemetry({
                      question: activeQ,
                      selectedOptionId: opt.id,
                      mode: 'duel_1v1',
                    });
                    setRoundTelemetry(tel);
                    setMyPick(opt.id);
                    if (correct) setMyScore((s) => s + 100 + timer * 4);
                  }}
                  activeOpacity={0.8}
                  style={[styles.optBtn, { borderColor: border, backgroundColor: bg }]}
                >
                  <View
                    style={[
                      styles.optBadge,
                      {
                        backgroundColor: picked
                          ? palette.primary
                          : revealed && correct
                            ? palette.success
                            : palette.surfaceMuted,
                      },
                    ]}
                  >
                    <Text
                      style={[
                        styles.optLetter,
                        {
                          color:
                            picked || (revealed && correct)
                              ? '#FFFFFF'
                              : palette.text,
                        },
                      ]}
                    >
                      {opt.id}
                    </Text>
                  </View>
                  <MathText
                    text={opt.text}
                    style={{
                      color: palette.text,
                      flex: 1,
                      fontSize: 14,
                      lineHeight: 20,
                    }}
                  />
                  {revealed && correct ? (
                    <CheckCircle size={18} color={palette.success} weight="fill" />
                  ) : revealed && picked && !correct ? (
                    <XCircle size={18} color={palette.danger} weight="fill" />
                  ) : picked ? (
                    <LockKey size={16} color={palette.primary} weight="fill" />
                  ) : null}
                </TouchableOpacity>
              );
            })}
          </View>

          {revealed && (
            <ScalePressable
              onPress={nextRound}
              style={[
                styles.primaryBtn,
                { backgroundColor: palette.plumAnchorBg },
              ]}
            >
              <Text
                style={[styles.primaryBtnText, { color: palette.plumAnchorText }]}
              >
                {roundIdx < questions.length - 1 ? 'Next Round →' : 'Finish Duel'}
              </Text>
            </ScalePressable>
          )}
        </EditorialCard>
      </ScrollView>
    );
  }

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <View style={styles.headerRow}>
          <View
            style={[
              styles.iconBox,
              { backgroundColor: palette.secondarySoft },
            ]}
          >
            <Sword size={22} color={palette.secondary} weight="duotone" />
          </View>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              LIVE CHALLENGE
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              1v1 Quiz Battle Arena
            </Text>
            <Text style={[styles.subText, { color: palette.textMuted }]}>
              5 rapid rounds · 15s timer · 1-Tap Answer Lock · +150 XP Victory bonus
            </Text>
          </View>
        </View>

        <View style={styles.chipRow}>
          {['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP'].map((u) => {
            const active = track === u;
            return (
              <TouchableOpacity
                key={u}
                onPress={() => setTrack(u)}
                activeOpacity={0.8}
                style={[
                  styles.chip,
                  {
                    backgroundColor: active
                      ? palette.primary
                      : palette.surfaceMuted,
                    borderColor: active ? palette.primary : palette.border,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.chipText,
                    { color: active ? palette.primaryInk : palette.text },
                  ]}
                >
                  {u}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <ScalePressable
          onPress={() => startDuel()}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Start Quick 1v1 Duel ({track})
          </Text>
        </ScalePressable>
      </EditorialCard>

      <EditorialCard>
        <Text style={[styles.sectionTitle, { color: palette.text }]}>
          Join Friend by Room Code
        </Text>
        <View style={styles.joinRow}>
          <TextInput
            value={joinCode}
            onChangeText={(t) => setJoinCode(t.toUpperCase())}
            placeholder="e.g. P404X8"
            placeholderTextColor={palette.textMuted}
            style={[
              styles.input,
              {
                color: palette.text,
                borderColor: palette.borderStrong,
                backgroundColor: palette.surfaceMuted,
              },
            ]}
          />
          <ScalePressable
            onPress={() => {
              if (!joinCode.trim()) showToast('Enter room code first');
              else startDuel(joinCode.trim());
            }}
            style={[
              styles.joinBtn,
              { borderColor: palette.primary, backgroundColor: palette.creamTint },
            ]}
          >
            <Text style={[styles.joinBtnText, { color: palette.primary }]}>
              Join Room
            </Text>
          </ScalePressable>
        </View>
      </EditorialCard>

      <View style={styles.sectionBlock}>
        <Text style={[styles.kicker, { color: palette.textMuted }]}>
          RECENT DUELS ({history.length})
        </Text>
        <EditorialCard style={{ paddingVertical: 4 }}>
          {history.length === 0 ? (
            <Text
              style={[
                styles.emptyText,
                { color: palette.textMuted },
              ]}
            >
              No duels played yet. Start a quick 1v1 match above.
            </Text>
          ) : (
            history.map((h, idx) => {
              const isWin = h.outcome === 'victory';
              const isLoss = h.outcome === 'defeat';
              return (
                <HairlineRow
                  key={h.id}
                  isLast={idx === history.length - 1}
                  left={
                    <View style={{ gap: 2 }}>
                      <Text
                        style={[
                          styles.kicker,
                          {
                            color: isWin
                              ? palette.success
                              : isLoss
                                ? palette.danger
                                : palette.primary,
                          },
                        ]}
                      >
                        {h.outcome.toUpperCase()} · {h.track}
                      </Text>
                      <Text style={[styles.rowTitle, { color: palette.text }]}>
                        vs {h.opponentName}
                      </Text>
                    </View>
                  }
                  right={
                    <Text style={[styles.scoreMono, { color: palette.text }]}>
                      {h.yourScore} — {h.opponentScore}
                    </Text>
                  }
                />
              );
            })
          )}
        </EditorialCard>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
  headerRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  iconBox: {
    width: 46,
    height: 46,
    borderRadius: RADII.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconBadgeLarge: {
    width: 60,
    height: 60,
    borderRadius: RADII.lg,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
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
  sectionTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 15,
    fontWeight: '700',
  },
  sectionBlock: { gap: 8 },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    borderWidth: 1,
    borderRadius: RADII.sm,
    paddingHorizontal: 14,
    minHeight: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  chipText: {
    fontFamily: TYPE_FONTS.body,
    fontWeight: '700',
    fontSize: 12.5,
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
  outlineBtn: {
    borderWidth: 1.5,
    borderRadius: RADII.md,
    minHeight: 48,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
  outlineBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '700',
    fontSize: 14,
  },
  joinRow: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  input: {
    flex: 1,
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    minHeight: 46,
    fontFamily: TYPE_FONTS.mono,
    fontSize: 14,
  },
  joinBtn: {
    borderWidth: 1.5,
    borderRadius: RADII.md,
    minHeight: 46,
    paddingHorizontal: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  joinBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontWeight: '700',
    fontSize: 13.5,
  },
  rowTitle: {
    fontFamily: TYPE_FONTS.body,
    fontWeight: '700',
    fontSize: 14,
  },
  scoreMono: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '700',
    fontSize: 13.5,
    fontVariant: ['tabular-nums'],
  },
  emptyText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    textAlign: 'center',
    paddingVertical: 16,
  },
  hudCard: { gap: 12 },
  hudRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  hudLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    fontWeight: '600',
  },
  hudScore: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 22,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  timerBox: {
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: RADII.md,
    borderWidth: 1,
  },
  hudTimer: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 18,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  roundText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    fontWeight: '600',
  },
  timerTrack: { height: 6, borderRadius: 3, overflow: 'hidden' },
  timerFill: { height: '100%', borderRadius: 3 },
  optionsList: { gap: 10 },
  optBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1.5,
    borderRadius: RADII.md,
    padding: 12,
    minHeight: 54,
  },
  optBadge: {
    width: 32,
    height: 32,
    borderRadius: RADII.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optLetter: {
    fontFamily: TYPE_FONTS.mono,
    fontWeight: '800',
    fontSize: 13,
  },
  resultCard: { gap: 20, paddingVertical: 24 },
  resultCenter: { alignItems: 'center', gap: 6 },
  resultTitle: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 24,
    fontWeight: '800',
  },
  scorePair: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 30,
    fontWeight: '800',
    fontVariant: ['tabular-nums'],
  },
  actionStack: { gap: 10 },
  offlineBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  offlineText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '600',
    flex: 1,
  },
});

import React, { useEffect, useMemo, useState } from 'react';
import {
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  CheckCircle,
  ClockCounterClockwise,
  CloudArrowUp,
  Code,
  Lightning,
  PaperPlaneRight,
  PlusCircle,
  Sparkle,
  TerminalWindow,
} from 'phosphor-react-native';
import { useApp } from '../context/AppContext';
import { QUESTION_BANK } from '../data/questionBank';
import {
  exportConversationLedgerAsJsonl,
  sendAetherMessage,
  testCloudflareTunnelHandshake,
} from '../services/aiTutorService';
import { dataLoggingService } from '../services/dataLoggingService';
import { computeLearnerKnowledgeProfile } from '../services/knowledgeProfileService';
import { storageService } from '../services/storageService';
import { computeCandidateSeriousnessProfile } from '../services/telemetryService';
import { DataLoggingQueueStatus } from '../types';
import { PREP404_COLORS, RADII, TYPE_FONTS } from '../theme/colors';
import {
  AIConversationThread,
  AIStudentContextSnapshot,
  AITutorMode,
} from '../types';
import {
  BottomSheetModal,
  EditorialCard,
  HairlineRow,
  ScalePressable,
  SegmentedControl,
} from '../components/DesignPrimitives';
import { MathText } from '../components/MathText';

interface AetherAITutorScreenProps {
  questionId?: string;
  topicId?: string;
  subjectId?: string;
  threadId?: string;
  initialMode?: AITutorMode;
}

export const SocraticAITutorScreen: React.FC<AetherAITutorScreenProps> = ({
  questionId,
  topicId,
  subjectId,
  threadId,
  initialMode = 'aether_solver',
}) => {
  const { profile, palette, showToast, navigate } = useApp();
  const [threads, setThreads] = useState<AIConversationThread[]>(() =>
    storageService.getAIConversations()
  );
  const [mode, setMode] = useState<AITutorMode>(initialMode);
  const [activeThreadId, setActiveThreadId] = useState<string | undefined>(
    () => {
      if (threadId) return threadId;
      if (questionId) {
        const match = storageService
          .getAIConversations()
          .find((t) => t.questionId === questionId);
        if (match) return match.threadId;
      }
      return storageService.getAIConversations()[0]?.threadId;
    }
  );
  const [inputText, setInputText] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [jsonlModalOpen, setJsonlModalOpen] = useState(false);

  const gatewayConfig = storageService.getAIGatewayConfig();
  const knowledge = useMemo(() => computeLearnerKnowledgeProfile(), []);
  const seriousness = useMemo(() => computeCandidateSeriousnessProfile(), []);

  const linkedQuestion = useMemo(
    () =>
      questionId ? QUESTION_BANK.find((q) => q.id === questionId) : undefined,
    [questionId]
  );

  const linkedTopic = useMemo(() => {
    const tId = topicId || linkedQuestion?.topicId;
    if (tId) {
      return knowledge.topics.find((t) => t.topicId === tId);
    }
    if (subjectId) {
      return knowledge.topics.find((t) => t.subjectId === subjectId);
    }
    return knowledge.topics[1]; // Differentiation default
  }, [topicId, subjectId, linkedQuestion, knowledge.topics]);

  const activeThread = useMemo(
    () => threads.find((t) => t.threadId === activeThreadId) || threads[0],
    [threads, activeThreadId]
  );

  const contextSnapshot: AIStudentContextSnapshot = useMemo(
    () => ({
      questionId: linkedQuestion?.id || activeThread?.questionId,
      questionText: linkedQuestion?.text,
      correctOption: linkedQuestion?.correctOptionId,
      subjectName: linkedQuestion?.subjectName || linkedTopic?.subjectName,
      topicId: linkedTopic?.topicId,
      topicName: linkedTopic?.topicName,
      topicMasteryPercent: linkedTopic?.masteryScore,
      fsrsRetrievabilityPercent: linkedTopic?.fsrsRetrievability,
      negativeMarksLost: 0,
      targetUniversity: activeThread?.universityCode || 'NSU',
      seriousnessScore: seriousness.seriousnessScore,
      impulseGuessRatePercent: seriousness.impulseGuessRatePercent,
    }),
    [linkedQuestion, linkedTopic, activeThread, seriousness]
  );

  const handleSend = async (customPrompt?: string) => {
    const text = (customPrompt ?? inputText).trim();
    if (!text || isSending) return;
    setIsSending(true);
    if (!customPrompt) setInputText('');

    try {
      const result = await sendAetherMessage({
        threadId: activeThread?.threadId,
        userId: profile?.id || 'guest_preview_01',
        userMessage: text,
        mode,
        context: contextSnapshot,
      });
      setThreads(storageService.getAIConversations());
      setActiveThreadId(result.thread.threadId);
    } finally {
      setIsSending(false);
    }
  };

  const startFreshThread = () => {
    const freshId = `thr_${Date.now()}`;
    const newThread: AIConversationThread = {
      threadId: freshId,
      userId: profile?.id || 'guest_preview_01',
      title: linkedTopic
        ? `${linkedTopic.topicName} AETHER AI Session`
        : 'New AETHER AI Analysis Thread',
      mode,
      questionId: linkedQuestion?.id,
      subjectId: linkedTopic?.subjectId,
      topicId: linkedTopic?.topicId,
      topicName: linkedTopic?.topicName,
      universityCode: 'NSU',
      modelEndpointUsed: `${gatewayConfig.localModelName} (${gatewayConfig.cloudflareTunnelUrl})`,
      messages: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isResolved: false,
    };
    const nextList = storageService.upsertAIConversation(newThread);
    setThreads(nextList);
    setActiveThreadId(freshId);
    setHistoryOpen(false);
    showToast('Started new AETHER AI thread');
  };

  const jsonlPreview = useMemo(
    () => exportConversationLedgerAsJsonl(threads),
    [threads]
  );

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      {/* Top Tunnel & Ledger Status Banner */}
      <EditorialCard>
        <View style={styles.rowBetween}>
          <View style={{ flex: 1, gap: 2 }}>
            <Text style={[styles.kicker, { color: palette.primary }]}>
              AETHER AI ENGINE · CLOUDFLARE TUNNEL GPU CLUSTER
            </Text>
            <Text style={[styles.title, { color: palette.text }]}>
              AETHER AI Direct Solver & Telemetry Analyzer
            </Text>
            <Text style={[styles.metaMono, { color: palette.textMuted }]}>
              Model: {gatewayConfig.localModelName} · {threads.length} Saved Threads · Seriousness {seriousness.seriousnessScore}%
            </Text>
          </View>
        </View>

        <View style={styles.topActionsRow}>
          <TouchableOpacity
            onPress={() => setHistoryOpen(true)}
            accessibilityRole="button"
            accessibilityLabel="Open Conversation History Vault"
            style={[
              styles.secondaryBtn,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.borderStrong,
              },
            ]}
          >
            <ClockCounterClockwise size={15} color={palette.text} weight="bold" />
            <Text style={[styles.secondaryBtnText, { color: palette.text }]}>
              History ({threads.length})
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={startFreshThread}
            accessibilityRole="button"
            accessibilityLabel="Start New AETHER AI Thread"
            style={[
              styles.secondaryBtn,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.borderStrong,
              },
            ]}
          >
            <PlusCircle size={15} color={palette.primary} weight="bold" />
            <Text style={[styles.secondaryBtnText, { color: palette.text }]}>
              New Thread
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setJsonlModalOpen(true)}
            accessibilityRole="button"
            accessibilityLabel="Export JSONL Training Ledger"
            style={[
              styles.secondaryBtn,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.borderStrong,
              },
            ]}
          >
            <Code size={15} color={palette.info} weight="bold" />
            <Text style={[styles.secondaryBtnText, { color: palette.text }]}>
              JSONL Ledger
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => navigate({ name: 'serverGateway' })}
            accessibilityRole="button"
            accessibilityLabel="Configure Cloudflare Tunnel Gateway"
            style={[
              styles.secondaryBtn,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.borderStrong,
              },
            ]}
          >
            <TerminalWindow size={15} color={palette.success} weight="bold" />
            <Text style={[styles.secondaryBtnText, { color: palette.text }]}>
              Tunnel Config
            </Text>
          </TouchableOpacity>
        </View>
      </EditorialCard>

      {/* Workload Mode Selector */}
      <SegmentedControl<AITutorMode>
        value={mode}
        onChange={setMode}
        options={[
          { id: 'aether_solver', label: 'Direct Solver' },
          { id: 'mistake_diagnosis', label: 'Telemetry Autopsy' },
          { id: 'study_planner', label: 'Countdown Plan' },
          { id: 'formula_verifier', label: '15s Shortcut' },
        ]}
      />

      {/* Active Student Knowledge Context Card */}
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.textMuted }]}>
          INJECTED LEARNER & TELEMETRY CONTEXT SNAPSHOT
        </Text>
        <Text style={[styles.contextHeadline, { color: palette.text }]}>
          {linkedTopic?.subjectName || 'Higher Mathematics'} ·{' '}
          {linkedTopic?.topicName || 'Differentiation & Tangents'}
        </Text>
        <Text style={[styles.metaMono, { color: palette.textMuted }]}>
          Mastery {linkedTopic?.masteryScore ?? 0}% · FSRS R={linkedTopic?.fsrsRetrievability ?? 0}% · Read {seriousness.avgReadTimeSeconds}s / Think {seriousness.avgThinkTimeSeconds}s · Seriousness {seriousness.seriousnessScore}%
        </Text>
        {linkedQuestion && (
          <View
            style={[
              styles.questionPreviewBox,
              {
                backgroundColor: palette.surfaceMuted,
                borderColor: palette.border,
              },
            ]}
          >
            <MathText
              text={linkedQuestion.text}
              style={{
                color: palette.text,
                fontSize: 13.5,
                fontWeight: '700',
              }}
            />
          </View>
        )}

        {/* Quick AETHER AI Trigger Prompts */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={styles.quickPromptsRow}>
            {[
              {
                label: 'Solve Step-by-Step + 15s Shortcut',
                prompt:
                  'Show the complete AETHER AI step-by-step KaTeX derivation and 15-second exam shortcut.',
              },
              {
                label: 'Analyze My Finger & Impulse Telemetry',
                prompt:
                  'Analyze my Read -> Think -> Lock finger telemetry, impulse-guess rate, and seriousness score.',
              },
              {
                label: 'Build Admission Countdown Plan',
                prompt:
                  'Build my personalized admission countdown roadmap and custom syllabus for NSU, BRACU, and AUST.',
              },
              {
                label: 'Verify Governing Formula & Traps',
                prompt:
                  'Verify the governing formula and show why setter distractor options fail.',
              },
            ].map((chip) => (
              <TouchableOpacity
                key={chip.label}
                onPress={() => handleSend(chip.prompt)}
                accessibilityRole="button"
                accessibilityLabel={chip.label}
                style={[
                  styles.promptChip,
                  {
                    backgroundColor: palette.surfaceMuted,
                    borderColor: palette.borderStrong,
                  },
                ]}
              >
                <Sparkle size={12} color={palette.primary} weight="fill" />
                <Text style={[styles.promptChipText, { color: palette.text }]}>
                  {chip.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </EditorialCard>

      {/* Conversation Transcript */}
      <EditorialCard>
        <View style={styles.rowBetween}>
          <Text style={[styles.kicker, { color: palette.primary }]}>
            ACTIVE THREAD · {activeThread?.title.toUpperCase() || 'AETHER AI SESSION'}
          </Text>
          <Text style={[styles.metaMono, { color: palette.success }]}>
            ● SAVED TO LEDGER
          </Text>
        </View>

        {activeThread && activeThread.messages.length > 0 ? (
          <View style={styles.messagesStack}>
            {activeThread.messages.map((msg) => {
              const isUser = msg.role === 'user';
              return (
                <View
                  key={msg.messageId}
                  style={[
                    styles.messageBubble,
                    {
                      backgroundColor: isUser
                        ? palette.surfaceMuted
                        : palette.surface,
                      borderColor: isUser
                        ? palette.borderStrong
                        : palette.primary,
                    },
                  ]}
                >
                  <View style={styles.rowBetween}>
                    <Text
                      style={[
                        styles.msgRoleMono,
                        { color: isUser ? palette.textMuted : palette.primary },
                      ]}
                    >
                      {isUser
                        ? 'CANDIDATE PROMPT'
                        : `AETHER AI ENGINE · ${String(msg.aetherStage || 'DIRECT SOLVE').toUpperCase()}`}
                    </Text>
                    <Text
                      style={[styles.msgLatencyMono, { color: palette.textSubtle }]}
                    >
                      {msg.latencyMs > 0 ? `${msg.latencyMs}ms · ` : ''}
                      ~{msg.tokenEstimate} tok
                    </Text>
                  </View>

                  <MathText
                    text={msg.content}
                    style={{
                      color: palette.text,
                      fontSize: 13.5,
                      lineHeight: 20,
                    }}
                  />
                </View>
              );
            })}
          </View>
        ) : (
          <Text style={[styles.emptyThreadText, { color: palette.textMuted }]}>
            Ask a question below or tap any AETHER AI prompt above. Every turn and telemetry snapshot is recorded in the FourZeroFour Technologies ledger.
          </Text>
        )}

        {/* Composer Input */}
        <View style={styles.composerRow}>
          <TextInput
            value={inputText}
            onChangeText={setInputText}
            placeholder="Ask AETHER AI for a direct derivation, 15s shortcut, or telemetry analysis..."
            placeholderTextColor={palette.textMuted}
            style={[
              styles.composerInput,
              {
                color: palette.text,
                borderColor: palette.borderStrong,
                backgroundColor: palette.surfaceMuted,
              },
            ]}
          />
          <ScalePressable
            onPress={() => handleSend()}
            accessibilityLabel="Send AETHER AI Message"
            style={[
              styles.sendBtn,
              {
                backgroundColor: palette.primary,
                opacity: isSending ? 0.6 : 1,
              },
            ]}
          >
            <PaperPlaneRight size={18} color={palette.primaryInk} weight="fill" />
          </ScalePressable>
        </View>
      </EditorialCard>

      {/* Conversation History Bottom Sheet */}
      <BottomSheetModal
        visible={historyOpen}
        onClose={() => setHistoryOpen(false)}
        title="Persisted AETHER AI Conversation Vault"
        subtitle="Zero-loss history of every AETHER AI session & candidate telemetry snapshot"
      >
        <View style={{ gap: 6 }}>
          {threads.map((thr, idx) => (
            <HairlineRow
              key={thr.threadId}
              isLast={idx === threads.length - 1}
              onPress={() => {
                setActiveThreadId(thr.threadId);
                setMode(thr.mode);
                setHistoryOpen(false);
              }}
              left={
                <View style={{ gap: 2 }}>
                  <Text style={[styles.rowTitle, { color: palette.text }]}>
                    {thr.title}
                  </Text>
                  <Text style={[styles.metaMono, { color: palette.textMuted }]}>
                    {thr.messages.length} turns · {thr.universityCode || 'PHASE 1'} ·{' '}
                    {thr.mode.replace('_', ' ')}
                  </Text>
                </View>
              }
              right={
                <Text
                  style={[
                    styles.kicker,
                    {
                      color:
                        thr.threadId === activeThread?.threadId
                          ? palette.primary
                          : palette.textMuted,
                    },
                  ]}
                >
                  {thr.threadId === activeThread?.threadId ? 'ACTIVE' : 'OPEN'}
                </Text>
              }
            />
          ))}
        </View>
      </BottomSheetModal>

      {/* JSONL Training Dataset Export Modal */}
      <BottomSheetModal
        visible={jsonlModalOpen}
        onClose={() => setJsonlModalOpen(false)}
        title="Local Model Fine-Tuning Ledger (JSONL)"
        subtitle="Structured system + context + multi-turn conversation logs"
      >
        <View
          style={[
            styles.codeBox,
            {
              backgroundColor: palette.surfaceMuted,
              borderColor: palette.borderStrong,
            },
          ]}
        >
          <Text
            style={[styles.codeMono, { color: palette.text }]}
            numberOfLines={12}
          >
            {jsonlPreview}
          </Text>
        </View>
        <ScalePressable
          onPress={() => {
            setJsonlModalOpen(false);
            showToast(
              `Exported ${threads.length} conversation threads in ShareGPT/OpenAI JSONL format!`
            );
          }}
          style={[styles.primaryBtn, { backgroundColor: palette.primary }]}
        >
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            Copy / Sync JSONL to Local Training Pipeline
          </Text>
        </ScalePressable>
      </BottomSheetModal>
    </ScrollView>
  );
};

export const ServerGatewayScreen: React.FC = () => {
  const { palette, showToast, navigate } = useApp();
  const [config, setConfig] = useState(() =>
    storageService.getAIGatewayConfig()
  );
  const [testing, setTesting] = useState(false);
  const [handshakeReport, setHandshakeReport] = useState<string | null>(null);
  const [queueStatus, setQueueStatus] = useState<DataLoggingQueueStatus>(() =>
    dataLoggingService.getQueueStatus()
  );

  useEffect(() => {
    return dataLoggingService.subscribeStatus(setQueueStatus);
  }, []);

  const threads = storageService.getAIConversations();
  const totalMessages = threads.reduce((acc, t) => acc + t.messages.length, 0);

  const saveAndTest = async () => {
    setTesting(true);
    storageService.setAIGatewayConfig(config);
    try {
      const res = await testCloudflareTunnelHandshake(config);
      setConfig(storageService.getAIGatewayConfig());
      setHandshakeReport(
        `${res.message} [Status: ${res.status.toUpperCase()} · Latency: ${res.latencyMs}ms]`
      );
      showToast(`Handshake verified (${res.latencyMs}ms)`);
    } finally {
      setTesting(false);
    }
  };

  return (
    <ScrollView
      contentContainerStyle={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.primary }]}>
          FOURZEROFOUR TECHNOLOGIES · INFRASTRUCTURE GATEWAY
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          Cloudflare Tunnel & prep404_server Sync
        </Text>
        <Text style={[styles.subText, { color: palette.textMuted }]}>
          Connect your on-premise RTX A4000 GPU cluster via Cloudflare Tunnel while keeping 100% of learner conversations and telemetry synchronized with prep404_server contracts.
        </Text>

        <View style={styles.fieldGroup}>
          <Text style={[styles.fieldLabel, { color: palette.text }]}>
            Cloudflare Tunnel Endpoint (Local GPU Cluster)
          </Text>
          <TextInput
            value={config.cloudflareTunnelUrl}
            onChangeText={(v) =>
              setConfig((prev) => ({ ...prev, cloudflareTunnelUrl: v }))
            }
            placeholder="https://a4000-cluster.fourzerofour.tech"
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
        </View>

        <View style={styles.fieldGroup}>
          <Text style={[styles.fieldLabel, { color: palette.text }]}>
            Local Model Identifier (vLLM / Ollama / OpenAI-Compatible)
          </Text>
          <TextInput
            value={config.localModelName}
            onChangeText={(v) =>
              setConfig((prev) => ({ ...prev, localModelName: v }))
            }
            placeholder="aether-ai-7b-prep404"
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
        </View>

        <View style={styles.fieldGroup}>
          <Text style={[styles.fieldLabel, { color: palette.text }]}>
            prep404_server Base API Route
          </Text>
          <TextInput
            value={config.prep404ServerUrl}
            onChangeText={(v) =>
              setConfig((prev) => ({ ...prev, prep404ServerUrl: v }))
            }
            placeholder="/api/v1"
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
        </View>

        <HairlineRow
          left={
            <View style={{ gap: 2 }}>
              <Text style={[styles.rowTitle, { color: palette.text }]}>
                Zero-Loss Conversation & Telemetry Ledger
              </Text>
              <Text style={[styles.subText, { color: palette.textMuted }]}>
                Retain every prompt, locked option, finger timing & FSRS state for AETHER AI
              </Text>
            </View>
          }
          right={
            <Switch
              value={config.keepFullConversationLedger}
              onValueChange={(v) =>
                setConfig((prev) => ({ ...prev, keepFullConversationLedger: v }))
              }
            />
          }
        />

        <ScalePressable
          onPress={saveAndTest}
          accessibilityLabel="Test Cloudflare Tunnel and Server Handshake"
          style={[
            styles.primaryBtn,
            { backgroundColor: palette.primary, opacity: testing ? 0.7 : 1 },
          ]}
        >
          <CloudArrowUp size={18} color={palette.primaryInk} weight="bold" />
          <Text style={[styles.primaryBtnText, { color: palette.primaryInk }]}>
            {testing
              ? 'Probing Tunnel & /api/v1...'
              : 'Save & Test Tunnel Handshake'}
          </Text>
        </ScalePressable>

        {handshakeReport && (
          <View
            style={[
              styles.reportBanner,
              {
                backgroundColor: palette.successSoft,
                borderColor: palette.success,
              },
            ]}
          >
            <CheckCircle size={16} color={palette.success} weight="fill" />
            <Text style={[styles.reportText, { color: palette.text }]}>
              {handshakeReport}
            </Text>
          </View>
        )}
      </EditorialCard>

      {/* Synchronized prep404_server Contract Endpoints */}
      <EditorialCard>
        <Text style={[styles.kicker, { color: palette.primary }]}>
          SYNCHRONIZED PREP404_SERVER CONTRACTS
        </Text>
        <Text style={[styles.title, { color: palette.text }]}>
          Active Full-Stack Routes (/api/v1/*)
        </Text>
        <Text style={[styles.metaMono, { color: palette.textMuted }]}>
          {threads.length} Conversation Threads · {totalMessages} Logged Turns · Outbox {queueStatus.pendingCount} Pending · {queueStatus.transmittedCount} Delivered
        </Text>
        <ScalePressable
          onPress={async () => {
            const res = await dataLoggingService.flushOutbox();
            showToast(`Telemetry flush complete: ${res.delivered} sent, ${res.remaining} pending`);
          }}
          accessibilityLabel="Flush Telemetry Outbox Queue"
          style={[
            styles.secondaryBtn,
            {
              backgroundColor: palette.surfaceMuted,
              borderColor: palette.borderStrong,
              marginBottom: 4,
            },
          ]}
        >
          <CloudArrowUp size={15} color={palette.primary} weight="bold" />
          <Text style={[styles.secondaryBtnText, { color: palette.text }]}>
            {queueStatus.isFlushing
              ? 'Flushing Telemetry Queue...'
              : `Flush Telemetry Queue (${queueStatus.pendingCount} Pending · ${queueStatus.transmittedCount} Synced)`}
          </Text>
        </ScalePressable>

        {[
          [
            'POST /api/v1/ai/chat',
            'Proxies AETHER AI turns to Cloudflare Tunnel + logs full context snapshot',
          ],
          [
            'POST /api/v1/ai/tunnel-handshake',
            'Verifies live RTX A4000 Cloudflare Tunnel health & latency',
          ],
          [
            'GET /api/v1/ai/conversations',
            'Retrieves persisted multi-turn AETHER AI threads & JSONL training logs',
          ],
          [
            'POST /api/v1/telemetry/answer-lock',
            'Records Read -> Think -> Permanent Answer Lock finger timing & seriousness',
          ],
          [
            'GET /api/v1/knowledge/profile',
            'Computes 360° Subject/Topic Mastery, FSRS curves & 7-Uni Cut-Off Gap (0 Neg)',
          ],
        ].map(([route, desc], idx, arr) => (
          <HairlineRow
            key={route}
            isLast={idx === arr.length - 1}
            left={
              <View style={{ gap: 2 }}>
                <Text style={[styles.codeRouteMono, { color: palette.text }]}>
                  {route}
                </Text>
                <Text style={[styles.subText, { color: palette.textMuted }]}>
                  {desc}
                </Text>
              </View>
            }
            right={
              <Text style={[styles.kicker, { color: palette.success }]}>
                ● LIVE
              </Text>
            }
          />
        ))}

        <ScalePressable
          onPress={() => navigate({ name: 'aiTutor' })}
          style={[
            styles.primaryBtn,
            { backgroundColor: PREP404_COLORS.plum, marginTop: 4 },
          ]}
        >
          <Lightning size={16} color="#FFFFFF" weight="fill" />
          <Text style={[styles.primaryBtnText, { color: '#FFFFFF' }]}>
            Open AETHER AI Studio
          </Text>
        </ScalePressable>
      </EditorialCard>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: { padding: 16, gap: 14, paddingBottom: 36 },
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
  subText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    lineHeight: 19,
  },
  metaMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    fontVariant: ['tabular-nums'],
  },
  topActionsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 4,
  },
  secondaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 11,
    minHeight: 38,
    borderRadius: RADII.sm,
    borderWidth: 1,
  },
  secondaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 12,
    fontWeight: '700',
  },
  contextHeadline: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 15.5,
    fontWeight: '800',
  },
  questionPreviewBox: {
    padding: 12,
    borderRadius: RADII.md,
    borderWidth: 1,
    marginTop: 4,
  },
  quickPromptsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 6,
  },
  promptChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: RADII.sm,
    borderWidth: 1,
    minHeight: 38,
  },
  promptChipText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12,
    fontWeight: '700',
  },
  messagesStack: {
    gap: 10,
    marginTop: 4,
  },
  messageBubble: {
    padding: 12,
    borderRadius: RADII.md,
    borderWidth: 1.5,
    gap: 6,
  },
  msgRoleMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10.5,
    fontWeight: '700',
  },
  msgLatencyMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 10.5,
    fontVariant: ['tabular-nums'],
  },
  emptyThreadText: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13,
    lineHeight: 19,
    paddingVertical: 12,
  },
  composerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 6,
  },
  composerInput: {
    flex: 1,
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 14,
    paddingVertical: 11,
    minHeight: 46,
    fontFamily: TYPE_FONTS.body,
    fontSize: 13.5,
  },
  sendBtn: {
    width: 48,
    height: 46,
    borderRadius: RADII.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowTitle: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 13.5,
    fontWeight: '700',
  },
  codeBox: {
    padding: 12,
    borderRadius: RADII.md,
    borderWidth: 1,
  },
  codeMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11,
    lineHeight: 16,
  },
  primaryBtn: {
    height: 46,
    borderRadius: RADII.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingHorizontal: 16,
  },
  primaryBtnText: {
    fontFamily: TYPE_FONTS.display,
    fontSize: 13.5,
    fontWeight: '700',
  },
  fieldGroup: {
    gap: 5,
  },
  fieldLabel: {
    fontFamily: TYPE_FONTS.body,
    fontSize: 12.5,
    fontWeight: '700',
  },
  input: {
    borderWidth: 1,
    borderRadius: RADII.md,
    paddingHorizontal: 12,
    paddingVertical: 10,
    minHeight: 44,
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
  },
  reportBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 12,
    borderRadius: RADII.md,
    borderWidth: 1,
  },
  reportText: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 11.5,
    flex: 1,
  },
  codeRouteMono: {
    fontFamily: TYPE_FONTS.mono,
    fontSize: 12.5,
    fontWeight: '700',
  },
});

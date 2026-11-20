import 'package:flutter/material.dart';
import '../../../../core/repositories/ai_mentor_repository.dart';
import '../../../../core/theme/app_theme.dart';

/// Prep404 Bhaiya — Senior Brother AI Mentor Chat
/// Streams real-time replies from the Lab PC Gemma 4 fleet (via Cloudflare Tunnels)
/// in English, Bangla (বাংলা), or Banglish, with full DB conversation history.
class AiMentorChatScreen extends StatefulWidget {
  final String? initialSessionId;
  final String contextType;
  final String? contextRefId;
  final Map<String, dynamic>? contextPayload;
  final String? initialPrompt;

  const AiMentorChatScreen({
    super.key,
    this.initialSessionId,
    this.contextType = 'general',
    this.contextRefId,
    this.contextPayload,
    this.initialPrompt,
  });

  @override
  State<AiMentorChatScreen> createState() => _AiMentorChatScreenState();
}

class _AiMentorChatScreenState extends State<AiMentorChatScreen> {
  final AiMentorRepository _repo = AiMentorRepository();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _sessionId;
  String _sessionTitle = 'Prep404 Bhaiya';
  List<AiChatSessionItem> _sessions = [];
  List<AiChatMessageItem> _messages = [];
  bool _isLoadingHistory = true;
  bool _isStreaming = false;
  int _onlineNodesCount = 0;

  static const List<Map<String, String>> _starterPrompts = [
    {
      'tag': 'Banglish',
      'text': 'Vaiya, physics er vector bujhtesi na. Simple shortcut bole dao.',
    },
    {
      'tag': 'বাংলা',
      'text': 'পরীক্ষার আগে অনেক টেনশন হচ্ছে, কীভাবে শান্ত থেকে পড়াশোনা করব?',
    },
    {
      'tag': 'English',
      'text': 'Give me a smart 30-day revision plan for private university admission.',
    },
    {
      'tag': 'Strategy',
      'text': 'Vaiya, 60 minute MCQ exam e time management kivabe korbo?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoadingHistory = true);
    final fleetFuture = _repo.fetchFleetStatus();
    final sessionsFuture = _repo.fetchSessions();

    final fleet = await fleetFuture;
    final sessions = await sessionsFuture;
    if (!mounted) return;

    setState(() {
      _onlineNodesCount = (fleet['onlineCount'] as num?)?.toInt() ?? 0;
      _sessions = sessions;
    });

    if (widget.initialSessionId != null) {
      await _openSession(widget.initialSessionId!);
    } else if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      setState(() => _isLoadingHistory = false);
      await _sendMessage(widget.initialPrompt!);
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _openSession(String sessionId) async {
    setState(() => _isLoadingHistory = true);
    final msgs = await _repo.fetchMessages(sessionId);
    final match = _sessions.where((s) => s.id == sessionId).firstOrNull;
    if (!mounted) return;
    setState(() {
      _sessionId = sessionId;
      _sessionTitle = match?.title ?? 'Prep404 Bhaiya';
      _messages = msgs;
      _isLoadingHistory = false;
    });
    _scrollToBottom();
  }

  void _startFreshChat() {
    setState(() {
      _sessionId = null;
      _sessionTitle = 'Prep404 Bhaiya';
      _messages = [];
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _isStreaming) return;
    _inputController.clear();

    setState(() => _isStreaming = true);

    try {
      // Create a DB session on the first message
      if (_sessionId == null) {
        final created = await _repo.createSession(
          contextType: widget.contextType,
          contextRefId: widget.contextRefId,
          contextPayload: widget.contextPayload,
        );
        _sessionId = created.id;
        _sessions = [created, ..._sessions];
      }

      final tempUserId = 'local_u_${DateTime.now().millisecondsSinceEpoch}';
      final tempAsstId = 'local_a_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _messages = [
          ..._messages,
          AiChatMessageItem(id: tempUserId, role: 'user', content: text),
          AiChatMessageItem(
            id: tempAsstId,
            role: 'assistant',
            content: '',
            isStreaming: true,
          ),
        ];
      });
      _scrollToBottom();

      String accumulated = '';
      String? realAsstId;
      String? modelUsed;
      String? nodeName;
      int? latencyMs;

      await for (final event in _repo.streamMessage(
        sessionId: _sessionId!,
        content: text,
      )) {
        if (!mounted) return;
        final type = event['type']?.toString();
        if (type == 'meta') {
          modelUsed = event['model']?.toString();
          nodeName = event['node']?.toString();
          final newTitle = event['sessionTitle']?.toString();
          if (newTitle != null && newTitle.isNotEmpty) {
            _sessionTitle = newTitle;
          }
        } else if (type == 'token') {
          final tok = event['token']?.toString() ?? '';
          accumulated += tok;
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == tempAsstId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                content: accumulated,
                modelUsed: modelUsed,
                nodeName: nodeName,
              );
            }
          });
          _scrollToBottom();
        } else if (type == 'done') {
          realAsstId = event['assistantMessageId']?.toString();
          latencyMs = (event['latencyMs'] as num?)?.toInt();
        }
      }

      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempAsstId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            id: realAsstId ?? tempAsstId,
            content: accumulated.isEmpty
                ? 'Sorry bhai, connection ta ektu drop hoye geche. Abar bolo!'
                : accumulated,
            modelUsed: modelUsed,
            nodeName: nodeName,
            latencyMs: latencyMs,
            isStreaming: false,
          );
        }
        _isStreaming = false;
      });
      _repo.fetchSessions().then((list) {
        if (mounted) setState(() => _sessions = list);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isStreaming && m.content.isEmpty);
        _isStreaming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: context.colors.dangerRed,
        ),
      );
    }
  }

  void _openHistorySheet() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Past Conversations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startFreshChat();
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Chat'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'No saved conversations yet. Say hi to Bhaiya!',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, idx) {
                        final s = _sessions[idx];
                        final isCurrent = s.id == _sessionId;
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCurrent ? colors.primary : colors.border,
                            ),
                          ),
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: isCurrent ? colors.primary : colors.textSecondary,
                            size: 20,
                          ),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${s.messageCount} messages',
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: colors.textSecondary),
                            onPressed: () async {
                              await _repo.archiveSession(s.id);
                              if (!mounted) return;
                              setState(() {
                                _sessions.removeWhere((x) => x.id == s.id);
                                if (_sessionId == s.id) _startFreshChat();
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _openSession(s.id);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: colors.primary.withValues(alpha: 0.14),
              child: Icon(Icons.psychology_alt_rounded,
                  size: 20, color: colors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sessionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _onlineNodesCount > 0
                              ? colors.accentEmerald
                              : colors.accentAmber,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _onlineNodesCount > 0
                            ? 'Senior Mentor • English / বাংলা / Banglish'
                            : 'Connecting to Lab AI...',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            onPressed: _openHistorySheet,
            icon: Icon(Icons.history_rounded, color: colors.textPrimary),
          ),
          IconButton(
            tooltip: 'New Chat',
            onPressed: _isStreaming ? null : _startFreshChat,
            icon: Icon(Icons.add_comment_outlined, color: colors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingHistory
                ? Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  )
                : _messages.isEmpty
                    ? _buildEmptyWelcome(colors)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) =>
                            _buildMessageBubble(_messages[idx], colors),
                      ),
          ),
          _buildInputBar(colors),
        ],
      ),
    );
  }

  Widget _buildEmptyWelcome(AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded,
                size: 36, color: colors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Assalamu Alaikum! Ask Bhaiya Anything',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Write in English, বাংলা, or Banglish — study doubts, exam stress, or admission strategy. Everything is saved in your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ..._starterPrompts.map((item) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendMessage(item['text']!),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['tag']!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['text']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: colors.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessageItem msg, AppColors colors) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && msg.isStreaming && msg.content.isEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bhaiya is typing...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              )
            else
              SelectableText(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isUser ? Colors.white : colors.textPrimary,
                ),
              ),
            if (!isUser && !msg.isStreaming && !msg.id.startsWith('local_')) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _setFeedback(msg, 'up'),
                    child: Icon(
                      msg.feedback == 'up'
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 14,
                      color: msg.feedback == 'up'
                          ? colors.accentEmerald
                          : colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _setFeedback(msg, 'down'),
                    child: Icon(
                      msg.feedback == 'down'
                          ? Icons.thumb_down_rounded
                          : Icons.thumb_down_outlined,
                      size: 14,
                      color: msg.feedback == 'down'
                          ? colors.dangerRed
                          : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _setFeedback(AiChatMessageItem msg, String fb) async {
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(feedback: fb);
      }
    });
    await _repo.sendFeedback(msg.id, fb);
  }

  Widget _buildInputBar(AppColors colors) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Ask Bhaiya in English, বাংলা or Banglish...',
                  hintStyle: TextStyle(fontSize: 13, color: colors.textMuted),
                  filled: true,
                  fillColor: colors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isStreaming
                  ? null
                  : () => _sendMessage(_inputController.text),
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              icon: _isStreaming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

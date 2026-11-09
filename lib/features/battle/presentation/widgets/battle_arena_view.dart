import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/battle_controller.dart';
import 'battle_idle_lobby_view.dart';
import 'battle_active_duel_view.dart';
import 'battle_finished_view.dart';

/// Real-Time 1v1 PvP Quiz Battle Arena View
/// 100% Database-Driven: Same university preference, program track choice,
/// and multi-section question coverage from PostgreSQL.
class BattleArenaView extends StatefulWidget {
  final BattleController controller;

  const BattleArenaView({super.key, required this.controller});

  @override
  State<BattleArenaView> createState() => _BattleArenaViewState();
}

class _BattleArenaViewState extends State<BattleArenaView> {
  final TextEditingController _roomCodeInputController =
      TextEditingController();

  @override
  void dispose() {
    _roomCodeInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        switch (state.status) {
          case BattleStatus.idle:
          case BattleStatus.loadingPrograms:
            return _buildIdleLobby(context, state);
          case BattleStatus.waitingInQueue:
            return _buildWaitingQueueView(context, state);
          case BattleStatus.roomCreated:
            return _buildRoomCreatedView(context, state);
          case BattleStatus.readyCountdown:
            return _buildReadyCountdownView(context, state);
          case BattleStatus.questionActive:
          case BattleStatus.roundSummary:
            return _buildQuestionActiveView(context, state);
          case BattleStatus.finished:
            return _buildFinishedView(context, state);
          case BattleStatus.error:
            return _buildErrorView(context, state);
        }
      },
    );
  }

  // 1. Idle Lobby: Target University & Program Selector
  Widget _buildIdleLobby(BuildContext context, BattleState state) =>
      BattleIdleLobbyView(
        controller: widget.controller,
        state: state,
        onJoinRoomPressed: () => _showJoinRoomDialog(context),
      );

  // 2. Waiting in Matchmaking Queue
  Widget _buildWaitingQueueView(BuildContext context, BattleState state) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A36)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Searching for Opponent...',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '${state.universityCode ?? "BRACU"} • ${state.programSlug?.toUpperCase() ?? "ENG"} Track',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFFF7A36)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.queueWaitingMessage ??
                    'Matching you with a real candidate targeting the same program...',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 36),
              OutlinedButton(
                onPressed: widget.controller.cancelMatchmaking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textSecondary,
                  side: BorderSide(color: colors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel Search'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () =>
                    widget.controller.startBotMatch(candidateName: 'You'),
                icon:
                    const Icon(Icons.bolt, size: 16, color: Color(0xFFFF7A36)),
                label: const Text(
                  'No waiting: Play Prep404 AI Engine now',
                  style: TextStyle(
                      color: Color(0xFFFF7A36),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Room Created: Assembly Lobby View (2 - 8 Players, 1m 30s Timer, Ready Sync)
  Widget _buildRoomCreatedView(BuildContext context, BattleState state) {
    final colors = context.colors;
    final code = state.roomCode ?? 'ROOM-404';
    final isHost = state.isHost;
    final players = state.roomPlayers;
    final maxPlayers = state.roomMaxPlayers;
    final timeRemaining = state.roomTimeRemainingSeconds;
    final isWarning = timeRemaining <= 20;
    final timerColor = isWarning ? const Color(0xFFEF4444) : const Color(0xFFFF7A36);

    // Host can start when at least 2 players are in and all non-host players are ready
    final nonHostPlayers = players.where((p) => !p.isHost).toList();
    final allClientsReady = nonHostPlayers.isNotEmpty && nonHostPlayers.every((p) => p.isReady);
    final canHostStart = players.length >= 2 && allClientsReady;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A36).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF7A36)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHost ? Icons.military_tech : Icons.sports_kabaddi,
                        size: 16,
                        color: const Color(0xFFFF7A36),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isHost ? 'ROOM HOST LOBBY' : 'CONTESTANT LOBBY',
                        style: const TextStyle(
                          color: Color(0xFFFF7A36),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Duel Assembly Room',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.universityCode ?? "BRACU"} • ${state.programSlug?.toUpperCase() ?? "ENG"} Track',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Room Code Share Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF7A36), width: 1.5),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROOM CODE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: colors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            color: Color(0xFFFF7A36),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A36).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFFFF7A36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFFF7A36)),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Room Code $code copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 1m 30s Countdown Timer Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: timerColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 18, color: timerColor),
                            const SizedBox(width: 8),
                            Text(
                              'Assembly Window (1m 30s max)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatRemainingSeconds(timeRemaining),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: timerColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (timeRemaining / 90.0).clamp(0.0, 1.0),
                        backgroundColor: colors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Players Joined Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COMPETITORS JOINED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A36).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${players.length} / $maxPlayers PLAYERS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7A36),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Slots list (shows joined players + empty waiting slots)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: maxPlayers,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index < players.length) {
                    final p = players[index];
                    final isMe = (p.id == widget.controller.state.myPlayer?.id) ||
                        (p.name == (widget.controller.state.myPlayer?.name ?? 'You'));

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: p.isHost
                              ? const Color(0xFFFF7A36)
                              : (p.isReady ? const Color(0xFF10B981) : colors.border),
                          width: (p.isHost || p.isReady) ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: p.isHost
                                ? const Color(0xFFFF7A36).withValues(alpha: 0.2)
                                : (p.isReady
                                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                    : colors.surfaceElevated),
                            child: Icon(
                              p.isHost ? Icons.star : Icons.person,
                              size: 18,
                              color: p.isHost
                                  ? const Color(0xFFFF7A36)
                                  : (p.isReady ? const Color(0xFF10B981) : colors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (isMe)
                                      Text(
                                        ' (You)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.college,
                                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (p.isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A36).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.military_tech, size: 12, color: Color(0xFFFF7A36)),
                                  SizedBox(width: 4),
                                  Text(
                                    'HOST',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF7A36),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (p.isReady)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'READY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                'NOT READY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.6),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_add_outlined, size: 18, color: colors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Slot ${index + 1}: Waiting for contestant to join...',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (isHost) ...[
                ElevatedButton.icon(
                  onPressed: canHostStart ? widget.controller.hostStartRoom : null,
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: Text(
                    canHostStart
                        ? 'Start Battle (${players.length} Players Ready)'
                        : (players.length < 2
                            ? 'Waiting for Friends to Join (Min 2)'
                            : 'Waiting for Clients to be Ready'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A36),
                    foregroundColor: const Color(0xFF542747),
                    disabledBackgroundColor: colors.surfaceElevated,
                    disabledForegroundColor: colors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: widget.controller.leaveRoom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Disband Room'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => widget.controller.toggleReady(!state.isReady),
                  icon: Icon(
                    state.isReady ? Icons.check_circle : Icons.bolt,
                    size: 18,
                  ),
                  label: Text(
                    state.isReady ? 'You Are Ready ✓ (Tap to Unready)' : 'Click When Ready ⚡',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isReady ? const Color(0xFF10B981) : const Color(0xFFFF7A36),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.isReady
                      ? 'Waiting for host to launch the duel...'
                      : 'Please mark yourself Ready so the host can start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: widget.controller.leaveRoom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Leave Room'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRemainingSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // 4. Ready Countdown View
  Widget _buildReadyCountdownView(BuildContext context, BattleState state) {
    final colors = context.colors;
    final me = state.myPlayer;
    final opp = state.opponentPlayer;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A36).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF7A36)),
              ),
              child: const Text(
                'OPPONENT FOUND!',
                style: TextStyle(
                  color: Color(0xFFFF7A36),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPlayerAvatar(colors, me?.name ?? 'You', true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surfaceElevated,
                      border: Border.all(color: colors.border),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFFFF7A36)),
                    ),
                  ),
                ),
                _buildPlayerAvatar(colors, opp?.name ?? 'Opponent', false),
              ],
            ),
            const SizedBox(height: 28),

            // Section breakdown preview
            if (state.sections.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      '${state.totalQuestions} Rounds across ${state.sections.length} Sections',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.sections.join(' • '),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Get Ready! Round 1 begins in moments...',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Question Active Battle Arena
  Widget _buildQuestionActiveView(BuildContext context, BattleState state) =>
      BattleActiveDuelView(
        controller: widget.controller,
        state: state,
      );

  // 6. Finished / Victory View
  Widget _buildFinishedView(BuildContext context, BattleState state) =>
      BattleFinishedView(
        controller: widget.controller,
        state: state,
      );

  // 7. Error View
  Widget _buildErrorView(BuildContext context, BattleState state) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: colors.dangerRed),
            const SizedBox(height: 16),
            Text(
              'Duel Encountered an Issue',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Connection lost to the duel server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.controller.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A36),
                foregroundColor: const Color(0xFF542747),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Return to Lobby'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(AppColors colors, String name, bool isMe) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: isMe ? const Color(0xFFFF7A36) : colors.dangerRed,
          child: Icon(isMe ? Icons.person : Icons.person_outline,
              color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontSize: 13),
        ),
      ],
    );
  }

  void _showJoinRoomDialog(BuildContext context) {
    final colors = context.colors;
    _roomCodeInputController.clear();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Enter Duel Room Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 4-8 character room code provided by your friend (e.g. BRACU-404):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomCodeInputController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. BRACU-582',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _roomCodeInputController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(dialogCtx).pop();
                widget.controller
                    .joinPrivateRoom(roomCode: code, candidateName: 'You');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A36),
              foregroundColor: const Color(0xFF542747),
            ),
            child: const Text('Join Room'),
          ),
        ],
      ),
    );
  }
}

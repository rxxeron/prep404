import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/battle_controller.dart';

class BattleIdleLobbyView extends StatelessWidget {
  final BattleController controller;
  final BattleState state;
  final VoidCallback onJoinRoomPressed;

  const BattleIdleLobbyView({
    super.key,
    required this.controller,
    required this.state,
    required this.onJoinRoomPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabSwitcher(context),
              const SizedBox(height: 20),
              if (state.activeLobbyTab == 0)
                _buildMatchmakingView(context)
              else
                _buildHistoryView(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final colors = context.colors;
    final isLobby = state.activeLobbyTab == 0;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => controller.switchLobbyTab(0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isLobby ? const Color(0xFFFF7A36) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 16,
                      color: isLobby ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Duel Arena',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLobby ? Colors.white : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => controller.switchLobbyTab(1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isLobby ? const Color(0xFFFF7A36) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: !isLobby ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Match History${state.matchHistory.isNotEmpty ? " (${state.matchHistory.length})" : ""}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: !isLobby ? Colors.white : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchmakingView(BuildContext context) {
    final colors = context.colors;
    final unis = state.universities;
    final selectedUni = state.selectedUniversity;
    final selectedProg = state.selectedProgram;

    return Column(
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 16, color: Color(0xFFFF7A36)),
                SizedBox(width: 6),
                Text(
                  'REAL-LIFE 1v1 DUEL ARENA',
                  style: TextStyle(
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
          'Admission Quiz Duel',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Duel candidates targeting the exact same university and faculty. Questions are drawn dynamically from the official admission blueprint.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: colors.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 24),

        // University Preference Selector
        Text(
          'TARGET UNIVERSITY PREFERENCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: colors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        if (unis.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: unis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final u = unis[idx];
                final isSelected = selectedUni?.code == u.code;
                return ChoiceChip(
                  label: Text(
                    u.code,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w600,
                      color:
                          isSelected ? Colors.white : colors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF7A36),
                  backgroundColor: colors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFFF7A36)
                        : colors.border,
                  ),
                  onSelected: (_) => controller.selectUniversity(u),
                );
              },
            ),
          ),
        const SizedBox(height: 20),

        // Program Choice Selector
        Text(
          'PROGRAM & FACULTY TRACK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: colors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedUni != null && selectedUni.programs.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: selectedUni.programs.map((p) {
                final isSelected = selectedProg?.id == p.id;
                return InkWell(
                  onTap: () => controller.selectProgram(p),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A36).withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF7A36)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFFFF7A36)
                              : colors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                              color: isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              'No patterns loaded for selected university.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        const SizedBox(height: 20),

        // Tested Sections Breakdown
        if (selectedProg != null && selectedProg.sections.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book,
                        size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Text(
                      'SECTIONS COVERED IN THIS DUEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedProg.sections.map((sec) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '• $sec (2-3 Qs)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Rounds: ~${selectedProg.sections.length * 3} • 15 Seconds per Round',
                  style: TextStyle(
                      fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 28),

        // Primary Matchmaking Action
        ElevatedButton.icon(
          onPressed: () => controller.joinQueue(candidateName: 'You'),
          icon: const Icon(Icons.flash_on, size: 20),
          label: Text(
            'Find Match (${selectedUni?.code ?? "BRACU"} - ${selectedProg?.slug.toUpperCase() ?? "ENG"})',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A36),
            foregroundColor: const Color(0xFF542747),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 12),

        // Two secondary action buttons: Challenge Friend & Practice
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showBuildRoomDialog(context),
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text('Create Room',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onJoinRoomPressed,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Enter Code',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Practice Duel Option
        TextButton.icon(
          onPressed: () =>
              controller.startBotMatch(candidateName: 'You'),
          icon: const Icon(Icons.smart_toy,
              size: 18, color: Color(0xFFFF7A36)),
          label: const Text(
            'Immediate Duel vs Prep404 AI Engine',
            style: TextStyle(
              color: Color(0xFFFF7A36),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryView(BuildContext context) {
    final colors = context.colors;
    final summary = state.matchSummary;
    final history = state.matchHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Performance Cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                label: 'DUELS',
                value: '${summary?.totalBattles ?? history.length}',
                accentColor: const Color(0xFFFF7A36),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                label: 'VICTORIES',
                value: '${summary?.wins ?? 0}',
                accentColor: const Color(0xFF10B981),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                label: 'DEFEATS',
                value: '${summary?.losses ?? 0}',
                accentColor: const Color(0xFFEF4444),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                label: 'WIN RATE',
                value: '${summary?.winRate ?? 0}%',
                accentColor: const Color(0xFF3B82F6),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section header with refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAST 1V1 DUELS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: colors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            IconButton(
              onPressed: () => controller.loadBattleHistory(),
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh History',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (state.isLoadingHistory)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7A36)),
            ),
          )
        else if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 48,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Match History Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter the duel arena to battle other candidates and record your competitive victories!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.switchLobbyTab(0),
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Start First Duel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryCard(item, colors);
            },
          ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color accentColor,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BattleHistoryItem item, AppColors colors) {
    final isVictory = item.outcome.toLowerCase() == 'victory';
    final isDraw = item.outcome.toLowerCase() == 'draw';

    final badgeColor = isVictory
        ? const Color(0xFF10B981)
        : (isDraw ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    final outcomeText = isVictory
        ? 'VICTORY'
        : (isDraw ? 'DRAW' : 'DEFEAT');

    final outcomeIcon = isVictory
        ? Icons.emoji_events
        : (isDraw ? Icons.handshake : Icons.close);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Room/Track & Outcome Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.roomCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.track,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(outcomeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      outcomeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Match matchup & score details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${item.opponentName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.opponentCollege,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.yourScore} - ${item.opponentScore}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      'POINTS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Timestamp
          Text(
            _formatDate(item.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  void _showBuildRoomDialog(BuildContext context) {
    int selectedCapacity = 2;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setState) {
            final colors = modalContext.colors;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A36).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.groups, color: Color(0xFFFF7A36), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Build Battle Room',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'Select room capacity (2 to 8 players)',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ROOM CAPACITY (PLAYERS)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final count = i + 2;
                      final isSelected = selectedCapacity == count;
                      return ChoiceChip(
                        label: Text(
                          '$count ${count == 2 ? "Players (1v1)" : "Players"}',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? Colors.white : colors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF7A36),
                        backgroundColor: colors.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFFF7A36) : colors.border,
                        ),
                        onSelected: (_) => setState(() => selectedCapacity = count),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '1m 30s Assembly Limit: Contestants have 90s to enter room code. Battle auto-starts if full & ready, or host can start as soon as clients are ready (min 2 players).',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      controller.createPrivateRoom(
                        candidateName: 'You',
                        maxPlayers: selectedCapacity,
                      );
                    },
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: Text(
                      'Build Room ($selectedCapacity Players)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A36),
                      foregroundColor: const Color(0xFF542747),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

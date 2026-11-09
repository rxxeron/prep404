import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/battle_controller.dart';

class BattleFinishedView extends StatelessWidget {
  final BattleController controller;
  final BattleState state;

  const BattleFinishedView({
    super.key,
    required this.controller,
    required this.state,
  });

  Future<void> _reportOpponent(BuildContext context) async {
    final isBot = (state.opponentPlayer?.id.startsWith('bot_') ?? false) ||
        (state.roomId?.startsWith('room_bot_') ?? false) ||
        (state.opponentPlayer?.name == 'Prep404 AI Engine');

    if (isBot) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.smart_toy_outlined, color: Color(0xFFFF7A36)),
            SizedBox(width: 8),
            Text('Automated AI Duel'),
          ]),
          content: const Text(
            'This match was played against the automated Prep404 AI Engine (practice bot).\n\n'
            'Practice bots cannot be reported for player misconduct (cheating/harassment).\n\n'
            'If you found a flawed question or equation error, please use the Question Report button.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF7A36)),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    var category = 'cheating';
    final detailsController = TextEditingController();
    final report = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report this battle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Reports are reviewed by the moderation team. Do not include contact details.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'cheating', child: Text('Cheating or unfair play')),
                  DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                  DropdownMenuItem(value: 'inappropriate_name', child: Text('Inappropriate display name')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) { if (value != null) setDialogState(() => category = value); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Details (optional)', hintText: 'Describe what happened.'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, {'category': category, 'details': detailsController.text}), child: const Text('Submit report')),
          ],
        ),
      ),
    );
    if (report != null && context.mounted) {
      try {
        await controller.reportOpponent(category: report['category']!, details: report['details']!);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report sent to the moderation team.')));
      } catch (error) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))));
      }
    }
    detailsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final myScore = state.myPlayer?.score ?? 0;
    final oppScore = state.opponentPlayer?.score ?? 0;

    final isWin = state.isVictory || myScore > oppScore;
    final isDraw = state.isDraw || myScore == oppScore;

    final title = isWin ? '🏆 VICTORY!' : (isDraw ? '🤝 DRAW!' : '⚡ DEFEAT');
    final subtitle = isWin
        ? 'Outstanding performance! You earned +${state.xpEarned} XP and topped your admission tier!'
        : (isDraw
            ? 'Evenly matched! Earned +${state.xpEarned} XP.'
            : 'Good effort! Review the sections and challenge again. Earned +${state.xpEarned} XP.');
    final badgeColor = isWin
        ? const Color(0xFF10B981)
        : (isDraw ? const Color(0xFFFFD166) : colors.dangerRed);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor, width: 2),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),

              // Score Comparison Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          state.myPlayer?.name ?? 'You',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$myScore pts',
                          style: const TextStyle(
                            color: Color(0xFFFF7A36),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'VS',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          state.opponentPlayer?.name ?? 'Opponent',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$oppScore pts',
                          style: TextStyle(
                            color: colors.dangerRed,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () => controller.reset(),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Play Another Match',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A36),
                  foregroundColor: const Color(0xFF542747),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  controller.reset();
                  controller.switchLobbyTab(1);
                },
                icon: const Icon(Icons.history_edu, size: 18),
                label: const Text(
                  'View Player Duel History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: state.roomId == null ? null : () => _reportOpponent(context),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: Text(
                  (state.opponentPlayer?.id.startsWith('bot_') ?? false) ||
                          (state.roomId?.startsWith('room_bot_') ?? false)
                      ? 'AI Practice Bot Match'
                      : 'Report Opponent Misconduct',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

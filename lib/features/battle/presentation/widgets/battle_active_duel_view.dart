import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exam/presentation/widgets/katex_question_view.dart';
import '../controllers/battle_controller.dart';

class BattleActiveDuelView extends StatelessWidget {
  final BattleController controller;
  final BattleState state;

  const BattleActiveDuelView({
    super.key,
    required this.controller,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final me = state.myPlayer;
    final opp = state.opponentPlayer;
    final q = state.currentQuestion;
    if (q == null) return const SizedBox.shrink();

    final isWarning = state.timeRemainingSeconds <= 4;
    final isRoundResult = state.showRoundResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            children: [
              // Current Section Badge
              if (state.currentSection != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A36).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF7A36).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'SECTION: ${state.currentSection!.toUpperCase()} • ROUND ${state.currentQuestionIndex}/${state.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF7A36),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              // Live Battle HUD (Scores + Timer)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  children: [
                    // Player Info (You)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me?.name ?? 'You',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${me?.score ?? 0} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF7A36),
                              fontSize: 20,
                            ),
                          ),
                          if (me?.hasAnswered ?? false)
                            const Text(
                              'Answered ✓',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Center Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isWarning
                            ? colors.dangerRed
                            : colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isWarning ? Colors.white : colors.border,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.timeRemainingSeconds}s',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color:
                                  isWarning ? Colors.white : colors.textPrimary,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${state.currentQuestionIndex}/${state.totalQuestions}',
                            style: TextStyle(
                              color: isWarning
                                  ? Colors.white70
                                  : colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Opponent Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            opp?.name ?? 'Opponent',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${opp?.score ?? 0} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: colors.dangerRed,
                              fontSize: 20,
                            ),
                          ),
                          if (opp?.hasAnswered ?? false)
                            const Text(
                              'Answered ✓',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            Text(
                              'Thinking...',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Round Result Banner (Shown during inter-round summary)
              if (isRoundResult)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Round Result: You +${me?.roundPoints ?? 0} pts',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Opponent +${opp?.roundPoints ?? 0} pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Question Card: Zero Spoiler during active 15s rounds, revealed only during round result summary
              KaTeXQuestionView(
                key: ValueKey('battle_q_${q.id}_round_${state.currentQuestionIndex}'),
                question: isRoundResult && state.correctOptionId != null && state.correctOptionId!.isNotEmpty
                    ? q.copyWith(correctOptionId: state.correctOptionId)
                    : (isRoundResult ? q : q.copyWith(correctOptionId: '')),
                selectedOptionId: state.selectedOptionId,
                onOptionSelected: (optId) {
                  controller.submitAnswer(optId);
                },
                showExplanation: isRoundResult,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/question.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_bounce_tap.dart';
import 'katex_question_view.dart';

/// Authentic Software OMR Bubble Sheet Simulator for Private University Exams
class SoftwareOmrSheetView extends StatelessWidget {
  final String title;
  final String candidateName;
  final String candidateCollege;
  final List<Question> questions;
  final Map<String, String> userAnswers;
  final void Function(String questionId, String optionId) onOptionSelected;
  final VoidCallback onSubmit;
  final void Function(int questionIndex)? onQuestionTap;

  const SoftwareOmrSheetView({
    super.key,
    required this.title,
    this.candidateName = 'Private Uni Candidate',
    this.candidateCollege = 'Notre Dame College',
    required this.questions,
    required this.userAnswers,
    required this.onOptionSelected,
    required this.onSubmit,
    this.onQuestionTap,
  });

  void _previewQuestion(BuildContext context, Question q, int number) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question #$number Preview',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              KaTeXQuestionView(
                question: q,
                questionNumber: number,
                isOmrMode: true,
                selectedOptionId: userAnswers[q.id],
                onOptionSelected: (optId) {
                  onOptionSelected(q.id, optId);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final answeredCount = userAnswers.length;
    final totalCount = questions.length;
    final blankCount = totalCount - answeredCount;

    return Column(
      children: [
        // OMR Paper Header Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colors.accentAmber.withValues(alpha: 0.35)),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.radio_button_checked,
                        color: colors.accentAmber, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREP404 • OMR ANSWER SHEET',
                          style: TextStyle(
                            color: colors.accentAmber,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      'SET-A',
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Candidate: $candidateName',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.accentEmerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Darkened: $answeredCount',
                          style: TextStyle(
                              color: colors.accentEmerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.dangerRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Blank: $blankCount',
                          style: TextStyle(
                              color: colors.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick Instructions Pill
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_outlined,
                  size: 14, color: colors.accentAmber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tap circle to fill with 2B pencil lead. Tap question number [01] to preview math & question.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Main OMR Grid
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final q = questions[index];
              final qNum = index + 1;
              final selectedOpt = userAnswers[q.id];

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedOpt != null
                      ? (context.isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFFEF3C7).withValues(alpha: 0.5))
                      : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedOpt != null
                        ? colors.accentAmber.withValues(alpha: 0.6)
                        : colors.border,
                    width: selectedOpt != null ? 1.5 : 1.0,
                  ),
                  boxShadow: colors.cardShadow,
                ),
                child: Row(
                  children: [
                    // Question Number Button (Tapping opens question preview with bounce feedback)
                    PrepBounceTap(
                      scaleFactor: 0.94,
                      onTap: () {
                        if (onQuestionTap != null) {
                          onQuestionTap!(index);
                        } else {
                          _previewQuestion(context, q, qNum);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedOpt != null
                                ? colors.accentAmber
                                : colors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              qNum < 10 ? '0$qNum' : '$qNum',
                              style: TextStyle(
                                color: selectedOpt != null
                                    ? colors.accentAmber
                                    : colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.remove_red_eye_outlined,
                                size: 12, color: colors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // OMR Bubbles: (A), (B), (C), (D)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['A', 'B', 'C', 'D'].map((letter) {
                          final isSelected = selectedOpt == letter;
                          return PrepBounceTap(
                            scaleFactor: 0.88,
                            enableHaptic: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onOptionSelected(q.id, letter);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? (context.isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF1E293B))
                                    : colors.surfaceElevated,
                                border: Border.all(
                                  color: isSelected
                                      ? colors.accentAmber
                                      : colors.border,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.accentAmber
                                              .withValues(alpha: 0.45),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: isSelected
                                  ? Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            colors.accentAmber,
                                            const Color(0xFFD97706),
                                          ],
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        letter,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      letter,
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom Submission Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: colors.cardShadow,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$answeredCount of $totalCount Bubbles Filled',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalCount == 0
                              ? 0
                              : (answeredCount / totalCount),
                          backgroundColor: colors.surfaceElevated,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(colors.accentAmber),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Submit OMR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

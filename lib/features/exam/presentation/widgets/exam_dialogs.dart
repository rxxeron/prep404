import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ExamSubmitConfirmDialog extends StatelessWidget {
  final int totalQuestions;
  final int answeredCount;
  final VoidCallback onConfirmSubmit;

  const ExamSubmitConfirmDialog({
    super.key,
    required this.totalQuestions,
    required this.answeredCount,
    required this.onConfirmSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unAnswered = totalQuestions - answeredCount;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      title: Text(
        'Submit Examination?',
        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Questions: $totalQuestions',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Answered: $answeredCount',
            style: TextStyle(
              color: colors.accentEmerald,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unanswered: $unAnswered',
            style: TextStyle(
              color: colors.dangerRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            unAnswered > 0
                ? 'Warning: Unanswered questions will receive 0 marks. Submit now?'
                : 'Great job! You have answered all questions. Ready to submit?',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Review', style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmSubmit();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentEmerald,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Confirm & Submit'),
        ),
      ],
    );
  }
}

class ExamQuitConfirmDialog extends StatelessWidget {
  final VoidCallback onQuit;

  const ExamQuitConfirmDialog({
    super.key,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      title: Text('Quit Examination?', style: TextStyle(color: colors.textPrimary)),
      content: Text(
        'If you leave now, your progress will not be saved.',
        style: TextStyle(color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Stay', style: TextStyle(color: colors.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onQuit();
          },
          child: Text('Quit', style: TextStyle(color: colors.dangerRed)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/services/question_report_service.dart';
import '../../../../core/theme/app_theme.dart';

class QuestionReportButton extends StatelessWidget {
  final String questionId;

  const QuestionReportButton({super.key, required this.questionId});

  @override
  Widget build(BuildContext context) {
    if (!RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(questionId)) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _showReportDialog(context),
        icon: Icon(Icons.flag_outlined, size: 17, color: colors.textSecondary),
        label: Text('Report a problem',
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final description = TextEditingController();
    var category = QuestionReportService.categories.keys.first;
    var saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Report a question'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Issue type'),
                  items: QuestionReportService.categories.entries
                      .map((entry) => DropdownMenuItem(
                          value: entry.key, child: Text(entry.value)))
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                      labelText: 'What seems wrong?',
                      hintText: 'Do not include personal information.'),
                  validator: (value) =>
                      (value == null || value.trim().length < 5)
                          ? 'Please add at least 5 characters.'
                          : null,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await QuestionReportService().submit(
                            questionId: questionId,
                            category: category,
                            description: description.text);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Thanks. Your report was sent to the content review team.')));
                      } catch (exception) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          saving = false;
                          error = exception
                              .toString()
                              .replaceFirst('Exception: ', '')
                              .replaceFirst('StateError: ', '');
                          if (error!.contains('duplicate key') ||
                              error!.contains(
                                  'question_reports_one_open_per_reporter_idx')) {
                            error =
                                'You already have an open report for this question.';
                          }
                        });
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(saving ? 'Sending…' : 'Send report'),
            ),
          ],
        ),
      ),
    );
    description.dispose();
  }
}

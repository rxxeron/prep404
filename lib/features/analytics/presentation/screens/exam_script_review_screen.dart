import 'package:flutter/material.dart';
import '../../../../core/models/question.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exam/presentation/widgets/katex_question_view.dart';
import '../../data/models/exam_history_item.dart';

enum ScriptFilter { all, mistakes, correct, skipped }

class ExamScriptReviewScreen extends StatefulWidget {
  final ExamHistoryItem item;

  const ExamScriptReviewScreen({super.key, required this.item});

  @override
  State<ExamScriptReviewScreen> createState() => _ExamScriptReviewScreenState();
}

class _ExamScriptReviewScreenState extends State<ExamScriptReviewScreen> {
  ScriptFilter _filter = ScriptFilter.all;
  late List<Question> _questions;
  bool _isLoadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _questions = List<Question>.from(widget.item.questions);
    final needsEnrichment =
        _questions.isEmpty || _questions.any((q) => q.correctOptionId.isEmpty);
    if (needsEnrichment) {
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoadingQuestions = true);
    try {
      // 1. Fetch submission review with verified answers & predefined explanations
      if (widget.item.id.isNotEmpty) {
        final reviewQuestions = await ExamRepository().fetchSubmissionReview(
          widget.item.id,
          examId: widget.item.examId,
        );
        if (mounted && reviewQuestions.isNotEmpty) {
          setState(() {
            _questions = reviewQuestions;
            _isLoadingQuestions = false;
          });
          return;
        }
      }

      // 2. Fallback to exam slug/id questions
      if (widget.item.examId != null && widget.item.examId!.isNotEmpty) {
        final exam =
            await ExamRepository().fetchExamBySlug(widget.item.examId!);
        if (mounted && exam != null && exam.questions.isNotEmpty) {
          setState(() {
            _questions = exam.questions;
            _isLoadingQuestions = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingQuestions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = widget.item;

    final filteredQuestions = _questions.where((q) {
      final userAns = item.userAnswers[q.id] ?? q.userAnswer;
      final correctKey = q.effectiveCorrectOptionId;
      if (_filter == ScriptFilter.mistakes) {
        return userAns != null &&
            userAns.isNotEmpty &&
            (correctKey.isNotEmpty ? userAns.toUpperCase() != correctKey.toUpperCase() : true);
      } else if (_filter == ScriptFilter.correct) {
        return userAns != null &&
            correctKey.isNotEmpty &&
            userAns.toUpperCase() == correctKey.toUpperCase();
      } else if (_filter == ScriptFilter.skipped) {
        return userAns == null || userAns.isEmpty;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${item.date} • Score: ${item.score.toStringAsFixed(1)}/${item.totalMarks.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colors.surface,
            child: Row(
              children: [
                _buildFilterChip(
                  'All (${_questions.length})',
                  ScriptFilter.all,
                  colors,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Mistakes (${item.wrongCount})',
                  ScriptFilter.mistakes,
                  colors,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Correct (${item.correctCount})',
                  ScriptFilter.correct,
                  colors,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Skipped (${item.skippedCount})',
                  ScriptFilter.skipped,
                  colors,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Question Scripts List
          Expanded(
            child: _isLoadingQuestions
                ? const Center(child: CircularProgressIndicator())
                : filteredQuestions.isEmpty
                    ? Center(
                        child: Text(
                          'No questions in this filter view.',
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary),
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, idx) {
                      final q = filteredQuestions[idx];
                      final correctKey = q.effectiveCorrectOptionId;
                      final userAns = item.userAnswers[q.id] ?? q.userAnswer;
                      final isCorrect = userAns != null &&
                          correctKey.isNotEmpty &&
                          userAns.toUpperCase() == correctKey.toUpperCase();
                      final isMistake =
                          userAns != null && userAns.isNotEmpty && !isCorrect;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Answer Status Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question #${idx + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? const Color(0xFFECFDF5)
                                        : (isMistake
                                            ? const Color(0xFFFEF2F2)
                                            : colors.surfaceElevated),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCorrect
                                        ? 'Correct (+${q.marks})'
                                        : (isMistake
                                            ? 'Incorrect (-${q.negativeMarks}) • You selected ($userAns)'
                                            : 'Skipped (0.0)'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCorrect
                                          ? const Color(0xFF059669)
                                          : (isMistake
                                              ? const Color(0xFFDC2626)
                                              : colors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Render KaTeX Question Stem, Options, and Detailed Explanation
                            KaTeXQuestionView(
                              question: q,
                              questionNumber: idx + 1,
                              selectedOptionId: userAns,
                              showExplanation: true,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ScriptFilter targetFilter,
    AppColors colors,
  ) {
    final isSelected = _filter == targetFilter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = targetFilter),
      selectedColor: colors.tangerine,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : colors.textSecondary,
      ),
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(
        color: isSelected ? colors.tangerine : colors.borderSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}

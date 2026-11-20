import 'package:flutter/material.dart';
import '../../../../core/repositories/printable_omr_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/printable_omr_pdf_service.dart';

/// Opened immediately after scanning a printed Prep404 OMR QR code (or entering its Set Code).
/// Displays the official Answer Key, lets the student check & save their offline paper score,
/// and browse full solutions.
class OmrPackResultScreen extends StatefulWidget {
  final PrintableOmrPack pack;

  const OmrPackResultScreen({super.key, required this.pack});

  @override
  State<OmrPackResultScreen> createState() => _OmrPackResultScreenState();
}

class _OmrPackResultScreenState extends State<OmrPackResultScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, String> _selectedAnswers = {};
  late List<Map<String, dynamic>> _attempts;
  bool _isSaving = false;
  bool _isPrinting = false;
  bool _showOfficialKey = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _attempts = List<Map<String, dynamic>>.from(widget.pack.previousAttempts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ({int correct, int wrong, int skipped, double score, int accuracy})
      _computeLiveStats() {
    int correct = 0;
    int wrong = 0;
    final key = widget.pack.answerKey;
    for (final entry in _selectedAnswers.entries) {
      final expected = key[entry.key]?.toUpperCase();
      if (expected == null) continue;
      if (entry.value.toUpperCase() == expected) {
        correct++;
      } else {
        wrong++;
      }
    }
    final total = widget.pack.totalQuestions;
    final skipped = (total - correct - wrong).clamp(0, total);
    final score = correct - (wrong * widget.pack.negativeMark);
    final answered = correct + wrong;
    final accuracy = answered == 0 ? 0 : ((correct / answered) * 100).round();
    return (
      correct: correct,
      wrong: wrong,
      skipped: skipped,
      score: score,
      accuracy: accuracy,
    );
  }

  Future<void> _saveAttempt() async {
    if (_selectedAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap your marked answers first to record your offline score.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await PrintableOmrRepository().submitOfflineAttempt(
        shortCode: widget.pack.shortCode,
        answers: _selectedAnswers,
      );
      if (!mounted) return;
      setState(() {
        _attempts = [saved, ..._attempts];
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved! Score: ${(saved['score'] as num?)?.toStringAsFixed(2) ?? '0'} / ${widget.pack.totalQuestions}',
          ),
          backgroundColor: context.colors.accentEmerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: context.colors.dangerRed,
        ),
      );
    }
  }

  Future<void> _reprintPdf() async {
    setState(() => _isPrinting = true);
    try {
      await PrintableOmrPdfService.previewAndPrint(widget.pack);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF preview: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stats = _computeLiveStats();
    final negText = widget.pack.negativeMark > 0
        ? '-${widget.pack.negativeMark.toStringAsFixed(2)}'
        : 'None';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pack.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${widget.pack.shortCode} • ${widget.pack.totalQuestions} Qs • Penalty: $negText',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Print / Save PDF',
            onPressed: _isPrinting ? null : _reprintPdf,
            icon: _isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.picture_as_pdf_rounded, color: colors.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Answer Key & Score'),
            Tab(text: 'Full Solutions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnswerKeyAndRecordTab(colors, stats),
          _buildSolutionsTab(colors),
        ],
      ),
    );
  }

  Widget _buildAnswerKeyAndRecordTab(
    AppColors colors,
    ({int correct, int wrong, int skipped, double score, int accuracy}) stats,
  ) {
    return Column(
      children: [
        // Live score summary strip
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statTile('Score', stats.score.toStringAsFixed(2), colors.primary, colors),
                  _statTile('Correct', '${stats.correct}', colors.accentEmerald, colors),
                  _statTile('Wrong', '${stats.wrong}', colors.dangerRed, colors),
                  _statTile('Accuracy', '${stats.accuracy}%', colors.textPrimary, colors),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showOfficialKey = !_showOfficialKey),
                      icon: Icon(
                        _showOfficialKey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                      ),
                      label: Text(
                        _showOfficialKey ? 'Hide Key' : 'Show Key',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAttempt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentEmerald,
                        foregroundColor: Colors.white,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_alt_rounded, size: 17),
                      label: const Text(
                        'Save Practice Record',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (_attempts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Recorded Offline Attempts (${_attempts.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 62,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attempts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final att = _attempts[idx];
                      final sc = (att['score'] as num?)?.toStringAsFixed(2) ?? '0';
                      final acc = (att['accuracyPercent'] as num?)?.round() ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors.accentEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.accentEmerald.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Score: $sc / ${widget.pack.totalQuestions}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              '${att['correctCount'] ?? 0}✓  ${att['wrongCount'] ?? 0}✗  •  $acc%',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Text(
                'Tap your paper answers below to auto-check against the official key:',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 8),

              ...List.generate(widget.pack.totalQuestions, (index) {
                final qKey = '${index + 1}';
                final expected = widget.pack.answerKey[qKey]?.toUpperCase() ?? '';
                final chosen = _selectedAnswers[qKey];
                final isCorrect = chosen != null && chosen == expected;
                final isWrong = chosen != null && chosen != expected;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? colors.accentEmerald.withValues(alpha: 0.5)
                          : (isWrong
                              ? colors.dangerRed.withValues(alpha: 0.5)
                              : colors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          qKey.padLeft(2, '0'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['A', 'B', 'C', 'D'].map((letter) {
                            final isPicked = chosen == letter;
                            final isAnswer = _showOfficialKey && expected == letter;
                            Color bg = colors.background;
                            Color fg = colors.textSecondary;
                            Color border = colors.border;

                            if (isPicked && isCorrect) {
                              bg = colors.accentEmerald;
                              fg = Colors.white;
                              border = colors.accentEmerald;
                            } else if (isPicked && isWrong) {
                              bg = colors.dangerRed;
                              fg = Colors.white;
                              border = colors.dangerRed;
                            } else if (isAnswer) {
                              bg = colors.accentEmerald.withValues(alpha: 0.16);
                              fg = colors.accentEmerald;
                              border = colors.accentEmerald;
                            }

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (_selectedAnswers[qKey] == letter) {
                                    _selectedAnswers.remove(qKey);
                                  } else {
                                    _selectedAnswers[qKey] = letter;
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: border, width: 1.4),
                                ),
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: fg,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (_showOfficialKey && expected.isNotEmpty)
                        Container(
                          width: 36,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Key $expected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colors.accentEmerald,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSolutionsTab(AppColors colors) {
    if (widget.pack.questions.isEmpty) {
      return Center(
        child: Text(
          'No detailed question snapshots available for this set.',
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.pack.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final q = widget.pack.questions[idx];
        final expected = (q.correctOption ?? widget.pack.answerKey['${q.order}'] ?? '')
            .toUpperCase();
        final chosen = _selectedAnswers['${q.order}'];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Q${q.order} • ${q.subjectName}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (expected.isNotEmpty)
                    Text(
                      'Answer: $expected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.accentEmerald,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                q.questionText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ...q.options.map((opt) {
                final id = opt['id'] ?? '';
                final isRight = id.toUpperCase() == expected;
                final isUserWrong = chosen == id && !isRight;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRight
                        ? colors.accentEmerald.withValues(alpha: 0.12)
                        : (isUserWrong
                            ? colors.dangerRed.withValues(alpha: 0.1)
                            : colors.background),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRight
                          ? colors.accentEmerald
                          : (isUserWrong ? colors.dangerRed : colors.border),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '($id) ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRight
                              ? colors.accentEmerald
                              : (isUserWrong
                                  ? colors.dangerRed
                                  : colors.textPrimary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          opt['text'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (q.solutionMarkdown != null &&
                  q.solutionMarkdown!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accentAmber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.accentAmber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.accentAmber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.solutionMarkdown!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statTile(String label, String value, Color valueColor, AppColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
      ],
    );
  }
}

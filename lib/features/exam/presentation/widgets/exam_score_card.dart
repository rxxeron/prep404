import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/animations/prep_lottie.dart';
import '../../../../core/models/question.dart';
import '../../../../core/theme/app_theme.dart';
import 'katex_question_view.dart';

/// Comprehensive Scorecard, University Cut-Off Benchmark & Socratic Review
class ExamScoreCard extends StatefulWidget {
  final String title;
  final String slug;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int timeTakenSeconds;
  final int nationalRank;
  final int totalCandidates;
  final List<Question> questions;
  final Map<String, String> userAnswers;
  final VoidCallback onExit;
  final bool isPractice;
  final double negativeMark;

  const ExamScoreCard({
    super.key,
    required this.title,
    required this.slug,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.timeTakenSeconds,
    required this.nationalRank,
    required this.totalCandidates,
    required this.questions,
    required this.userAnswers,
    required this.onExit,
    this.isPractice = false,
    this.negativeMark = 0.0,
  });

  @override
  State<ExamScoreCard> createState() => _ExamScoreCardState();
}

class _ExamScoreCardState extends State<ExamScoreCard> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Map<String, _SubjectStats> _computeSubjectBreakdown() {
    final Map<String, _SubjectStats> stats = {};

    for (final q in widget.questions) {
      final subjectName = _mapSubjectName(q.subjectId);
      final entry = stats.putIfAbsent(
          subjectName, () => _SubjectStats(name: subjectName));
      entry.total++;

      final userAns = widget.userAnswers[q.id];
      if (userAns != null) {
        if (userAns == q.correctOptionId) {
          entry.correct++;
        } else {
          entry.wrong++;
        }
      }
    }

    return stats;
  }

  String _mapSubjectName(String subjectId) {
    switch (subjectId) {
      case 'sub_quant_math':
      case 'general_mathematics':
      case '5f32fe4a-c1b8-4b99-b657-8121b6468633':
        return 'General Mathematics';
      case 'sub_higher_math':
      case 'higher_mathematics':
      case 'ac4a67c7-c9aa-4832-9949-6c370c11fda9':
        return 'Higher Mathematics';
      case 'sub_english_priv':
      case 'english':
      case 'af1cdf97-8331-459a-9df1-2521f87e54e6':
        return 'English Language';
      case 'sub_physics':
      case 'physics':
      case '54a032b0-980e-4258-a9c1-d972acae4268':
        return 'Physics';
      case 'chemistry':
      case '1511ecca-60f3-4515-a7ee-1fb447a8dec0':
        return 'Chemistry';
      case 'biology':
      case 'ebed0cbf-c4a3-477a-a5a0-243694bc8766':
        return 'Biology';
      default:
        return 'Core Knowledge';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shareText = widget.isPractice
        ? 'I practiced "${widget.title}" on Prep404 and scored ${widget.score.toStringAsFixed(2)}/${widget.totalQuestions} (${widget.correctCount} correct, ${widget.wrongCount} wrong).'
        : 'I scored ${widget.score.toStringAsFixed(2)}/${widget.totalQuestions} (Rank #${widget.nationalRank} of ${widget.totalCandidates}) on "${widget.title}" on Prep404!';

    final answeredTotal = widget.correctCount + widget.wrongCount;
    final accuracy = answeredTotal == 0
        ? 0
        : ((widget.correctCount / answeredTotal) * 100).toInt();

    final subjectBreakdown = _computeSubjectBreakdown();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        title: Text(
          'Diagnostic Marksheet & Analytics',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontSize: 16),
        ),
        actions: const [
          ThemeToggleIconButton(),
          SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: widget.onExit,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Score Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.isDark
                          ? const [Color(0xFF542747), Color(0xFF1E293B)]
                          : const [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      PrepLottie.success(size: 64, loop: false),
                      const SizedBox(height: 6),
                      Text(
                        widget.isPractice
                            ? '🎯 UNRANKED PRACTICE MODE'
                            : '🎉 MODEL TEST COMPLETED',
                        style: const TextStyle(
                          color: Color(0xFFD1FAE5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Time Taken: ${widget.timeTakenSeconds ~/ 60}m ${widget.timeTakenSeconds % 60}s',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.score.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.totalQuestions}',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Mini Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('Correct', '${widget.correctCount}',
                                const Color(0xFF34D399)),
                            Container(
                                width: 1, height: 24, color: Colors.white24),
                            _buildMiniStat('Wrong', '${widget.wrongCount}',
                                const Color(0xFFF87171)),
                            Container(
                                width: 1, height: 24, color: Colors.white24),
                            _buildMiniStat(
                                'Accuracy', '$accuracy%', Colors.white),
                            Container(
                                width: 1, height: 24, color: Colors.white24),
                            _buildMiniStat(
                              'Rank',
                              widget.isPractice
                                  ? 'Practice'
                                  : '#${widget.nationalRank}',
                              widget.isPractice
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFFFBBF24),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Attempt Pacing & Accuracy Summary (100% real telemetry, zero hardcoded cut-offs)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assessment_outlined,
                              color: colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Attempt Summary',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildRealMetricRow(
                        'Questions Attempted',
                        '$answeredTotal / ${widget.totalQuestions}',
                        colors,
                      ),
                      const SizedBox(height: 10),
                      _buildRealMetricRow(
                        'Unanswered / Skipped',
                        '${widget.totalQuestions - answeredTotal}',
                        colors,
                      ),
                      const SizedBox(height: 10),
                      _buildRealMetricRow(
                        'Average Pace',
                        answeredTotal > 0
                            ? '${(widget.timeTakenSeconds / answeredTotal).round()}s per question'
                            : '—',
                        colors,
                      ),
                      const SizedBox(height: 10),
                      _buildRealMetricRow(
                        'Negative Marking',
                        widget.negativeMark == 0
                            ? 'None (0.00)'
                            : '-${widget.negativeMark.toStringAsFixed(2)} per wrong answer',
                        colors,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Subject-wise Strength Breakdown
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart_outline,
                              color: colors.accentAmber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Subject-wise Strength Breakdown',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...subjectBreakdown.values.map((stat) {
                        final rawSub = (stat.correct * 1.0) -
                            (stat.wrong * widget.negativeMark);
                        final subScore = rawSub < 0 ? 0.0 : rawSub;
                        final subAccuracy = stat.correct + stat.wrong == 0
                            ? 0
                            : ((stat.correct / (stat.correct + stat.wrong)) *
                                    100)
                                .toInt();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(stat.name,
                                      style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    '${subScore.toStringAsFixed(1)} / ${stat.total} ($subAccuracy%)',
                                    style: TextStyle(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: stat.total == 0
                                      ? 0
                                      : (stat.correct / stat.total),
                                  backgroundColor: colors.surfaceElevated,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    subAccuracy >= 70
                                        ? colors.accentEmerald
                                        : colors.primary,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Shareable Link & Challenge Friends
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: colors.accentEmerald.withValues(alpha: 0.4)),
                    boxShadow: colors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.share,
                              color: colors.accentEmerald, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Share Your Score Summary',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shareText,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Score summary copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Score Summary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Review Questions & Socratic Explanations
                Text(
                  'Detailed Question Solutions & Peer Analytics',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, idx) {
                    final q = widget.questions[idx];
                    final userAns = widget.userAnswers[q.id];
                    return KaTeXQuestionView(
                      question: q,
                      questionNumber: idx + 1,
                      selectedOptionId: userAns,
                      showExplanation: true,
                    );
                  },
                ),
              ],
            ),
          ),
          // Confetti Celebration Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF059669),
                Color(0xFFF59E0B),
                Color(0xFFFF7A36),
                Color(0xFFFFD166),
                Color(0xFF10B981),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealMetricRow(String label, String value, AppColors colors) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: colors.primary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _SubjectStats {
  final String name;
  int total = 0;
  int correct = 0;
  int wrong = 0;

  _SubjectStats({required this.name});
}

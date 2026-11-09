import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/config/app_config.dart';
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
    final cleanSlug = widget.slug.contains('_daily_slot')
        ? 'daily-${widget.slug.replaceAll('_daily_slot', '').replaceAll('_daily', '')}-live'
        : widget.slug;
    final shareUrl = '${AppConfig.webBaseUrl}/m/$cleanSlug';
    final shareText = widget.isPractice
        ? 'I practiced "${widget.title}" on Prep404 and scored ${widget.score.toStringAsFixed(2)}/${widget.totalQuestions}! Challenge yourself here: $shareUrl'
        : 'I scored ${widget.score.toStringAsFixed(2)}/${widget.totalQuestions} (Rank #${widget.nationalRank} of ${widget.totalCandidates}) on today\'s ${widget.title}! Can you beat me? $shareUrl';

    final answeredTotal = widget.correctCount + widget.wrongCount;
    final accuracy = answeredTotal == 0
        ? 0
        : ((widget.correctCount / answeredTotal) * 100).toInt();
    final scorePercentage = widget.totalQuestions == 0
        ? 0
        : ((widget.score / widget.totalQuestions) * 100).toInt();

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

                // 2. Admission Benchmark Evaluation
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
                            'University Cut-Off Benchmark',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildBenchmarkRow('BRAC University (CSE/EEE)', 68,
                          scorePercentage, colors),
                      const SizedBox(height: 10),
                      _buildBenchmarkRow('North South University (SEPS)', 65,
                          scorePercentage, colors),
                      const SizedBox(height: 10),
                      _buildBenchmarkRow('Independent University (SETS)', 60,
                          scorePercentage, colors),
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
                        final subScore =
                            (stat.correct * 1.0) - (stat.wrong * 0.25);
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
                            'Challenge Friends with this Test',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shareUrl,
                        style: TextStyle(
                            color: colors.accentEmerald,
                            fontFamily: 'monospace',
                            fontSize: 12),
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
                                      'Result and model test link copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Score & Challenge Link'),
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

  Widget _buildBenchmarkRow(
      String uniName, int cutOffPercent, int userPercent, AppColors colors) {
    final passed = userPercent >= cutOffPercent;
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: passed ? colors.accentEmerald : colors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            uniName,
            style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          'Cut-off: $cutOffPercent% • You: $userPercent%',
          style: TextStyle(
            color: passed ? colors.accentEmerald : colors.textSecondary,
            fontSize: 12,
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

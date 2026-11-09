import 'package:flutter/material.dart';
import '../../../../core/models/question.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exam/presentation/screens/live_model_test_screen.dart';
import '../../../exam/presentation/widgets/katex_question_view.dart';

class MistakeVaultScreen extends StatefulWidget {
  final String? userId;

  const MistakeVaultScreen({super.key, this.userId});

  @override
  State<MistakeVaultScreen> createState() => _MistakeVaultScreenState();
}

class _MistakeVaultScreenState extends State<MistakeVaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  int _totalMistakes = 0;
  int _totalSkipped = 0;
  List<Map<String, dynamic>> _weakTopics = [];
  List<Question> _mistakes = [];
  List<Question> _skipped = [];

  String? _optimizingTopicId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVaultData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVaultData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUserId = widget.userId ?? SupabaseService().currentUser?.id;
    final summary =
        await ExamRepository().fetchUserVaultSummary(userId: currentUserId);

    if (!mounted) return;

    if (summary == null || summary['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load your personal vault. Please check your connection and retry.';
      });
      return;
    }

    final rawWeakTopics = summary['weakTopics'] as List? ?? [];
    final rawMistakes = summary['mistakes'] as List? ?? [];
    final rawSkipped = summary['skipped'] as List? ?? [];

    setState(() {
      _totalMistakes = (summary['totalMistakes'] as num?)?.toInt() ?? 0;
      _totalSkipped = (summary['totalSkipped'] as num?)?.toInt() ?? 0;
      _weakTopics = rawWeakTopics.map((t) => Map<String, dynamic>.from(t as Map)).toList();
      _mistakes = rawMistakes
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
      _skipped = rawSkipped
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _launchAdaptiveReTest(Map<String, dynamic> topic) async {
    final topicId = topic['topicId']?.toString() ?? '';
    final topicName = topic['topicName']?.toString() ?? 'Topic Mastery';

    if (topicId.isEmpty) return;

    setState(() => _optimizingTopicId = topicId);

    try {
      final liveQuestions = await ExamRepository()
          .fetchTopicPracticeQuestions(topicId, limit: 15);

      if (!mounted) return;

      if (liveQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No practice questions found in database for this topic yet.',
            ),
          ),
        );
        setState(() => _optimizingTopicId = null);
        return;
      }

      setState(() => _optimizingTopicId = null);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveModelTestScreen(
            slug: 'vault_opt_$topicId',
            title: 'Adaptive Re-Test: $topicName',
            isPracticeMode: true,
            initialQuestions: liveQuestions,
            onExit: () {
              Navigator.of(context).pop();
              _loadVaultData(); // Refresh after practice
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _optimizingTopicId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load live adaptive questions.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              'Mistake & Skipped Vault',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              'Personalized Error Deficit & Topic Optimization',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 44, color: colors.dangerRed),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadVaultData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Overview Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: colors.surface,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Active Mistakes',
                              value: '$_totalMistakes',
                              icon: Icons.cancel_outlined,
                              color: const Color(0xFFDC2626),
                              bgColor: const Color(0xFFFEF2F2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Skipped Questions',
                              value: '$_totalSkipped',
                              icon: Icons.skip_next_outlined,
                              color: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFFFBEB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Weak Topics',
                              value: '${_weakTopics.length}',
                              icon: Icons.trending_down_outlined,
                              color: const Color(0xFF7C3AED),
                              bgColor: const Color(0xFFF5F3FF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation Tabs
                    Container(
                      color: colors.surface,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: colors.tangerine,
                        indicatorWeight: 3,
                        labelColor: colors.tangerine,
                        unselectedLabelColor: colors.textSecondary,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        tabs: [
                          Tab(text: 'Weak Topics (${_weakTopics.length})'),
                          Tab(text: 'Mistakes ($_totalMistakes)'),
                          Tab(text: 'Skipped ($_totalSkipped)'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildWeakTopicsTab(colors),
                          _buildQuestionsList(_mistakes, 'No mistakes recorded yet. Keep taking exams to track weak points!', colors),
                          _buildQuestionsList(_skipped, 'No skipped questions found in your history.', colors),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Ranked Weak Topics with Live DB Re-Test Action
  Widget _buildWeakTopicsTab(AppColors colors) {
    if (_weakTopics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars, size: 52, color: colors.accentEmerald),
              const SizedBox(height: 12),
              Text(
                'No Weak Topics Detected!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You have not made significant mistakes or skips yet. Your performance across topics is well-balanced.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _weakTopics.length,
      itemBuilder: (context, idx) {
        final t = _weakTopics[idx];
        final rank = t['rank'] ?? (idx + 1);
        final topicTitle = t['topicName']?.toString() ?? 'Grammar & Usage';
        final subjectTitle = t['subjectName']?.toString() ?? 'English';
        final wrongCount = (t['wrongCount'] as num?)?.toInt() ?? 0;
        final skippedCount = (t['skippedCount'] as num?)?.toInt() ?? 0;
        final deficitScore = (t['deficitScore'] as num?)?.toInt() ?? 0;
        final isOptimizing = _optimizingTopicId == t['topicId'];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: rank == 1
                  ? const Color(0xFFFCA5A5)
                  : colors.borderSubtle,
              width: rank == 1 ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Rank badge & Subject
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFDC2626)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rank #$rank Deficit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: rank == 1 ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subjectTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Impact Score: $deficitScore',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Topic Name
              Text(
                topicTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Badges: Mistakes & Skipped breakdown
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$wrongCount Mistakes',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$skippedCount Skipped',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recommendation Prompt
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Color(0xFFF97316)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You made $wrongCount mistakes and skipped $skippedCount questions here. Re-test this topic with live database questions to optimize your readiness.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action CTA: Optimize & Re-Test Live DB
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isOptimizing ? null : () => _launchAdaptiveReTest(t),
                  icon: isOptimizing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(
                    isOptimizing
                        ? 'Querying Live Database...'
                        : 'Optimize This Topic (15 Questions)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.tangerine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 2 & 3: Questions List with Green Highlight & Predefined Solutions
  Widget _buildQuestionsList(
    List<Question> questions,
    String emptyMessage,
    AppColors colors,
  ) {
    if (questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: colors.accentEmerald),
              const SizedBox(height: 10),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: questions.length,
      itemBuilder: (context, idx) {
        final q = questions[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge header
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
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Verified Answer: (${q.correctOptionId})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Render KaTeX stem, green correct answer & predefined explanation
              KaTeXQuestionView(
                question: q,
                questionNumber: idx + 1,
                selectedOptionId: null,
                showExplanation: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

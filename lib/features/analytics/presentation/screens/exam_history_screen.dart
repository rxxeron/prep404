import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/question.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../../core/widgets/prep_state_views.dart';
import '../../data/models/exam_history_item.dart';
import '../widgets/exam_history_components.dart';
import 'exam_script_review_screen.dart';
import 'mistake_vault_screen.dart';

class ExamHistoryScreen extends StatefulWidget {
  final String? userId;
  final VoidCallback onPracticeMistakes;
  final bool isEnglish;

  const ExamHistoryScreen({
    super.key,
    this.userId,
    required this.onPracticeMistakes,
    this.isEnglish = true,
  });

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

enum AnalyticsScope {
  overall,
  daily,
  university,
  questionBank,
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _mistakeCount = 0;
  int _skippedCount = 0;
  List<ExamHistoryItem> _historyList = [];
  bool _isLoading = true;
  AnalyticsScope _selectedScope = AnalyticsScope.overall;
  String _selectedUniversityFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final localScripts = CacheService().loadExamScripts();
    final items = <ExamHistoryItem>[];
    final seenIds = <String>{};

    // 1. Fetch remote submissions from Supabase
    if (SupabaseService().isInitialized) {
      try {
        final remoteRows =
            await SupabaseService().fetchExamSubmissions(widget.userId);
        for (final row in remoteRows) {
          final id = row['id']?.toString() ?? '';
          if (id.isEmpty) continue;
          seenIds.add(id);

          final examId = row['exam_id']?.toString();
          final examData = row['exams'] is Map ? (row['exams'] as Map) : null;
          final examTitle =
              examData?['title']?.toString() ?? 'Admission Model Test';
          final totalMarks =
              (examData?['total_marks'] as num?)?.toDouble() ?? 50.0;
          final negativeMarkPerQ =
              (examData?['negative_mark_per_question'] as num?)?.toDouble() ??
                  0.25;

          final userAnswersRaw = row['answers'] as Map? ?? {};
          final userAnswersMap = userAnswersRaw
              .map((k, v) => MapEntry(k.toString(), v.toString()));

          final score = (row['score'] as num?)?.toDouble() ?? 0.0;
          final correct = (row['correct_count'] as num?)?.toInt() ?? 0;
          final wrong = (row['wrong_count'] as num?)?.toInt() ?? 0;
          final unanswered = (row['unanswered_count'] as num?)?.toInt() ?? 0;
          final totalQ = correct + wrong + unanswered;

          // 1. Prioritize remote questions_snapshot for this exact attempt
          List<Question> questionsList = [];
          final snapshotRaw = row['questions_snapshot'] as List? ?? [];
          if (snapshotRaw.isNotEmpty) {
            questionsList = snapshotRaw.map((q) {
              if (q is Map<String, dynamic>) return Question.fromJson(q);
              if (q is Map) return Question.fromJson(Map<String, dynamic>.from(q));
              return Question.fromJson({});
            }).toList();
          }

          // 2. Otherwise match local snapshot strictly by submission ID
          if (questionsList.isEmpty) {
            for (final s in localScripts) {
              if (s['id'] == id || s['submissionId'] == id) {
                final rawQ = s['questions'] as List? ?? [];
                questionsList = rawQ.map((q) {
                  if (q is Map<String, dynamic>) return Question.fromJson(q);
                  if (q is Map) {
                    return Question.fromJson(Map<String, dynamic>.from(q));
                  }
                  return Question.fromJson({});
                }).toList();
                if (questionsList.isNotEmpty) break;
              }
            }
          }

          final submittedIso = row['submitted_at']?.toString();
          final uCode = _detectUniversityCode(row['university_code']?.toString(), examTitle, examId);
          final isPracticeMode = row['is_practice'] == true;

          items.add(
            ExamHistoryItem(
              id: id,
              examId: examId,
              title: examTitle,
              date: _formatDate(submittedIso),
              score: score,
              totalMarks: totalMarks,
              totalQuestions: totalQ > 0 ? totalQ : 50,
              correctCount: correct,
              wrongCount: wrong,
              negativeMark: wrong * negativeMarkPerQ,
              skippedCount: unanswered,
              timeTakenSeconds:
                  (row['time_taken_seconds'] as num?)?.toInt() ?? 0,
              rank: (row['rank'] as num?)?.toInt() ?? 1,
              totalCandidates: 1,
              isPassed: score >= (totalMarks * 0.40),
              questions: questionsList,
              userAnswers: userAnswersMap,
              universityCode: uCode,
              isPractice: isPracticeMode,
              submittedAt: submittedIso != null ? DateTime.tryParse(submittedIso) : null,
            ),
          );
        }
      } catch (_) {}
    }

    // 2. Merge local-only scripts (e.g. offline attempts)
    for (final s in localScripts) {
      final id = s['id']?.toString() ?? '';
      if (id.isNotEmpty && seenIds.contains(id)) continue;

      final questionsRaw = (s['questions'] as List? ?? []);
      final questionsList = questionsRaw.map((q) {
        if (q is Map<String, dynamic>) {
          return Question.fromJson(q);
        } else if (q is Map) {
          return Question.fromJson(Map<String, dynamic>.from(q));
        }
        return Question.fromJson({});
      }).toList();

      final userAnswersRaw = s['userAnswers'] as Map? ?? {};
      final userAnswersMap =
          userAnswersRaw.map((k, v) => MapEntry(k.toString(), v.toString()));

      final examTitle = s['examTitle']?.toString() ?? 'Model Test';
      final examIdVal = s['examId']?.toString() ?? s['examSlug']?.toString();
      final dateIso = s['date']?.toString();
      final uCode = _detectUniversityCode(s['universityCode']?.toString(), examTitle, examIdVal);
      final isPracticeMode = s['isPractice'] == true;

      items.add(
        ExamHistoryItem(
          id: id,
          examId: examIdVal,
          title: examTitle,
          date: _formatDate(dateIso),
          score: (s['score'] as num?)?.toDouble() ?? 0.0,
          totalMarks: (s['totalMarks'] as num?)?.toDouble() ?? 50.0,
          totalQuestions: (s['totalQuestions'] as num?)?.toInt() ?? 50,
          correctCount: (s['correctCount'] as num?)?.toInt() ?? 0,
          wrongCount: (s['wrongCount'] as num?)?.toInt() ?? 0,
          negativeMark: (s['negativeMark'] as num?)?.toDouble() ?? 0.0,
          skippedCount: (s['skippedCount'] as num?)?.toInt() ?? 0,
          timeTakenSeconds: (s['timeTakenSeconds'] as num?)?.toInt() ?? 0,
          rank: (s['rank'] as num?)?.toInt() ?? 1,
          totalCandidates: (s['totalCandidates'] as num?)?.toInt() ?? 1,
          isPassed: s['isPassed'] as bool? ?? false,
          questions: questionsList,
          userAnswers: userAnswersMap,
          universityCode: uCode,
          isPractice: isPracticeMode,
          submittedAt: dateIso != null ? DateTime.tryParse(dateIso) : null,
        ),
      );
    }

    // 2. Fetch user-specific mistake & skipped counts from Vault
    int mistakesCount = 0;
    int skippedCount = 0;
    final effectiveUid = widget.userId ?? SupabaseService().currentUser?.id;
    if (effectiveUid != null && effectiveUid.isNotEmpty) {
      try {
        final vaultSummary = await ExamRepository().fetchUserVaultSummary(userId: effectiveUid);
        if (vaultSummary != null && vaultSummary['success'] == true) {
          mistakesCount = (vaultSummary['totalMistakes'] as num?)?.toInt() ?? 0;
          skippedCount = (vaultSummary['totalSkipped'] as num?)?.toInt() ?? 0;
        } else if (SupabaseService().isInitialized) {
          final mistakes = await SupabaseService().fetchMistakeVault();
          mistakesCount = mistakes.length;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _historyList = items;
        _mistakeCount = mistakesCount;
        _skippedCount = skippedCount;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(isoString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Recent';
    }
  }

  void _openScriptDetail(ExamHistoryItem item) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.examScriptReview, extra: item);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExamScriptReviewScreen(item: item),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam History & Scripts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Analytical Performance Reports & Submitted Question Scripts',
                      style:
                          TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Mistake Vault Banner
                    _buildMistakeVaultBanner(colors),
                    const SizedBox(height: 14),

                    // Segmented Tabs
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: colors.tangerine,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: colors.textSecondary,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            iconMargin: EdgeInsets.zero,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Analytical Report'),
                              ],
                            ),
                          ),
                          Tab(
                            iconMargin: EdgeInsets.zero,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 16),
                                SizedBox(width: 6),
                                Text('Exam Scripts'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const PrepPageSkeleton(cardCount: 3)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildAnalyticalReportTab(colors),
                  _buildScriptsTab(colors),
                ],
              ),
      ),
    );
  }

  Widget _buildMistakeVaultBanner(AppColors colors) => MistakeVaultBanner(
        mistakeCount: _mistakeCount,
        skippedCount: _skippedCount,
        onPracticeMistakes: _openMistakeVault,
      );

  void _openMistakeVault() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MistakeVaultScreen(userId: widget.userId),
      ),
    );
  }

  // TAB 1: Analytical Report
  Widget _buildAnalyticalReportTab(AppColors colors) {
    if (_historyList.isEmpty) {
      return PrepEmptyStateView(
        icon: Icons.analytics_outlined,
        title: 'No Analytics Yet',
        subtitle:
            'Complete your first live or practice model test to unlock comprehensive performance breakdowns and varsity readiness analytics.',
        actionLabel: 'Take a Daily Test',
        onAction: widget.onPracticeMistakes,
      );
    }

    final totalOverall = _historyList.length;
    final dailyList =
        _historyList.where((e) => e.isPractice != true).toList();
    final qbList =
        _historyList.where((e) => e.isPractice == true).toList();
    final univList = _historyList
        .where((e) =>
            (e.universityCode != null && e.universityCode != 'General') ||
            _detectUniversityCode(null, e.title, e.examId) != 'General')
        .toList();

    // Determine available university codes
    final availableUniversities = <String>{};
    for (final item in _historyList) {
      final code = item.universityCode ??
          _detectUniversityCode(null, item.title, item.examId);
      if (code != 'General') {
        availableUniversities.add(code.toUpperCase());
      }
    }

    List<ExamHistoryItem> activeList = _historyList;
    switch (_selectedScope) {
      case AnalyticsScope.overall:
        activeList = _historyList;
        break;
      case AnalyticsScope.daily:
        activeList = dailyList.isNotEmpty ? dailyList : _historyList;
        break;
      case AnalyticsScope.university:
        if (_selectedUniversityFilter == 'ALL') {
          activeList = univList.isNotEmpty ? univList : _historyList;
        } else {
          activeList = _historyList
              .where((e) =>
                  (e.universityCode ??
                          _detectUniversityCode(null, e.title, e.examId))
                      .toUpperCase() ==
                  _selectedUniversityFilter.toUpperCase())
              .toList();
        }
        break;
      case AnalyticsScope.questionBank:
        activeList = qbList.isNotEmpty ? qbList : _historyList;
        break;
    }

    final totalExams = activeList.length;
    int totalQuestions = 0;
    int totalCorrect = 0;
    int totalWrong = 0;
    int totalSkipped = 0;
    double totalNegative = 0.0;
    double totalScoreSum = 0.0;
    double totalMarksSum = 0.0;
    int passCount = 0;

    final subjectDistribution = <String, SubjectAggregate>{};

    for (final item in activeList) {
      totalQuestions += item.totalQuestions;
      totalCorrect += item.correctCount;
      totalWrong += item.wrongCount;
      totalSkipped += item.skippedCount;
      totalNegative += item.negativeMark;
      totalScoreSum += item.score;
      totalMarksSum += item.totalMarks;
      if (item.isPassed) passCount++;

      for (final q in item.questions) {
        final sub = _cleanSubjectName(q.subjectId);
        final agg = subjectDistribution.putIfAbsent(
            sub, () => SubjectAggregate(name: sub));
        agg.total++;
        final ans = item.userAnswers[q.id];
        if (ans != null && ans.isNotEmpty) {
          if (ans == q.correctOptionId) {
            agg.correct++;
          } else {
            agg.wrong++;
          }
        } else {
          agg.skipped++;
        }
      }
    }

    final accuracyPercent = (totalCorrect + totalWrong) > 0
        ? ((totalCorrect / (totalCorrect + totalWrong)) * 100)
        : 0.0;

    final aggregateAvgScore = totalMarksSum > 0
        ? ((totalScoreSum / totalMarksSum) * 100)
        : 0.0;

    final passRatePercent = totalExams > 0
        ? ((passCount / totalExams) * 100).toStringAsFixed(0)
        : '0';

    final effectiveEfficiency = totalQuestions > 0
        ? ((totalCorrect / totalQuestions) * 100).toStringAsFixed(0)
        : '0';

    // Daily grouping
    final dailyGroups = <String, List<ExamHistoryItem>>{};
    for (final item in activeList) {
      String dayKey = item.date;
      if (item.submittedAt != null) {
        dayKey = _formatDayHeader(item.submittedAt!);
      } else if (item.date.contains('•')) {
        dayKey = item.date.split('•').first.trim();
      }
      dailyGroups.putIfAbsent(dayKey, () => []).add(item);
    }

    // University performance breakdown
    final universityGroups = <String, List<ExamHistoryItem>>{};
    for (final item in _historyList) {
      final code = (item.universityCode != null && item.universityCode != 'General')
          ? item.universityCode!
          : _detectUniversityCode(null, item.title, item.examId);
      universityGroups.putIfAbsent(code.toUpperCase(), () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Report Scope Switcher Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _buildScopeChip(
                  label: 'Overall Report',
                  count: totalOverall,
                  scope: AnalyticsScope.overall,
                  icon: Icons.insights_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _buildScopeChip(
                  label: 'Daily Live Exams',
                  count: dailyList.length,
                  scope: AnalyticsScope.daily,
                  icon: Icons.calendar_today_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _buildScopeChip(
                  label: 'University Specific',
                  count: univList.length,
                  scope: AnalyticsScope.university,
                  icon: Icons.account_balance_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _buildScopeChip(
                  label: 'Question Banks',
                  count: qbList.length,
                  scope: AnalyticsScope.questionBank,
                  icon: Icons.collections_bookmark_rounded,
                  colors: colors,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. University Sub-filters if in University scope
          if (_selectedScope == AnalyticsScope.university &&
              availableUniversities.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Varsities'),
                    selected: _selectedUniversityFilter == 'ALL',
                    onSelected: (_) => setState(() {
                      _selectedUniversityFilter = 'ALL';
                    }),
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _selectedUniversityFilter == 'ALL'
                          ? Colors.white
                          : colors.textPrimary,
                    ),
                    backgroundColor: colors.surfaceElevated,
                    side: BorderSide(
                      color: _selectedUniversityFilter == 'ALL'
                          ? colors.primary
                          : colors.borderSubtle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...availableUniversities.map((u) {
                    final isSel = _selectedUniversityFilter == u;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(u),
                        selected: isSel,
                        onSelected: (_) => setState(() {
                          _selectedUniversityFilter = u;
                        }),
                        selectedColor: colors.primary,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : colors.textPrimary,
                        ),
                        backgroundColor: colors.surfaceElevated,
                        side: BorderSide(
                          color: isSel ? colors.primary : colors.borderSubtle,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. 6 Core Individual KPI Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Exams Taken',
                  value: '$totalExams',
                  subtitle: '$totalQuestions Qs attempted',
                  icon: Icons.assignment_turned_in_outlined,
                  accentColor: const Color(0xFFFF7A36),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Net Accuracy',
                  value: '${accuracyPercent.toStringAsFixed(1)}%',
                  subtitle: '$totalCorrect correct answers',
                  icon: Icons.track_changes_rounded,
                  accentColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Average Score',
                  value: '${aggregateAvgScore.toStringAsFixed(1)}%',
                  subtitle: 'Overall baseline score',
                  icon: Icons.speed_rounded,
                  accentColor: colors.tangerine,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Negative Penalty',
                  value: '-${totalNegative.toStringAsFixed(1)}',
                  subtitle: '$totalWrong wrong responses',
                  icon: Icons.shield_outlined,
                  accentColor: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Pass Rate',
                  value: '$passRatePercent%',
                  subtitle: '$passCount of $totalExams passed',
                  icon: Icons.military_tech_rounded,
                  accentColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  colors: colors,
                  title: 'Answer Efficiency',
                  value: '$effectiveEfficiency%',
                  subtitle: '$totalCorrect / $totalQuestions solved',
                  icon: Icons.bolt_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Answer Breakdown Proportion Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Answer Efficiency Distribution',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary),
                    ),
                    Text(
                      '$totalQuestions Questions',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: totalQuestions == 0
                        ? Container(color: colors.borderSubtle)
                        : Row(
                            children: [
                              if (totalCorrect > 0)
                                Expanded(
                                  flex: totalCorrect,
                                  child: Container(
                                      color: const Color(0xFF10B981)),
                                ),
                              if (totalWrong > 0)
                                Expanded(
                                  flex: totalWrong,
                                  child: Container(
                                      color: const Color(0xFFEF4444)),
                                ),
                              if (totalSkipped > 0)
                                Expanded(
                                  flex: totalSkipped,
                                  child: Container(
                                      color: const Color(0xFF9CA3AF)),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem('Correct', '$totalCorrect',
                        const Color(0xFF10B981), colors),
                    _buildLegendItem('Incorrect', '$totalWrong',
                        const Color(0xFFEF4444), colors),
                    _buildLegendItem('Skipped', '$totalSkipped',
                        const Color(0xFF9CA3AF), colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Scoped Dynamic Section
          if (_selectedScope == AnalyticsScope.daily) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Exam Report Journal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${dailyGroups.length} Active Days',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chronological day-by-day exam submissions, scores and question review shortcuts',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),

            if (dailyGroups.isEmpty)
              _buildEmptySectionPlaceholder(
                  'No daily exam records found yet. Complete a live admission test to see daily logs.',
                  colors)
            else
              ...dailyGroups.entries.map((group) {
                final dayLabel = group.key;
                final items = group.value;
                final dayScoreAvg = items.fold<double>(
                        0.0,
                        (sum, e) =>
                            sum +
                            (e.totalMarks > 0
                                ? (e.score / e.totalMarks * 100)
                                : 0.0)) /
                    (items.isNotEmpty ? items.length : 1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                          border: Border(
                              bottom: BorderSide(color: colors.borderSubtle)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.today_rounded,
                                    size: 15, color: colors.tangerine),
                                const SizedBox(width: 6),
                                Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.tangerine.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${items.length} Test${items.length > 1 ? 's' : ''} • Avg ${dayScoreAvg.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.tangerine,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Day's tests list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: colors.borderSubtle,
                        ),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final uCode = item.universityCode ??
                              _detectUniversityCode(
                                  null, item.title, item.examId);
                          final itemAcc = item.totalQuestions > 0
                              ? ((item.correctCount / item.totalQuestions) *
                                      100)
                                  .toStringAsFixed(0)
                              : '0';

                          return InkWell(
                            onTap: () => _openScriptDetail(item),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          colors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      uCode,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '✅ ${item.correctCount}  ❌ ${item.wrongCount}  ⚪ ${item.skippedCount} • $itemAcc% Acc.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.score.toStringAsFixed(1)} / ${item.totalMarks.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: item.isPassed
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFDC2626),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Script',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colors.tangerine,
                                            ),
                                          ),
                                          Icon(Icons.chevron_right,
                                              size: 14, color: colors.tangerine),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
          ] else if (_selectedScope == AnalyticsScope.university) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'University Performance Matrix',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${universityGroups.length} Varsities Tracked',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Admission readiness, test volume, and cutoff margins per target university',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),

            if (universityGroups.isEmpty)
              _buildEmptySectionPlaceholder(
                  'No university-specific exams taken yet. Start an admission past paper or model test.',
                  colors)
            else
              ...universityGroups.entries.map((entry) {
                final uCode = entry.key;
                final items = entry.value;
                final fullName = _getUniversityFullName(uCode);

                final avgScore = items.fold<double>(
                        0.0,
                        (s, e) =>
                            s +
                            (e.totalMarks > 0
                                ? (e.score / e.totalMarks * 100)
                                : 0.0)) /
                    items.length;

                final uCorrect =
                    items.fold<int>(0, (s, e) => s + e.correctCount);
                final uWrong = items.fold<int>(0, (s, e) => s + e.wrongCount);
                final uSkipped =
                    items.fold<int>(0, (s, e) => s + e.skippedCount);

                final isReady = avgScore >= 70.0;
                final isModerate = avgScore >= 45.0;
                final statusColor = isReady
                    ? const Color(0xFF10B981)
                    : (isModerate
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444));
                final statusLabel = isReady
                    ? 'High Readiness'
                    : (isModerate ? 'Moderate' : 'Needs Practice');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        colors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    uCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$statusLabel • ${avgScore.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (avgScore / 100).clamp(0.0, 1.0),
                          backgroundColor: colors.borderSubtle,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${items.length} Exam${items.length > 1 ? 's' : ''} Taken  •  ✅ $uCorrect  ❌ $uWrong  ⚪ $uSkipped',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                          InkWell(
                            onTap: _openMistakeVault,
                            child: Text(
                              'Fix Mistakes',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: colors.tangerine,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
          ] else if (_selectedScope == AnalyticsScope.questionBank) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.collections_bookmark_rounded,
                          color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Question Banks & Practice Arena',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Practice mode exams do not penalize your live ranking and provide untimed deep learning. Use the Mistake Vault to turn all incorrect question bank questions into mastered points.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMistakeVault,
                          icon: const Text('📕', style: TextStyle(fontSize: 14)),
                          label: const Text('Open Mistake Vault'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE11D48),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 6. Subject-wise Accuracy Mastery Breakdown
          Text(
            'Subject Competency Matrix',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Relative performance evaluated across all attempted model tests',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (subjectDistribution.isEmpty)
            _buildEmptySectionPlaceholder(
                'No subject data yet. Take tests to generate the competency matrix.',
                colors)
          else
            ...subjectDistribution.values.map((sub) {
              final subAccuracy =
                  sub.total > 0 ? (sub.correct / sub.total) : 0.0;
              final isStrong = subAccuracy >= 0.70;
              final isModerate = subAccuracy >= 0.45;
              final badgeColor = isStrong
                  ? const Color(0xFF10B981)
                  : (isModerate
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444));
              final badgeLabel = isStrong
                  ? 'Strong'
                  : (isModerate ? 'Moderate' : 'Needs Practice');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sub.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$badgeLabel • ${(subAccuracy * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: subAccuracy,
                        backgroundColor: colors.borderSubtle,
                        valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sub.correct}/${sub.total} correct',
                          style: TextStyle(
                              fontSize: 11, color: colors.textSecondary),
                        ),
                        Text(
                          '${sub.wrong} mistakes • ${sub.skipped} skipped',
                          style:
                              TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // TAB 2: Exam Scripts List
  Widget _buildScriptsTab(AppColors colors) {
    if (_historyList.isEmpty) {
      return PrepEmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No Exam Scripts Available',
        subtitle:
            'Every time you complete a live or practice model test, your complete question script and answers are saved here for review.',
        actionLabel: 'Start an Exam Now',
        onAction: widget.onPracticeMistakes,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _historyList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _historyList[index];
        final accuracy = item.totalQuestions > 0
            ? ((item.correctCount / item.totalQuestions) * 100)
                .toStringAsFixed(0)
            : '0';

        return InkWell(
          onTap: () => _openScriptDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.date,
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isPassed
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.score.toStringAsFixed(1)} / ${item.totalMarks.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: item.isPassed
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.borderSubtle)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '✅ ${item.correctCount}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '❌ ${item.wrongCount}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '⚪ ${item.skippedCount}',
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '•  $accuracy% Acc.',
                            style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'View Script',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.tangerine,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right,
                              size: 16, color: colors.tangerine),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required AppColors colors,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) =>
      AnalyticsMetricCard(
        colors: colors,
        title: title,
        value: value,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
      );

  Widget _buildLegendItem(
          String label, String value, Color dotColor, AppColors colors) =>
      AnalyticsLegendItem(
        label: label,
        value: value,
        dotColor: dotColor,
        colors: colors,
      );

  Widget _buildScopeChip({
    required String label,
    required int count,
    required AnalyticsScope scope,
    required IconData icon,
    required AppColors colors,
  }) {
    final isSelected = _selectedScope == scope;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? Colors.white : colors.primary,
      ),
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _selectedScope = scope;
        _selectedUniversityFilter = 'ALL';
      }),
      selectedColor: colors.tangerine,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? Colors.white : colors.textPrimary,
      ),
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(
        color: isSelected ? colors.tangerine : colors.borderSubtle,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    );
  }

  Widget _buildEmptySectionPlaceholder(String message, AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ),
    );
  }

  String _formatDayHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today • ${_formatMonthDay(dt)}';
    if (diff == 1) return 'Yesterday • ${_formatMonthDay(dt)}';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[dt.weekday - 1]}, ${_formatMonthDay(dt)}';
  }

  String _formatMonthDay(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _detectUniversityCode(String? uCode, String? title, String? examId) {
    if (uCode != null && uCode.trim().isNotEmpty && uCode.toLowerCase() != 'null') {
      return uCode.trim().toUpperCase();
    }
    final combined = '${title ?? ''} ${examId ?? ''}'.toUpperCase();
    if (combined.contains('BRACU') || combined.contains('BRAC')) return 'BRACU';
    if (combined.contains('EWU') || combined.contains('EAST WEST')) return 'EWU';
    if (combined.contains('NSU') || combined.contains('NORTH SOUTH')) return 'NSU';
    if (combined.contains('IBA')) return 'IBA';
    if (combined.contains('BUET')) return 'BUET';
    if (combined.contains('DU') || combined.contains('DHAKA')) return 'DU';
    if (combined.contains('SUST')) return 'SUST';
    if (combined.contains('JU') || combined.contains('JAHANGIRNAGAR')) return 'JU';
    if (combined.contains('RU') || combined.contains('RAJSHAHI')) return 'RU';
    if (combined.contains('CU') || combined.contains('CHITTAGONG')) return 'CU';
    if (combined.contains('BUP')) return 'BUP';
    if (combined.contains('BUTEX')) return 'BUTEX';
    if (combined.contains('CKRUET') || combined.contains('RUET') || combined.contains('KUET') || combined.contains('CUET')) return 'CKRUET';
    return 'General';
  }

  String _getUniversityFullName(String code) {
    switch (code.toUpperCase()) {
      case 'BRACU': return 'BRAC University';
      case 'EWU': return 'East West University';
      case 'NSU': return 'North South University';
      case 'IBA': return 'IBA, University of Dhaka';
      case 'DU': return 'University of Dhaka';
      case 'BUET': return 'BUET Engineering';
      case 'SUST': return 'Shahjalal Univ. of Science & Tech';
      case 'JU': return 'Jahangirnagar University';
      case 'BUP': return 'Bangladesh University of Professionals';
      case 'CKRUET': return 'CKRUET Engineering Cluster';
      default: return '$code Tests & Past Papers';
    }
  }

  String _cleanSubjectName(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('chem')) return 'Chemistry';
    if (lower.contains('phys')) return 'Physics';
    if (lower.contains('math') || lower.contains('quant')) return 'Quantitative & Mathematics';
    if (lower.contains('eng')) return 'English Language & Reading';
    if (lower.contains('bio')) return 'Biology';
    if (lower.contains('gk') || lower.contains('general_knowledge') || lower.contains('general knowledge') || lower.contains('aptitude')) {
      return 'General Knowledge & Aptitude';
    }
    if (lower.contains('bba') || lower.contains('fbs') || lower.contains('business') || lower.contains('acc') || lower.contains('fin')) {
      return 'Business Studies & Finance';
    }
    if (raw.startsWith('sub_')) {
      return raw.substring(4).replaceAll('_', ' ').toUpperCase();
    }
    return raw.toUpperCase();
  }
}

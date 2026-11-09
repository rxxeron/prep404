import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Representation of a distinct continuous study streak run
class StreakPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final int questionsSolved;
  final int examsCompleted;
  final bool isActive;
  final bool usedFreeze;

  const StreakPeriod({
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    this.questionsSolved = 0,
    this.examsCompleted = 0,
    this.isActive = false,
    this.usedFreeze = false,
  });
}

/// Comprehensive Detail Screen for Study Streak History, Timeline, and Metrics
class StudyStreakDetailScreen extends StatefulWidget {
  final String? userId;

  const StudyStreakDetailScreen({
    super.key,
    this.userId,
  });

  @override
  State<StudyStreakDetailScreen> createState() => _StudyStreakDetailScreenState();
}

class _StudyStreakDetailScreenState extends State<StudyStreakDetailScreen> {
  bool _isLoading = true;
  int _currentStreak = 0;
  int _highestStreak = 0;
  int _lowestStreak = 0;
  int _totalActiveDays = 0;
  int _totalStreakCount = 0;
  int _streakFreezes = 1;
  int _totalQuestionsSolved = 0;
  List<bool> _weeklyDaysActive = [];

  final Set<DateTime> _activeDates = {};
  final List<StreakPeriod> _streakHistory = [];

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final effectiveUid = widget.userId ?? SupabaseService().currentUser?.id;

    // 1. Prioritize authoritative PostgreSQL live database streak record
    try {
      final dbData = await ExamRepository().fetchUserStreakDetails(userId: effectiveUid);
      if (dbData != null && dbData['success'] == true && dbData['streak'] is Map) {
        final s = dbData['streak'] as Map<String, dynamic>;
        final cur = (s['currentStreak'] as num?)?.toInt() ?? 0;
        final high = (s['highestStreak'] as num?)?.toInt() ?? 0;
        final low = (s['lowestStreak'] as num?)?.toInt() ?? 0;
        final activeDays = (s['totalActiveDays'] as num?)?.toInt() ?? 0;
        final cycles = (s['totalStreakCycles'] as num?)?.toInt() ?? 0;
        final freezes = (s['streakFreezesAvailable'] as num?)?.toInt() ?? 1;

        final rawTimeline = s['timeline'] as List? ?? [];
        final parsedTimeline = <StreakPeriod>[];
        int totalSolvedFromTimeline = 0;
        for (final item in rawTimeline) {
          if (item is Map) {
            final start = DateTime.tryParse(item['startDate']?.toString() ?? '') ?? DateTime.now();
            final end = DateTime.tryParse(item['endDate']?.toString() ?? '') ?? DateTime.now();
            final qCount = (item['questionsSolved'] as num?)?.toInt() ?? 0;
            totalSolvedFromTimeline += qCount;
            parsedTimeline.add(StreakPeriod(
              startDate: start,
              endDate: end,
              daysCount: (item['daysCount'] as num?)?.toInt() ?? 1,
              questionsSolved: qCount,
              examsCompleted: (item['examsCompleted'] as num?)?.toInt() ?? 0,
              isActive: item['isActive'] == true,
              usedFreeze: item['usedFreeze'] == true,
            ));
          }
        }

        final rawWeekly = s['weeklyDaysActive'] as List? ?? [];
        final weeklyActive = rawWeekly.map((e) => e == true).toList();
        final totalQuestionsFromDb = (s['totalQuestionsSolved'] as num?)?.toInt();
        final resolvedQuestionsSolved = totalQuestionsFromDb != null && totalQuestionsFromDb > 0
            ? totalQuestionsFromDb
            : totalSolvedFromTimeline;

        if (mounted) {
          setState(() {
            _currentStreak = cur;
            _highestStreak = high;
            _lowestStreak = low;
            _totalActiveDays = activeDays;
            _totalStreakCount = cycles;
            _streakFreezes = freezes;
            _totalQuestionsSolved = resolvedQuestionsSolved;
            if (parsedTimeline.isNotEmpty) {
              _streakHistory.clear();
              _streakHistory.addAll(parsedTimeline);
            }
            if (weeklyActive.isNotEmpty) {
              _weeklyDaysActive = weeklyActive;
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    final submissions = <Map<String, dynamic>>[];

    // 1. Fetch remote submissions from Supabase
    if (SupabaseService().isInitialized && effectiveUid != null) {
      try {
        final remote = await SupabaseService().fetchExamSubmissions(effectiveUid);
        for (final row in remote) {
          submissions.add(Map<String, dynamic>.from(row));
        }
      } catch (_) {}
    }

    // 2. Fetch local cached scripts
    final localScripts = CacheService().loadExamScripts();
    for (final s in localScripts) {
      submissions.add(Map<String, dynamic>.from(s));
    }

    // 3. Process activity dates and questions
    final Map<DateTime, int> dayQuestionMap = {};
    final Map<DateTime, int> dayExamMap = {};

    for (final s in submissions) {
      DateTime? dt;
      final rawIso = s['submitted_at'] ?? s['date'];
      if (rawIso != null) {
        dt = DateTime.tryParse(rawIso.toString());
      }
      dt ??= DateTime.now();

      final dayNormalized = DateTime(dt.year, dt.month, dt.day);
      _activeDates.add(dayNormalized);

      final qCount = (s['totalQuestions'] as num?)?.toInt() ??
          (s['correct_count'] as num?)?.toInt() ??
          10;
      dayQuestionMap[dayNormalized] =
          (dayQuestionMap[dayNormalized] ?? 0) + qCount;
      dayExamMap[dayNormalized] = (dayExamMap[dayNormalized] ?? 0) + 1;
      _totalQuestionsSolved += qCount;
    }

    // 4. Fallback or baseline from UserProfile
    final profile = SupabaseService().currentUser;
    int baselineStreak = 0;
    if (profile != null) {
      baselineStreak = (profile.userMetadata?['streak_days'] as num?)?.toInt() ??
          (profile.userMetadata?['studyStreakDays'] as num?)?.toInt() ??
          0;
    }

    // Ensure today or recent active days if profile has streak
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_activeDates.isEmpty && baselineStreak > 0) {
      for (int i = 0; i < baselineStreak; i++) {
        final d = today.subtract(Duration(days: i));
        _activeDates.add(d);
        dayQuestionMap[d] = 15;
        dayExamMap[d] = 1;
      }
    }

    // Sort active dates chronologically
    final sortedDates = _activeDates.toList()..sort((a, b) => a.compareTo(b));
    _totalActiveDays = sortedDates.length;

    // 5. Build continuous streak periods (with 1-day freeze allowance)
    final periods = <StreakPeriod>[];
    if (sortedDates.isNotEmpty) {
      DateTime chainStart = sortedDates.first;
      DateTime prevDate = sortedDates.first;
      int qSum = dayQuestionMap[chainStart] ?? 10;
      int examSum = dayExamMap[chainStart] ?? 1;
      bool usedFreezeInChain = false;

      for (int i = 1; i < sortedDates.length; i++) {
        final cur = sortedDates[i];
        final diffDays = cur.difference(prevDate).inDays;

        if (diffDays == 1) {
          // Continuous
          prevDate = cur;
          qSum += dayQuestionMap[cur] ?? 10;
          examSum += dayExamMap[cur] ?? 1;
        } else if (diffDays == 2 && !usedFreezeInChain) {
          // Protected by 1 Streak Freeze
          usedFreezeInChain = true;
          prevDate = cur;
          qSum += dayQuestionMap[cur] ?? 10;
          examSum += dayExamMap[cur] ?? 1;
        } else {
          // Chain broke; record completed period
          final len = prevDate.difference(chainStart).inDays + 1;
          periods.add(StreakPeriod(
            startDate: chainStart,
            endDate: prevDate,
            daysCount: len,
            questionsSolved: qSum,
            examsCompleted: examSum,
            isActive: false,
            usedFreeze: usedFreezeInChain,
          ));

          // Start new chain
          chainStart = cur;
          prevDate = cur;
          qSum = dayQuestionMap[cur] ?? 10;
          examSum = dayExamMap[cur] ?? 1;
          usedFreezeInChain = false;
        }
      }

      // Close the final chain
      final finalLen = prevDate.difference(chainStart).inDays + 1;
      final daysSinceLastActive = today.difference(prevDate).inDays;
      final isFinalActive = daysSinceLastActive <= 1; // today or yesterday

      periods.add(StreakPeriod(
        startDate: chainStart,
        endDate: prevDate,
        daysCount: finalLen,
        questionsSolved: qSum,
        examsCompleted: examSum,
        isActive: isFinalActive,
        usedFreeze: usedFreezeInChain,
      ));
    } else if (baselineStreak > 0) {
      periods.add(StreakPeriod(
        startDate: today.subtract(Duration(days: baselineStreak - 1)),
        endDate: today,
        daysCount: baselineStreak,
        questionsSolved: baselineStreak * 15,
        examsCompleted: baselineStreak,
        isActive: true,
      ));
    }

    // 6. Compute requested metrics:
    // - Current streak
    // - Highest streak
    // - Lowest streak
    // - Total streak count
    int cur = 0;
    int highest = baselineStreak;
    int lowest = periods.isNotEmpty ? periods.first.daysCount : 0;

    for (final p in periods) {
      if (p.isActive) {
        cur = p.daysCount;
      }
      if (p.daysCount > highest) highest = p.daysCount;
      if (p.daysCount > 0 && (lowest == 0 || p.daysCount < lowest)) {
        lowest = p.daysCount;
      }
    }

    if (baselineStreak > cur) cur = baselineStreak;
    if (cur > highest) highest = cur;
    if (lowest == 0) lowest = cur > 0 ? cur : 0;

    int totalQuestionsFallback = 0;
    for (final count in dayQuestionMap.values) {
      totalQuestionsFallback += count;
    }

    // Sort periods newest first for timeline view
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (mounted) {
      setState(() {
        _currentStreak = cur;
        _highestStreak = highest;
        _lowestStreak = lowest;
        _totalStreakCount = periods.length;
        _totalQuestionsSolved = totalQuestionsFallback > 0 ? totalQuestionsFallback : (cur * 15);
        _streakHistory.clear();
        _streakHistory.addAll(periods);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Study Streak & Consistency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined,
                    color: Color(0xFF059669), size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_streakFreezes Freeze Active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.tangerine))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Flame Banner
                  _buildHeroFlameBanner(colors),
                  const SizedBox(height: 16),

                  // 2. 6-Scoreboard Individual Metrics Grid
                  _buildMetricsScoreboard(colors),
                  const SizedBox(height: 16),

                  // 3. Consistency Level & Reliability Index
                  _buildConsistencyLevelCard(colors),
                  const SizedBox(height: 18),

                  // 4. Weekly Streak Strip
                  _buildWeeklyStreakStrip(colors),
                  const SizedBox(height: 20),

                  // 5. Chronological Streaked Timeline
                  _buildStreakedTimelineSection(colors),
                  const SizedBox(height: 20),

                  // 6. Milestone & League Consistency Ladder
                  _buildMilestoneLadder(colors),
                  const SizedBox(height: 24),

                  // 7. Keep Practicing CTA
                  _buildKeepPracticingCTA(colors),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // 1. Hero Flame Banner
  Widget _buildHeroFlameBanner(AppColors colors) {
    final statusText = _currentStreak > 0
        ? '$_currentStreak ${_currentStreak == 1 ? "Day" : "Days"} Study Streak!'
        : '0 Days Study Streak';

    final motivation = _currentStreak >= 14
        ? 'Unstoppable admission contender! Phoenix tenacity in full effect.'
        : _currentStreak >= 7
            ? 'On fire! You have built a solid daily admission study habit.'
            : _currentStreak >= 3
                ? 'Great momentum! 1.5x XP Boost active across all tests.'
                : 'Practice at least 1 question daily to keep your flame glowing!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF7ED),
            const Color(0xFFFEF3C7).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFF97316),
              size: 44,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            motivation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '⚡ 1.5x Boost Active • $_totalQuestionsSolved Questions Practiced',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. 6-Scoreboard Individual Metrics Grid
  Widget _buildMetricsScoreboard(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Performance Metrics',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Current Streak',
                value: '$_currentStreak Day${_currentStreak == 1 ? '' : 's'}',
                subtitle: _currentStreak > 0 ? 'Active Chain' : 'Needs Practice',
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Highest Streak',
                value: '$_highestStreak Day${_highestStreak == 1 ? '' : 's'}',
                subtitle: 'Personal Best Record',
                icon: Icons.emoji_events_rounded,
                accentColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Lowest Streak',
                value: '$_lowestStreak Day${_lowestStreak == 1 ? '' : 's'}',
                subtitle: 'Shortest Completed Run',
                icon: Icons.timeline_rounded,
                accentColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Total Active Days',
                value: '$_totalActiveDays Day${_totalActiveDays == 1 ? '' : 's'}',
                subtitle: 'Cumulative Study Days',
                icon: Icons.calendar_month_rounded,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Total Streak Cycles',
                value: '$_totalStreakCount Run${_totalStreakCount == 1 ? '' : 's'}',
                subtitle: 'Lifetime Streak Chains',
                icon: Icons.repeat_rounded,
                accentColor: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                colors: colors,
                title: 'Streak Freeze',
                value: '$_streakFreezes Available',
                subtitle: 'Missed-day Insurance',
                icon: Icons.health_and_safety_rounded,
                accentColor: const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Consistency Level & Reliability Index
  Widget _buildConsistencyLevelCard(AppColors colors) {
    final now = DateTime.now();
    final elapsedDaysInWeek = now.weekday; // 1 for Mon, 7 for Sun
    int activeDaysThisWeek = 0;
    for (int i = 0; i < elapsedDaysInWeek && i < _weeklyDaysActive.length; i++) {
      if (_weeklyDaysActive[i]) activeDaysThisWeek++;
    }
    if (_currentStreak > 0 && activeDaysThisWeek == 0) {
      activeDaysThisWeek = 1;
    }

    final consistencyPct = elapsedDaysInWeek > 0
        ? ((activeDaysThisWeek / elapsedDaysInWeek) * 100).round().clamp(0, 100)
        : 0;

    final String levelTitle;
    final String levelDesc;
    final Color levelColor;
    final IconData levelIcon;

    if (consistencyPct >= 80) {
      levelTitle = 'High Consistency';
      levelDesc = 'Exceptional discipline! Your daily admission habit is in the top tier.';
      levelColor = const Color(0xFF10B981);
      levelIcon = Icons.verified_rounded;
    } else if (consistencyPct >= 50) {
      levelTitle = 'Moderate Consistency';
      levelDesc = 'Solid momentum! Complete tests consistently to unlock the Elite badge.';
      levelColor = const Color(0xFFF59E0B);
      levelIcon = Icons.trending_up_rounded;
    } else {
      levelTitle = 'Developing Consistency';
      levelDesc = 'Building momentum. Practice at least 1 question daily to solidify your cadence.';
      levelColor = const Color(0xFF3B82F6);
      levelIcon = Icons.flag_rounded;
    }

    return Container(
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
              Row(
                children: [
                  Icon(Icons.insights_rounded, size: 18, color: colors.tangerine),
                  const SizedBox(width: 8),
                  Text(
                    'Consistency Level & Index',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(levelIcon, size: 13, color: levelColor),
                    const SizedBox(width: 4),
                    Text(
                      levelTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$consistencyPct%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: levelColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activeDaysThisWeek of $elapsedDaysInWeek Days Active This Week',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: consistencyPct / 100.0,
                        minHeight: 6,
                        backgroundColor: colors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            levelDesc,
            style: TextStyle(fontSize: 11.5, color: colors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required AppColors colors,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
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
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.5, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // 3. Weekly Streak Strip
  Widget _buildWeeklyStreakStrip(AppColors colors) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find Monday of this week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
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
                'This Week\'s Study Activity',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'Mon – Sun',
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final targetDay = monday.add(Duration(days: index));
              final isToday = targetDay.year == today.year &&
                  targetDay.month == today.month &&
                  targetDay.day == today.day;
              final hasActive = (_weeklyDaysActive.length > index &&
                      _weeklyDaysActive[index]) ||
                  _activeDates.contains(targetDay);

              Color dotColor = colors.surfaceElevated;
              Color iconColor = colors.textMuted;
              IconData icon = Icons.circle_outlined;

              if (hasActive) {
                dotColor = const Color(0xFFF59E0B);
                iconColor = Colors.white;
                icon = Icons.check_rounded;
              } else if (isToday) {
                dotColor = const Color(0xFFFEF3C7);
                iconColor = const Color(0xFFF97316);
                icon = Icons.local_fire_department_rounded;
              }

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: const Color(0xFFF97316), width: 2)
                          : Border.all(color: colors.borderSubtle),
                    ),
                    child: Center(
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    weekDayLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? colors.tangerine : colors.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // 4. Chronological Streaked Timeline ("The Streaked Timeline")
  Widget _buildStreakedTimelineSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Streaked Timeline & History',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '${_streakHistory.length} Cycles',
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
          'Complete log of past and ongoing study streak durations and activity',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 12),

        if (_streakHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                'No recorded streak history yet. Solve a model test today to begin your timeline.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ),
          )
        else
          ..._streakHistory.map((period) => _buildTimelineItem(period, colors)),
      ],
    );
  }

  Widget _buildTimelineItem(StreakPeriod period, AppColors colors) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final startStr =
        '${months[period.startDate.month - 1]} ${period.startDate.day}';
    final endStr = period.isActive
        ? 'Present (Active)'
        : '${months[period.endDate.month - 1]} ${period.endDate.day}, ${period.endDate.year}';

    final badgeColor = period.isActive
        ? const Color(0xFFF97316)
        : period.daysCount >= 7
            ? const Color(0xFF10B981)
            : const Color(0xFF6B7280);

    final statusLabel = period.isActive
        ? 'Active Run 🔥'
        : period.daysCount >= 7
            ? 'Milestone Hit 🏆'
            : 'Completed Run';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: period.isActive
              ? const Color(0xFFFDE68A)
              : colors.border,
          width: period.isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Flame Indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              period.isActive
                  ? Icons.local_fire_department_rounded
                  : Icons.history_rounded,
              color: badgeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${period.daysCount} Day${period.daysCount == 1 ? '' : 's'} Streak',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$startStr – $endStr',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '📝 ${period.questionsSolved} questions solved',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                    if (period.usedFreeze) ...[
                      const SizedBox(width: 10),
                      const Text(
                        '🛡️ Freeze Used',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Milestone & League Consistency Ladder
  Widget _buildMilestoneLadder(AppColors colors) {
    final milestones = [
      {'days': 3, 'title': 'Spark Ignited', 'desc': 'First 3 days unbroken streak'},
      {'days': 7, 'title': 'Week Warrior', 'desc': '7 days of uninterrupted focus'},
      {'days': 14, 'title': 'Fortnight Habit', 'desc': 'Formed an unbreakable daily rhythm'},
      {'days': 30, 'title': 'Admission Titan', 'desc': 'Top 5% nation-wide study consistency'},
      {'days': 60, 'title': 'Phoenix Ascended', 'desc': 'Pinnacle varsity admission readiness'},
    ];

    return Container(
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
                'Streak Milestone Ladder',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'Consistency Badges',
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...milestones.map((m) {
            final targetDays = m['days'] as int;
            final isAchieved = _highestStreak >= targetDays;
            final progress = (_currentStreak / targetDays).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAchieved
                          ? const Color(0xFF10B981)
                          : colors.surfaceElevated,
                      border: Border.all(
                        color: isAchieved
                            ? const Color(0xFF059669)
                            : colors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isAchieved ? Icons.check_rounded : Icons.lock_outline_rounded,
                        size: 15,
                        color: isAchieved ? Colors.white : colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${m['title']} ($targetDays Days)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAchieved
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                            Text(
                              isAchieved
                                  ? 'Unlocked ✅'
                                  : '$_currentStreak/$targetDays d',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isAchieved
                                    ? const Color(0xFF059669)
                                    : colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: colors.borderSubtle,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAchieved
                                  ? const Color(0xFF10B981)
                                  : colors.tangerine,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6. Keep Practicing CTA
  Widget _buildKeepPracticingCTA(AppColors colors) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.tangerine,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.bolt_rounded, size: 20),
        label: const Text(
          'Keep Streak Alive • Practice Now',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).maybePop();
          if (GoRouter.maybeOf(context) != null) {
            context.go(AppRoutes.modelTestCatalog);
          }
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/question.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/resilient_api_client.dart';
import '../../../../core/services/supabase_service.dart';
import 'live_model_test_screen.dart';
import '../widgets/university_leaderboard_view.dart';
import '../widgets/national_leaderboard_view.dart';
import '../widgets/past_exams_view.dart';
import '../widgets/daily_exam_live_card.dart';
import '../widgets/daily_exam_university_filter.dart';

class DailyExamArenaScreen extends StatefulWidget {
  final String? userId;
  final String candidateName;
  final String candidateCollege;
  final List<String>? targetUniversityKeys;
  final bool isEnglish;

  const DailyExamArenaScreen({
    super.key,
    this.userId,
    required this.candidateName,
    required this.candidateCollege,
    this.targetUniversityKeys,
    this.isEnglish = true,
  });

  @override
  State<DailyExamArenaScreen> createState() => _DailyExamArenaScreenState();
}

class _DailyExamArenaScreenState extends State<DailyExamArenaScreen> {
  final UniversityRoadmapService _service = UniversityRoadmapService();
  final ExamRepository _repository = ExamRepository();

  Future<Map<String, dynamic>?>? _dailyTestFuture;
  Future<List<Map<String, dynamic>>>? _pastExamsFuture;
  Future<List<Map<String, dynamic>>>? _overallLeaderboardFuture;

  Timer? _countdownTimer;
  String _remainingTime = '00:00:00';
  DailySlotState _slotState = DailySlotState.closed;
  String _slotBadgeText = 'SLOT CLOSED';
  String _lastFetchedKey = '';
  int _leaderboardTabIndex = 0; // 0: University Specific, 1: Overall National

  @override
  void initState() {
    super.initState();
    _service.ensureActiveTarget(widget.targetUniversityKeys ?? []);
    _startTimer();
    _fetchForActiveKey(_service.activeUniversityKey.value);
  }

  @override
  void didUpdateWidget(covariant DailyExamArenaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _service.ensureActiveTarget(widget.targetUniversityKeys ?? []);
    if (_lastFetchedKey != _service.activeUniversityKey.value) {
      _fetchForActiveKey(_service.activeUniversityKey.value);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 10, 0, 0); // 10:00 AM
    final end = DateTime(now.year, now.month, now.day, 22, 0, 0); // 10:00 PM

    DailySlotState state;
    String badge;
    String timeStr;

    if (now.isBefore(start)) {
      state = DailySlotState.upcoming;
      badge = 'OPENS AT 10:00 AM';
      final diff = start.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      timeStr = 'Opens in $hours:$minutes:$seconds';
    } else if (now.isAfter(end)) {
      state = DailySlotState.closed;
      badge = 'SLOT CLOSED';
      final tomorrowStart = start.add(const Duration(days: 1));
      final diff = tomorrowStart.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      timeStr = 'Next slot in $hours:$minutes:$seconds';
    } else {
      state = DailySlotState.live;
      badge = 'LIVE NOW';
      final diff = end.difference(now);
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      timeStr = '$hours:$minutes:$seconds remaining';
    }

    if (mounted) {
      setState(() {
        _slotState = state;
        _slotBadgeText = badge;
        _remainingTime = timeStr;
      });
    }
  }

  void _fetchForActiveKey(String key, {bool notify = true}) {
    _lastFetchedKey = key;
    final code = key.toUpperCase();
    _dailyTestFuture = _fetchDailyTestFromBackend(code);
    _pastExamsFuture = _repository.fetchPastDailyTests(
      universityCode: code,
    );
    _overallLeaderboardFuture = _repository.fetchOverallLeaderboard();
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>?> _fetchDailyTestFromBackend(
      String uniCode) async {
    try {
      final res = await ResilientApiClient().getWithFallback(
        '/api/v1/daily-test/today?university=$uniCode',
        headers: {
          if (SupabaseService().currentAccessToken != null)
            'Authorization': 'Bearer ${SupabaseService().currentAccessToken}',
        },
        timeout: const Duration(milliseconds: 2500),
      );
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  void _launchLiveTest({
    required String title,
    required String slug,
    required int durationMinutes,
    required double negativeMark,
    List<Question>? initialQuestions,
    bool isPracticeMode = false,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.liveModelTest,
        extra: {
          'title': title,
          'slug': slug,
          'durationMinutes': durationMinutes,
          'negativeMark': negativeMark,
          'initialQuestions': initialQuestions,
          'userId': widget.userId,
          'isPracticeMode': isPracticeMode,
        },
      ).then((_) {
        if (mounted) _fetchForActiveKey(_lastFetchedKey);
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveModelTestScreen(
            title: title,
            slug: slug,
            durationMinutes: durationMinutes,
            negativeMark: negativeMark,
            initialQuestions: initialQuestions,
            userId: widget.userId,
            candidateName: widget.candidateName,
            candidateCollege: widget.candidateCollege,
            isPracticeMode: isPracticeMode,
            onExit: () {
              Navigator.of(context).pop();
              _fetchForActiveKey(_lastFetchedKey);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<String>(
      valueListenable: _service.activeUniversityKey,
      builder: (context, activeKey, _) {
        if (_lastFetchedKey != activeKey) {
          _fetchForActiveKey(activeKey, notify: false);
        }
        final activeUni = _service.getRoadmap(activeKey);

        return Scaffold(
          backgroundColor: colors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Daily Live Exam Arena',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select a university — view today\'s live slot & dedicated leaderboard',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Top University Filter Pills
                DailyExamUniversityFilter(
                  roadmaps: _service.allRoadmaps,
                  activeKey: activeKey,
                  onSelectUniversity: (key) {
                    _service.setActiveUniversity(key);
                    _fetchForActiveKey(key);
                  },
                ),
                const SizedBox(height: 18),

                // 1. Today's Daily Live Test Card (Single Attempt Guaranteed)
                DailyExamLiveCard(
                  activeUni: activeUni,
                  dailyTestFuture: _dailyTestFuture,
                  slotState: _slotState,
                  slotBadgeText: _slotBadgeText,
                  remainingTime: _remainingTime,
                  onRetry: () => _fetchForActiveKey(activeUni.key),
                  onLaunchExam: _launchLiveTest,
                ),
                const SizedBox(height: 22),

                // 2. Leaderboards Section (University-Specific & Overall National)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _leaderboardTabIndex = 0),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _leaderboardTabIndex == 0
                                  ? const Color(0xFFFF7A36)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🏛️ ${activeUni.shortCode} Today',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _leaderboardTabIndex == 0
                                    ? Colors.white
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _leaderboardTabIndex = 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _leaderboardTabIndex == 1
                                  ? const Color(0xFFFF7A36)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '🌐 National Overall',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _leaderboardTabIndex == 1
                                    ? Colors.white
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Leaderboard Content Switcher
                if (_leaderboardTabIndex == 0)
                  _buildUniversityLeaderboard(colors, activeUni)
                else
                  _buildOverallNationalLeaderboard(colors),

                const SizedBox(height: 26),

                // 3. Past Daily Drills & Missed Exams (Unranked Practice)
                _buildPastExamsSection(colors, activeUni),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- University Specific Leaderboard ---
  Widget _buildUniversityLeaderboard(
      AppColors colors, UniversityRoadmapData activeUni) {
    return UniversityLeaderboardView(
      leaderboardFuture:
          _dailyTestFuture?.then((v) => v ?? <String, dynamic>{}) ??
              Future.value(<String, dynamic>{}),
      activeUni: activeUni,
      colors: colors,
    );
  }

  // --- Overall National Leaderboard ---
  Widget _buildOverallNationalLeaderboard(AppColors colors) {
    return NationalLeaderboardView(
      overallLeaderboardFuture: _overallLeaderboardFuture,
      colors: colors,
    );
  }

  // --- Past Daily Drills & Missed Exams (Unranked Practice) ---
  Widget _buildPastExamsSection(
      AppColors colors, UniversityRoadmapData activeUni) {
    return PastExamsView(
      pastExamsFuture: _pastExamsFuture,
      activeUni: activeUni,
      colors: colors,
      onLaunchLiveTest: ({
        required String title,
        required String slug,
        required int durationMinutes,
        required double negativeMark,
        bool isPracticeMode = false,
      }) {
        _launchLiveTest(
          title: title,
          slug: slug,
          durationMinutes: durationMinutes,
          negativeMark: negativeMark,
          isPracticeMode: isPracticeMode,
        );
      },
    );
  }
}

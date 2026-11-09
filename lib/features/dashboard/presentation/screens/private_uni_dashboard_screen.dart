import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/resilient_api_client.dart';
import '../widgets/dashboard_university_carousel.dart';
import '../widgets/dashboard_today_test_card.dart';
import '../widgets/dashboard_section_pattern_list.dart';
import '../../../exam/presentation/screens/live_model_test_screen.dart';

/// Modern Prep404 Target-University Centric Dashboard
class PrivateUniDashboardScreen extends StatefulWidget {
  final UserProfile profile;
  final void Function({String? topicId, String? subjectId}) onStartPractice;
  final VoidCallback onStartBattle;
  final void Function(int tabIndex)? onSwitchTab;
  final void Function(int step)? onEditProfile;
  final bool isEnglish;

  const PrivateUniDashboardScreen({
    super.key,
    required this.profile,
    required this.onStartPractice,
    required this.onStartBattle,
    this.onSwitchTab,
    this.onEditProfile,
    this.isEnglish = false,
  });

  @override
  State<PrivateUniDashboardScreen> createState() =>
      _PrivateUniDashboardScreenState();
}

class _PrivateUniDashboardScreenState extends State<PrivateUniDashboardScreen> {
  final UniversityRoadmapService _service = UniversityRoadmapService();
  Future<Map<String, dynamic>?>? _dailyTestFuture;
  Timer? _countdownTimer;
  String _remainingLeft = '00:00:00';
  String _lastFetchedKey = '';

  @override
  void initState() {
    super.initState();
    _service.ensureActiveTarget(widget.profile.targetSelections.keys.toList());
    _service.activeUniversityKey.addListener(_onActiveUniversityKeyChanged);
    _startTimer();
    _fetchForActiveKey(_service.activeUniversityKey.value, notify: false);
  }

  void _onActiveUniversityKeyChanged() {
    if (mounted && _lastFetchedKey != _service.activeUniversityKey.value) {
      _fetchForActiveKey(_service.activeUniversityKey.value, notify: true);
    }
  }

  @override
  void didUpdateWidget(covariant PrivateUniDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _service.ensureActiveTarget(widget.profile.targetSelections.keys.toList());
    if (_lastFetchedKey != _service.activeUniversityKey.value) {
      _fetchForActiveKey(_service.activeUniversityKey.value, notify: true);
    }
  }

  @override
  void dispose() {
    _service.activeUniversityKey.removeListener(_onActiveUniversityKeyChanged);
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

    String timeStr;
    if (now.isBefore(start)) {
      final diff = start.difference(now);
      final hours = diff.inHours.toString().padLeft(2, "0");
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, "0");
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, "0");
      timeStr = "Opens in $hours:$minutes:$seconds";
    } else if (now.isAfter(end)) {
      final tomorrowStart = start.add(const Duration(days: 1));
      final diff = tomorrowStart.difference(now);
      final hours = diff.inHours.toString().padLeft(2, "0");
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, "0");
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, "0");
      timeStr = "Next in $hours:$minutes:$seconds";
    } else {
      final diff = end.difference(now);
      final hours = diff.inHours.toString().padLeft(2, "0");
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, "0");
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, "0");
      timeStr = "$hours:$minutes:$seconds left";
    }

    if (mounted) {
      setState(() {
        _remainingLeft = timeStr;
      });
    }
  }

  void _fetchForActiveKey(String key, {bool notify = true}) {
    _lastFetchedKey = key;
    final code = key.toUpperCase();
    final future = _fetchDailyTestFromBackend(code);
    _dailyTestFuture = future;
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>?> _fetchDailyTestFromBackend(
      String uniCode) async {
    try {
      final res = await ResilientApiClient().getWithFallback(
        '/api/v1/daily-test/today?university=$uniCode',
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

  void _launchTodayExam({
    required String title,
    required String slug,
    required int durationMinutes,
    required double negativeMark,
  }) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.liveModelTest,
        extra: {
          'title': title,
          'slug': slug,
          'durationMinutes': durationMinutes,
          'negativeMark': negativeMark,
        },
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveModelTestScreen(
            title: title,
            slug: slug,
            durationMinutes: durationMinutes,
            negativeMark: negativeMark,
            userId: widget.profile.id,
            candidateName: widget.profile.name,
            candidateCollege: widget.profile.institutionName,
            onExit: () => Navigator.of(context).pop(),
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
        final currentUni = _service.currentRoadmap;

        return Scaffold(
          backgroundColor: colors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // Greeting Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning, ${widget.profile.name}! 👋',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Track your target university admissions prep',
                            style: TextStyle(
                                fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 1. TARGET UNIVERSITY PREFERENCE SLIDER / CAROUSEL
                DashboardUniversityCarousel(
                  universities: _service.getRoadmapsForTargets(
                      widget.profile.targetSelections.keys.toList()),
                  activeKey: activeKey,
                  onSelectUniversity: (key) =>
                      _service.setActiveUniversity(key),
                  onEditTargets: widget.onEditProfile != null
                      ? () => widget.onEditProfile!(2)
                      : null,
                  onViewRoadmap: () => widget.onSwitchTab?.call(1),
                ),
                const SizedBox(height: 18),
                // 2. UNIVERSITY SPECIFIC DAILY EXAM ARENA CARD (100% DATABASE-DRIVEN)
                DashboardTodayTestCard(
                  currentUni: currentUni,
                  dailyTestFuture: _dailyTestFuture,
                  remainingTimeLeft: _remainingLeft,
                  onLaunchExam: _launchTodayExam,
                ),
                const SizedBox(height: 20),
                // 3. UNIVERSITY QUESTION PATTERN SECTIONS
                DashboardSectionPatternList(
                  currentUni: currentUni,
                  onViewRoadmap: () => widget.onSwitchTab?.call(1),
                ),
                const SizedBox(height: 20),
                // ⚡ 4. LIVE 1v1 QUIZ DUEL BATTLE ⚡
                InkWell(
                  onTap: widget.onStartBattle,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF542747), Color(0xFF542747)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF542747)),
                      boxShadow: colors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFDC2626).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: const Icon(Icons.flash_on_rounded,
                              color: Color(0xFFF87171), size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Live 1v1 Quiz Duel (PvP Battle)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '15s fast-paced rounds • Compete directly with candidates',
                                style: TextStyle(
                                    color: Color(0xFFFFF3E6), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white70, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}

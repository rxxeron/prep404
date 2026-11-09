import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep404_logo.dart';
import '../../../../core/widgets/prep_bounce_tap.dart';
import '../../../onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../../battle/presentation/controllers/battle_controller.dart';
import '../../../battle/presentation/widgets/battle_arena_view.dart';
import '../../../practice_map/presentation/screens/admission_hiking_roadmap_screen.dart';
import '../../../question_bank/presentation/screens/chorcha_question_bank_screen.dart';
import '../../../exam/presentation/screens/daily_exam_arena_screen.dart';
import '../../../analytics/presentation/screens/exam_history_screen.dart';
import '../../../analytics/presentation/screens/study_streak_detail_screen.dart';
import 'notification_center_screen.dart';
import 'private_uni_dashboard_screen.dart';
import 'profile_settings_screen.dart';
import '../widgets/chorcha_bottom_nav_bar.dart';

/// Main Application Shell & Dynamic Tab Router
class MainDashboardScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile>? onProfileUpdated;
  final VoidCallback onResetProfile;
  final Future<void> Function(String reason)? onDeleteAccount;

  const MainDashboardScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
    required this.onResetProfile,
    this.onDeleteAccount,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  late UserProfile _currentProfile;
  late final BattleController _battleController;
  late final AnimationController _tabTransitionController;
  int _activeStreakDays = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    final cached = ExamRepository.cachedStreak;
    if (cached != null && cached['streak'] is Map) {
      _activeStreakDays = (cached['streak']['currentStreak'] as num?)?.toInt() ?? widget.profile.studyStreakDays;
    } else {
      _activeStreakDays = widget.profile.studyStreakDays;
    }
    _syncLiveStreak();
    _syncUnreadNotifications();
    ApiClient().recordAppOpen();
    _battleController = BattleController();
    _tabTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          FcmService().showPermissionPromptIfNeeded(context);
        }
      });
    });
  }

  Future<void> _syncUnreadNotifications() async {
    try {
      final list = await ExamRepository().fetchUserNotifications(
        userId: _currentProfile.id.isNotEmpty ? _currentProfile.id : null,
      );
      if (mounted) {
        final unread = list.where((n) => !n.isRead).length;
        if (unread != _unreadNotificationCount) {
          setState(() {
            _unreadNotificationCount = unread;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _syncLiveStreak() async {
    try {
      final effectiveUid = _currentProfile.id.isNotEmpty
          ? _currentProfile.id
          : (SupabaseService().currentUser?.id ?? CacheService().loadProfile()?.id);
      final res = await ExamRepository().fetchUserStreakDetails(
        userId: effectiveUid,
      );
      if (res != null && res['success'] == true && res['streak'] is Map) {
        final cur = (res['streak']['currentStreak'] as num?)?.toInt() ?? 0;
        if (mounted && (cur != _activeStreakDays || _currentProfile.studyStreakDays != cur)) {
          setState(() {
            _activeStreakDays = cur;
            _currentProfile = _currentProfile.copyWith(studyStreakDays: cur);
          });
          CacheService().saveProfile(_currentProfile);
          try {
            final container = ProviderScope.containerOf(context, listen: false);
            container.read(userProfileProvider.notifier).setProfile(_currentProfile);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  void _switchTab(int index) {
    if (index == _currentTabIndex) return;
    setState(() => _currentTabIndex = index);
    if (MediaQuery.of(context).disableAnimations) {
      _tabTransitionController.value = 1;
    } else {
      _tabTransitionController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant MainDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      _currentProfile = widget.profile;
      _activeStreakDays = widget.profile.studyStreakDays;
      _syncLiveStreak();
      _syncUnreadNotifications();
    }
  }

  void _handleProfileUpdated(UserProfile newProfile) {
    setState(() {
      _currentProfile = newProfile;
    });
    widget.onProfileUpdated?.call(newProfile);
  }

  void _openEditFlow({int step = 0}) async {
    UserProfile? updated;
    if (GoRouter.maybeOf(context) != null) {
      updated = await context.push<UserProfile>(
        AppRoutes.onboarding,
        extra: _currentProfile,
      );
    } else {
      updated = await Navigator.of(context).push<UserProfile>(
        MaterialPageRoute(
          builder: (_) => OnboardingFlowScreen(
            initialProfile: _currentProfile,
            initialStep: step,
            isEditing: true,
            onCompleted: _handleProfileUpdated,
          ),
        ),
      );
    }
    final res = updated;
    if (res != null && mounted) {
      _handleProfileUpdated(res);
    }
  }

  void _showStreakModal(BuildContext context) {
    final effectiveStreak = _activeStreakDays > 0 ? _activeStreakDays : _currentProfile.studyStreakDays;
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.streakModal).then((_) => _syncLiveStreak());
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StudyStreakModalContent(
          streakDays: effectiveStreak,
          userId: _currentProfile.id,
          onKeepPracticing: () {
            Navigator.pop(ctx);
            _switchTab(1);
          },
        ),
      ).then((_) => _syncLiveStreak());
    }
  }

  @override
  void dispose() {
    _battleController.dispose();
    _tabTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayStreak = _activeStreakDays > 0 ? _activeStreakDays : _currentProfile.studyStreakDays;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        centerTitle: true,
        leadingWidth: 78,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: Tooltip(
              message: 'Streak: $displayStreak Day${displayStreak == 1 ? '' : 's'}',
              child: PrepBounceTap(
                scaleFactor: 0.94,
                onTap: () => _showStreakModal(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentSunshine.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: colors.deepPlum,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$displayStreak',
                        style: TextStyle(
                          color: colors.deepPlum,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Prep404Logo(height: 32),
        actions: [
          // In-App Notification Center Trigger
          Center(
            child: Tooltip(
              message: 'Notifications',
              child: PrepBounceTap(
                scaleFactor: 0.92,
                onTap: () async {
                  if (GoRouter.maybeOf(context) != null) {
                    await context.push(AppRoutes.notifications);
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationCenterScreen(
                          userId: _currentProfile.id,
                        ),
                      ),
                    );
                  }
                  _syncUnreadNotifications();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: colors.textPrimary,
                        size: 20,
                      ),
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colors.tangerine,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Tooltip(
                message: 'Profile & Account',
                child: PrepBounceTap(
                  scaleFactor: 0.92,
                  onTap: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.push(AppRoutes.profile);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileSettingsScreen(
                            profile: _currentProfile,
                            onProfileUpdated: _handleProfileUpdated,
                            onLogOut: widget.onResetProfile,
                            onDeleteAccount: widget.onDeleteAccount,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.deepPlum,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        context.isDark
                            ? 'assets/images/brand/Prep404_Profile_Dark.png'
                            : 'assets/images/brand/Prep404_Profile_Light.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            _currentProfile.name.trim().isNotEmpty
                                ? _currentProfile.name.trim()[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _tabTransitionController,
        builder: (context, child) {
          final progress =
              Curves.easeOutCubic.transform(_tabTransitionController.value);
          return Opacity(
            opacity: 0.86 + (progress * 0.14),
            child: Transform.translate(
              offset: Offset(0, (1 - progress) * 5),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // Tab 0: Home (Target-University Centric Dashboard)
            TickerMode(
              enabled: _currentTabIndex == 0,
              child: PrivateUniDashboardScreen(
                profile: _currentProfile,
                onEditProfile: (step) => _openEditFlow(step: step),
                onStartPractice: ({String? topicId, String? subjectId}) {
                  _switchTab(2);
                },
                onStartBattle: () {
                  if (GoRouter.maybeOf(context) != null) {
                    context.push(AppRoutes.battle);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text(
                              'Live PvP Battle Arena',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          body: BattleArenaView(controller: _battleController),
                        ),
                      ),
                    );
                  }
                },
                onSwitchTab: _switchTab,
              ),
            ),

            // Tab 1: Plan (Visual Admission Hiking Roadmap)
            TickerMode(
              enabled: _currentTabIndex == 1,
              child: AdmissionHikingRoadmapScreen(
                targetUniversityKeys:
                    _currentProfile.targetSelections.keys.toList(),
                onStartTest: () => _switchTab(3),
              ),
            ),

            // Tab 2: Question Bank (University-wise, Topic-wise & Model Tests)
            TickerMode(
              enabled: _currentTabIndex == 2,
              child: ChorchaQuestionBankScreen(
                profile: _currentProfile,
                onSelectTrack: (track) {
                  _switchTab(3);
                },
              ),
            ),

            // Tab 3: Daily Test (10 AM - 10 PM Live Window & Isolated Leaderboards)
            TickerMode(
              enabled: _currentTabIndex == 3,
              child: DailyExamArenaScreen(
                candidateName: _currentProfile.name,
                candidateCollege: _currentProfile.institutionName,
                targetUniversityKeys:
                    _currentProfile.targetSelections.keys.toList(),
              ),
            ),

            // Tab 4: History (Exam History & Mistake Vault)
            TickerMode(
              enabled: _currentTabIndex == 4,
              child: ExamHistoryScreen(
                userId: _currentProfile.id,
                onPracticeMistakes: () => _switchTab(2),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 8),
        child: ChorchaBottomNavBar(
          selectedIndex: _currentTabIndex,
          onItemSelected: (idx) {
            HapticFeedback.selectionClick();
            _switchTab(idx);
          },
        ),
      ),
    );
  }
}

/// Self-contained Study Streak Content for Bottom Sheet & Routed Modal
class StudyStreakModalContent extends StatefulWidget {
  final int streakDays;
  final String? userId;
  final VoidCallback? onKeepPracticing;

  const StudyStreakModalContent({
    super.key,
    required this.streakDays,
    this.userId,
    this.onKeepPracticing,
  });

  @override
  State<StudyStreakModalContent> createState() => _StudyStreakModalContentState();
}

class _StudyStreakModalContentState extends State<StudyStreakModalContent> {
  late int _streakDays;
  List<bool> _weeklyDaysActive = [];

  @override
  void initState() {
    super.initState();
    final cached = ExamRepository.cachedStreak;
    if (cached != null && cached['streak'] is Map) {
      final s = cached['streak'] as Map<String, dynamic>;
      _streakDays = (s['currentStreak'] as num?)?.toInt() ?? widget.streakDays;
      final rawWeekly = s['weeklyDaysActive'] as List? ?? [];
      if (rawWeekly.isNotEmpty) {
        _weeklyDaysActive = rawWeekly.map((e) => e == true).toList();
      }
    } else {
      _streakDays = widget.streakDays;
    }
    _fetchLiveStreak();
  }

  Future<void> _fetchLiveStreak() async {
    try {
      final effectiveUid = widget.userId ??
          SupabaseService().currentUser?.id ??
          CacheService().loadProfile()?.id;
      final res = await ExamRepository().fetchUserStreakDetails(userId: effectiveUid);
      if (res != null && res['success'] == true && res['streak'] is Map) {
        final s = res['streak'] as Map<String, dynamic>;
        final cur = (s['currentStreak'] as num?)?.toInt() ?? _streakDays;
        final rawWeekly = s['weeklyDaysActive'] as List? ?? [];
        if (mounted) {
          setState(() {
            _streakDays = cur;
            if (rawWeekly.isNotEmpty) {
              _weeklyDaysActive = rawWeekly.map((e) => e == true).toList();
            }
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_streakDays ${_streakDays == 1 ? "Day" : "Days"} Study Streak!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    _streakDays > 0
                        ? '1.5x XP Boost Active'
                        : 'Practice 1 question daily to begin your streak!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Builder(builder: (context) {
            final now = DateTime.now();
            final currentDayIndex = now.weekday - 1; // 0 for Mon, 6 for Sun
            final dayLetters = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = dayLetters[index];
                  final isToday = index == currentDayIndex;
                  final daysAgo = currentDayIndex - index;
                  final hasDbActivity =
                      _weeklyDaysActive.length > index && _weeklyDaysActive[index];
                  final isCompleted = hasDbActivity ||
                      (_streakDays > 0 && daysAgo > 0 && daysAgo <= _streakDays);

                  Color circleColor;
                  Widget iconWidget;
                  Border? circleBorder;

                  if (isCompleted) {
                    circleColor = const Color(0xFFF59E0B);
                    iconWidget = const Icon(
                      Icons.check,
                      size: 18,
                      color: Colors.white,
                    );
                  } else if (isToday) {
                    circleColor = const Color(0xFFFEF3C7);
                    circleBorder = Border.all(
                        color: const Color(0xFFF59E0B), width: 1.5);
                    iconWidget = const Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    );
                  } else {
                    circleColor = colors.surface;
                    circleBorder = Border.all(color: colors.borderSubtle);
                    iconWidget = Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.textMuted.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: circleColor,
                          border: circleBorder,
                        ),
                        child: Center(child: iconWidget),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday
                              ? const Color(0xFFF59E0B)
                              : colors.textSecondary,
                          fontWeight:
                              isToday ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF059669),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _streakDays > 0
                        ? '1 Streak Freeze Protected • Practice 1 question daily to keep your flame!'
                        : 'Streak Freeze Available • Practice 1 question today to begin your streak!',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.tangerine,
                side: BorderSide(
                    color: colors.tangerine.withValues(alpha: 0.35), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.insights_rounded, size: 17),
              label: const Text(
                'View Streak Timeline & History ➔',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (GoRouter.maybeOf(context) != null) {
                  context.push(AppRoutes.streakDetail);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StudyStreakDetailScreen(),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.tangerine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onKeepPracticing ?? () => Navigator.pop(context),
              child: const Text(
                'Keep Practicing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../models/user_profile.dart';
import '../repositories/exam_repository.dart';
import '../../features/analytics/data/models/exam_history_item.dart';
import '../../features/analytics/presentation/screens/exam_history_screen.dart';
import '../../features/analytics/presentation/screens/exam_script_review_screen.dart';
import '../../features/analytics/presentation/screens/mistake_vault_screen.dart';
import '../../features/analytics/presentation/screens/study_streak_detail_screen.dart';
import '../../features/dashboard/presentation/widgets/profile_dialogs.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ai_tutor/services/ai_socratic_tutor.dart';
import '../../features/practice/presentation/widgets/dynamic_practice_view.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/battle/presentation/controllers/battle_controller.dart';
import '../../features/battle/presentation/widgets/battle_arena_view.dart';
import '../../features/dashboard/presentation/screens/about_us_screen.dart';
import '../../features/dashboard/presentation/screens/account_info_screen.dart';
import '../../features/dashboard/presentation/screens/community_links_screen.dart';
import '../../features/dashboard/presentation/screens/learner_support_screen.dart';
import '../../features/dashboard/presentation/screens/notification_center_screen.dart';
import '../../features/dashboard/presentation/screens/notification_settings_screen.dart';
import '../../features/dashboard/presentation/screens/profile_settings_screen.dart';
import '../../features/dashboard/presentation/screens/reported_questions_screen.dart';
import '../../features/dashboard/presentation/screens/subscription_screen.dart';
import '../../features/dashboard/presentation/screens/upgrade_screen.dart';
import '../../features/exam/presentation/screens/daily_exam_arena_screen.dart';
import '../../features/exam/presentation/screens/live_model_test_screen.dart';
import '../../features/exam/presentation/screens/model_test_catalog_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../../features/practice_map/presentation/screens/admission_hiking_roadmap_screen.dart';
import '../../features/question_bank/presentation/screens/chorcha_question_bank_screen.dart';
import '../../features/question_bank/presentation/screens/subject_chapter_directory_screen.dart';
import '../../features/question_bank/presentation/screens/university_detail_question_bank_screen.dart';

/// Central Declarative Routes for Prep404
class AppRoutes {
  static const String root = '/';
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';

  // Profile and Settings
  static const String profile = '/profile';
  static const String accountInfo = '/profile/account-info';
  static const String notificationSettings = '/profile/notifications';
  static const String aboutUs = '/profile/about-us';
  static const String communityLinks = '/profile/community';
  static const String learnerSupport = '/profile/support';
  static const String upgrade = '/profile/upgrade';
  static const String subscription = '/profile/subscription';
  static const String reportedQuestions = '/profile/reported-questions';

  // Exams
  static const String dailyExam = '/exams/daily';
  static const String modelTestCatalog = '/exams/catalog';
  static const String liveModelTest = '/exams/live';
  static const String examHistory = '/exams/history';
  static const String examScriptReview = '/exams/review';
  static const String mistakeVault = '/exams/vault';

  // Practice & Roadmap
  static const String hikingRoadmap = '/roadmap';
  static const String questionBank = '/question-bank';
  static const String subjectChapters = '/question-bank/chapters';
  static const String universityDetail = '/question-bank/university';

  // Modals & Dialogs
  static const String streakModal = '/dashboard/streak';
  static const String streakDetail = '/dashboard/streak-detail';
  static const String notifications = '/dashboard/notifications';
  static const String logoutDialog = '/profile/logout';
  static const String deleteAccountDialog = '/profile/delete-account';

  // Battle & Practice
  static const String battle = '/battle';
  static const String practice = '/practice';
}

/// Listenable that notifies GoRouter to re-evaluate route redirection
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<UserProfile?>(
        userProfileProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Riverpod Provider delivering the configured GoRouter instance
final appRouterProvider =
    Provider.family<GoRouter, Future<void> Function()?>((ref, initializeApp) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.root,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        name: 'root',
        builder: (context, state) =>
            RootFlowController(initializeApp: initializeApp),
        routes: [
          GoRoute(
            path: 'auth',
            name: 'auth',
            builder: (context, state) => AuthScreen(
              language: ref.watch(appLanguageProvider),
              onLanguageChanged:
                  ref.read(appLanguageProvider.notifier).setLanguage,
              onAuthSuccess: (token, userJson) {
                ref.read(authStateProvider.notifier).setSession(
                      token: token,
                      name: userJson['name'] as String? ?? '',
                      phone: userJson['phone'] as String? ?? '',
                    );
              },
            ),
          ),
          GoRoute(
            path: 'onboarding',
            name: 'onboarding',
            builder: (context, state) {
              final auth = ref.watch(authStateProvider);
              final editProfile = state.extra is UserProfile
                  ? state.extra as UserProfile
                  : null;
              return OnboardingFlowScreen(
                language: ref.watch(appLanguageProvider),
                onLanguageChanged:
                    ref.read(appLanguageProvider.notifier).setLanguage,
                initialName: auth.candidateName,
                initialPhone: auth.candidatePhone,
                initialProfile: editProfile,
                isEditing: editProfile != null,
                onSignOut: () => ref.read(authStateProvider.notifier).signOut(),
                onCompleted: (profile) {
                  ref.read(userProfileProvider.notifier).setProfile(profile);
                  if (context.canPop()) {
                    context.pop(profile);
                  } else {
                    context.go(AppRoutes.dashboard);
                  }
                },
              );
            },
          ),
          GoRoute(
            path: 'dashboard',
            name: 'dashboard',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              if (profile == null) {
                return RootFlowController(initializeApp: initializeApp);
              }
              return MainDashboardScreen(
                profile: profile,
                onProfileUpdated: (p) =>
                    ref.read(userProfileProvider.notifier).updateProfile(p),
                onResetProfile: () {
                  ref.read(authStateProvider.notifier).signOut();
                  ref.read(userProfileProvider.notifier).clear();
                  context.go(AppRoutes.root);
                },
                onDeleteAccount: (reason) async {
                  await ref
                      .read(authStateProvider.notifier)
                      .deleteAccount(reason);
                  ref.read(userProfileProvider.notifier).clear();
                  if (context.mounted) {
                    context.go(AppRoutes.root);
                  }
                },
              );
            },
            routes: [
              GoRoute(
                path: 'streak',
                name: 'streakModal',
                pageBuilder: (context, state) {
                  final profile = ref.watch(userProfileProvider);
                  return CustomTransitionPage<void>(
                    key: state.pageKey,
                    opaque: false,
                    barrierDismissible: true,
                    barrierColor: Colors.black54,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Material(
                        color: Colors.transparent,
                        child: Builder(builder: (context) {
                          final cached = ExamRepository.cachedStreak;
                          final effectiveStreak = (cached != null && cached['streak'] is Map)
                              ? ((cached['streak']['currentStreak'] as num?)?.toInt() ?? profile?.studyStreakDays ?? 0)
                              : (profile?.studyStreakDays ?? 0);
                          return StudyStreakModalContent(
                            streakDays: effectiveStreak,
                            userId: profile?.id,
                            onKeepPracticing: () => context.pop(),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'streak-detail',
                name: 'streakDetail',
                builder: (context, state) {
                  final profile = ref.watch(userProfileProvider);
                  return StudyStreakDetailScreen(userId: profile?.id);
                },
              ),
              GoRoute(
                path: 'notifications',
                name: 'notificationCenter',
                builder: (context, state) {
                  final profile = ref.watch(userProfileProvider);
                  return NotificationCenterScreen(userId: profile?.id);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              if (profile == null) {
                return RootFlowController(initializeApp: initializeApp);
              }
              return ProfileSettingsScreen(
                profile: profile,
                onLanguageChanged:
                    ref.read(appLanguageProvider.notifier).setLanguage,
                onProfileUpdated: (p) =>
                    ref.read(userProfileProvider.notifier).updateProfile(p),
                onLogOut: () {
                  ref.read(authStateProvider.notifier).signOut();
                  ref.read(userProfileProvider.notifier).clear();
                  context.go(AppRoutes.root);
                },
                onDeleteAccount: (reason) async {
                  await ref
                      .read(authStateProvider.notifier)
                      .deleteAccount(reason);
                  ref.read(userProfileProvider.notifier).clear();
                  if (context.mounted) {
                    context.go(AppRoutes.root);
                  }
                },
              );
            },
            routes: [
              GoRoute(
                path: 'account-info',
                name: 'accountInfo',
                builder: (context, state) {
                  final profile = ref.watch(userProfileProvider);
                  if (profile == null) {
                    return RootFlowController(initializeApp: initializeApp);
                  }
                  return AccountInfoScreen(
                    profile: profile,
                    onProfileUpdated: (p) =>
                        ref.read(userProfileProvider.notifier).updateProfile(p),
                    onLogOut: () {
                      ref.read(authStateProvider.notifier).signOut();
                      ref.read(userProfileProvider.notifier).clear();
                      context.go(AppRoutes.root);
                    },
                    onDeleteAccount: (reason) async {
                      await ref
                          .read(authStateProvider.notifier)
                          .deleteAccount(reason);
                      ref.read(userProfileProvider.notifier).clear();
                      if (context.mounted) {
                        context.go(AppRoutes.root);
                      }
                    },
                  );
                },
              ),
              GoRoute(
                path: 'notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: 'about-us',
                name: 'aboutUs',
                builder: (context, state) => const AboutUsScreen(),
              ),
              GoRoute(
                path: 'community',
                name: 'community',
                builder: (context, state) => const CommunityLinksScreen(),
              ),
              GoRoute(
                path: 'support',
                name: 'support',
                builder: (context, state) => const LearnerSupportScreen(),
              ),
              GoRoute(
                path: 'upgrade',
                name: 'upgrade',
                builder: (context, state) => const UpgradeScreen(),
              ),
              GoRoute(
                path: 'subscription',
                name: 'subscription',
                builder: (context, state) => const SubscriptionScreen(),
              ),
              GoRoute(
                path: 'reported-questions',
                name: 'reportedQuestions',
                builder: (context, state) => const ReportedQuestionsScreen(),
              ),
              GoRoute(
                path: 'logout',
                name: 'logoutDialog',
                pageBuilder: (context, state) => CustomTransitionPage<void>(
                  key: state.pageKey,
                  opaque: false,
                  barrierDismissible: true,
                  barrierColor: Colors.black54,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  child: LogoutConfirmDialog(
                    colors: context.colors,
                    onConfirm: () async {
                      await ref.read(authStateProvider.notifier).signOut();
                      ref.read(userProfileProvider.notifier).clear();
                      if (context.mounted) {
                        context.go(AppRoutes.root);
                      }
                    },
                  ),
                ),
              ),
              GoRoute(
                path: 'delete-account',
                name: 'deleteAccountDialog',
                pageBuilder: (context, state) => CustomTransitionPage<void>(
                  key: state.pageKey,
                  opaque: false,
                  barrierDismissible: true,
                  barrierColor: Colors.black54,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                  child: DeleteAccountDialog(
                    colors: context.colors,
                    onConfirm: (reason) async {
                      await ref
                          .read(authStateProvider.notifier)
                          .deleteAccount(reason);
                      ref.read(userProfileProvider.notifier).clear();
                      if (context.mounted) {
                        context.go(AppRoutes.root);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'exams/daily',
            name: 'dailyExam',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              return DailyExamArenaScreen(
                candidateName: profile?.name ?? 'Candidate',
                candidateCollege: profile?.institutionName ?? 'College',
                targetUniversityKeys:
                    profile?.targetSelections.keys.toList() ?? [],
              );
            },
          ),
          GoRoute(
            path: 'exams/catalog',
            name: 'modelTestCatalog',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              return ModelTestCatalogScreen(
                candidateName: profile?.name ?? 'Candidate',
                candidateCollege: profile?.institutionName ?? 'College',
              );
            },
          ),
          GoRoute(
            path: 'exams/live',
            name: 'liveModelTest',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return LiveModelTestScreen(
                slug: extra['slug'] as String? ?? 'live-model-test',
                title: extra['title'] as String?,
                durationMinutes: extra['durationMinutes'] as int? ?? 30,
                candidateName: profile?.name ?? 'Candidate',
                candidateCollege: profile?.institutionName ?? 'College',
                onExit: () => context.pop(),
              );
            },
          ),
          GoRoute(
            path: 'exams/history',
            name: 'examHistory',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              return ExamHistoryScreen(
                userId: profile?.id,
                onPracticeMistakes: () => context.go(AppRoutes.hikingRoadmap),
              );
            },
          ),
          GoRoute(
            path: 'exams/review',
            name: 'examScriptReview',
            builder: (context, state) {
              final item = state.extra as ExamHistoryItem?;
              if (item == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Exam Review')),
                  body: const Center(child: Text('No exam attempt provided.')),
                );
              }
              return ExamScriptReviewScreen(item: item);
            },
          ),
          GoRoute(
            path: 'exams/vault',
            name: 'mistakeVault',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              return MistakeVaultScreen(userId: profile?.id);
            },
          ),
          GoRoute(
            path: 'roadmap',
            name: 'hikingRoadmap',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              return AdmissionHikingRoadmapScreen(
                targetUniversityKeys:
                    profile?.targetSelections.keys.toList() ?? [],
                onStartTest: () => context.go(AppRoutes.dailyExam),
              );
            },
          ),
          GoRoute(
            path: 'question-bank',
            name: 'questionBank',
            builder: (context, state) {
              final profile = ref.watch(userProfileProvider);
              if (profile == null) {
                return RootFlowController(initializeApp: initializeApp);
              }
              return ChorchaQuestionBankScreen(profile: profile);
            },
            routes: [
              GoRoute(
                path: 'chapters',
                name: 'subjectChapters',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return SubjectChapterDirectoryScreen(
                    subjectTitle: extra['title'] as String? ?? 'Subject',
                    subjectSlug: extra['slug'] as String? ?? 'subject',
                    icon: extra['icon'] as IconData? ?? Icons.menu_book_rounded,
                    themeColor:
                        extra['color'] as Color? ?? const Color(0xFF059669),
                  );
                },
              ),
              GoRoute(
                path: 'university',
                name: 'universityDetail',
                builder: (context, state) {
                  final profile = ref.watch(userProfileProvider);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return UniversityDetailQuestionBankScreen(
                    universityKey: extra['universityKey'] as String? ?? 'nsu',
                    universityName: extra['universityName'] as String? ??
                        'North South University',
                    shortCode: extra['shortCode'] as String? ?? 'NSU',
                    candidateName: profile?.name ?? 'Candidate',
                    candidateCollege: profile?.institutionName ?? 'College',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'battle',
            name: 'battle',
            builder: (context, state) => Scaffold(
              appBar: AppBar(
                title: const Text('PvP Quiz Battle'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              body: BattleArenaView(controller: BattleController()),
            ),
          ),
          GoRoute(
            path: 'practice',
            name: 'practice',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final title = extra['title'] as String? ?? 'Practice Drill';
              final subjectId = extra['subjectId'] as String?;
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                ),
                body: DynamicPracticeView(
                  studyHintService: SocraticStudyHintService(),
                  initialSubjectId: subjectId,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
});

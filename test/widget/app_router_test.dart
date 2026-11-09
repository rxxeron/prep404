import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/core/models/user_profile.dart';
import 'package:prep404/core/providers/app_providers.dart';
import 'package:prep404/core/routing/app_router.dart';
import 'package:prep404/features/dashboard/presentation/screens/about_us_screen.dart';
import 'package:prep404/features/dashboard/presentation/screens/notification_settings_screen.dart';
import 'package:prep404/features/dashboard/presentation/screens/community_links_screen.dart';
import 'package:prep404/features/dashboard/presentation/screens/learner_support_screen.dart';
import 'package:prep404/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:prep404/features/dashboard/presentation/widgets/profile_dialogs.dart';
import 'package:prep404/features/exam/presentation/screens/model_test_catalog_screen.dart';
import 'package:prep404/features/practice/presentation/widgets/dynamic_practice_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GoRouter Declarative Routing Tests', () {
    const testProfile = UserProfile(
      id: 'usr_router_test',
      name: 'Adil Hossain',
      phone: '01911223344',
      medium: StudentMedium.bangla,
      academicBatch: "HSC '25",
      institutionName: 'Rajuk Uttara Model College',
      targetSelections: {
        'nsu': ['seps_cse'],
      },
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestApp({
      required String initialLocation,
      UserProfile? profile = testProfile,
    }) {
      return ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) {
            final notifier = UserProfileNotifier(ref.watch(cacheServiceProvider));
            if (profile != null) notifier.setProfile(profile);
            return notifier;
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(appRouterProvider(() async {}));
            router.go(initialLocation);
            return MaterialApp.router(
              routerConfig: router,
            );
          },
        ),
      );
    }

    testWidgets('navigates to /profile/about-us directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(initialLocation: AppRoutes.aboutUs));
      await tester.pumpAndSettle();

      expect(find.byType(AboutUsScreen), findsOneWidget);
      expect(find.text('Version 1.0.0 • 2026 Edition'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
    });

    testWidgets('navigates to /profile/notifications directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.notificationSettings));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Daily Practice Reminders'), findsOneWidget);
    });

    testWidgets('navigates to /profile/community directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.communityLinks));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityLinksScreen), findsOneWidget);
      expect(find.text('Prep404 Community'), findsOneWidget);
    });

    testWidgets('navigates to /profile/support directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.learnerSupport));
      await tester.pumpAndSettle();

      expect(find.byType(LearnerSupportScreen), findsOneWidget);
      expect(find.text('Learner support'), findsOneWidget);
      expect(find.text('How can we help?'), findsOneWidget);
    });

    testWidgets('navigates to /exams/catalog directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.modelTestCatalog));
      await tester.pumpAndSettle();

      expect(find.byType(ModelTestCatalogScreen), findsOneWidget);
      expect(find.text('Model Tests'), findsOneWidget);
    });

    testWidgets('navigates to /dashboard/streak directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.streakModal));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(StudyStreakModalContent), findsOneWidget);
      expect(find.text('Keep Practicing'), findsOneWidget);
    });

    testWidgets('navigates to /profile/logout directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.logoutDialog));
      await tester.pumpAndSettle();

      expect(find.byType(LogoutConfirmDialog), findsOneWidget);
      expect(find.text('Are you sure you want to log out of Prep404?'),
          findsOneWidget);
    });

    testWidgets('navigates to /profile/delete-account directly via GoRouter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          createTestApp(initialLocation: AppRoutes.deleteAccountDialog));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountDialog), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(DeleteAccountDialog),
            matching: find.text('Delete Account'),
          ),
          findsOneWidget);
      expect(find.text('Why are you leaving? (your answer is optional)'),
          findsOneWidget);
    });

    testWidgets('navigates to /practice directly via GoRouter',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(createTestApp(initialLocation: AppRoutes.practice));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DynamicPracticeView), findsOneWidget);
    });
  });
}

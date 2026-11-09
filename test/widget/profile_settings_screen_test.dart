import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/user_profile.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/features/dashboard/presentation/screens/profile_settings_screen.dart';

void main() {
  group('ProfileSettingsScreen Widget Tests', () {
    const testProfile = UserProfile(
      id: 'usr_test_101',
      name: 'Admission Candidate',
      phone: '01711223344',
      medium: StudentMedium.bangla,
      academicBatch: "HSC '25",
      institutionName: 'Notre Dame College',
      targetSelections: {
        'nsu': ['seps_cse'],
      },
    );

    testWidgets('renders all Chorcha-style profile sections in English',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool loggedOut = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () => loggedOut = true,
          ),
        ),
      );

      // Verify name, batch, avatar
      expect(find.text('Admission Candidate'), findsOneWidget);
      expect(find.text("Batch: HSC '25"), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Verify reminder banner and link account
      expect(
          find.textContaining(
              'Turn on notifications so you never miss practice!'),
          findsOneWidget);
      expect(find.text('Linked Accounts'), findsOneWidget);

      // Verify menu groups in English
      expect(find.text('Account Info'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Prep404 Community'), findsOneWidget);

      // Open logout confirmation dialog
      final logoutItem = find.text('Log Out');
      expect(logoutItem, findsOneWidget);
      await tester.ensureVisible(logoutItem);
      await tester.tap(logoutItem);
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Log Out'), findsWidgets);
      expect(find.text('Are you sure you want to log out of Prep404?'),
          findsOneWidget);

      // Confirm logout
      await tester.tap(find.text('Log Out').last);
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    });

    testWidgets(
        'tapping Delete Account shows Delete Account dialog instead of Log Out',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool accountDeleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
            onDeleteAccount: (reason) async {
              accountDeleted = true;
            },
          ),
        ),
      );

      final deleteItem = find.text('Delete Account');
      expect(deleteItem, findsOneWidget);
      await tester.ensureVisible(deleteItem);
      await tester.tap(deleteItem);
      await tester.pumpAndSettle();

      // Check Delete Account dialog
      expect(find.text('Confirm Log Out'), findsNothing);
      expect(find.text('Delete Account'), findsWidgets);
      expect(
          find.textContaining(
              'Are you sure you want to permanently delete your account?'),
          findsOneWidget);

      // Confirm Delete
      final deleteBtn = find.text('Delete Permanently');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(accountDeleted, isTrue);
    });

    testWidgets(
        'social account actions expose labels and 44px accessible targets',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      for (final label in [
        'Link Facebook account',
        'Link Google account',
        'Link Apple account',
      ]) {
        final action = find.bySemanticsLabel(label);
        expect(action, findsOneWidget);
        expect(tester.getRect(action).height, greaterThanOrEqualTo(44));
        expect(
          tester.getSemantics(action),
          matchesSemantics(label: label, isButton: true, hasTapAction: true),
        );
      }
    });

    testWidgets('tapping Prep404 Community navigates to CommunityLinksScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final communityItem = find.text('Prep404 Community');
      expect(communityItem, findsOneWidget);
      await tester.ensureVisible(communityItem);
      await tester.tap(communityItem);
      await tester.pumpAndSettle();

      expect(find.text('Connect with Prep404'), findsOneWidget);
      expect(find.text('Official Channels'), findsOneWidget);
    });

    testWidgets('profile remains usable at 320px with 200% text scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final previousFlutterErrorHandler = FlutterError.onError;
      final layoutErrors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          layoutErrors.add(details);
        }
        previousFlutterErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousFlutterErrorHandler);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: ProfileSettingsScreen(
                profile: testProfile,
                onLogOut: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        layoutErrors,
        isEmpty,
        reason: layoutErrors.map((details) => details.toString()).join('\n'),
      );
      final googleAction = find.bySemanticsLabel('Link Google account');
      expect(googleAction, findsOneWidget);
      expect(tester.getRect(googleAction).height, greaterThanOrEqualTo(44));
    });

    testWidgets('tapping Notifications navigates to NotificationSettingsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final notificationsItem = find.text('Notifications');
      expect(notificationsItem, findsOneWidget);
      await tester.ensureVisible(notificationsItem);
      await tester.tap(notificationsItem);
      await tester.pumpAndSettle();

      expect(find.text('Study Habits & Reminders'), findsOneWidget);
      expect(find.text('Daily Practice Reminders'), findsOneWidget);
    });

    testWidgets('tapping About Us navigates to AboutUsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final aboutUsItem = find.text('About Us');
      expect(aboutUsItem, findsOneWidget);
      await tester.ensureVisible(aboutUsItem);
      await tester.tap(aboutUsItem);
      await tester.pumpAndSettle();

      expect(find.text('Version 1.0.0 • 2026 Edition'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
    });

    testWidgets('tapping Account Info navigates to AccountInfoScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final accountInfoItem = find.text('Account Info');
      expect(accountInfoItem, findsOneWidget);
      await tester.ensureVisible(accountInfoItem);
      await tester.tap(accountInfoItem);
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Academic Details'), findsOneWidget);
      expect(find.text('Admission Candidate'), findsWidgets);
      expect(find.text("Batch: HSC '25"), findsOneWidget);
    });

    testWidgets('tapping Upgrade navigates to UpgradeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final upgradeItem = find.text('Upgrade');
      expect(upgradeItem, findsOneWidget);
      await tester.ensureVisible(upgradeItem);
      await tester.tap(upgradeItem);
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Plan'), findsOneWidget);
      expect(find.text('Unlock Every Varsity Blueprint'), findsOneWidget);
      expect(find.text('Prep404 Pro Pass'), findsOneWidget);
      expect(find.text('Varsity Elite Pass'), findsOneWidget);
    });

    testWidgets('tapping Subscription navigates to SubscriptionScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final subscriptionItem = find.text('Subscription');
      expect(subscriptionItem, findsOneWidget);
      await tester.ensureVisible(subscriptionItem);
      await tester.tap(subscriptionItem);
      await tester.pumpAndSettle();

      expect(find.text('Subscription'), findsWidgets);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('BILLING & INVOICE HISTORY'), findsOneWidget);
      expect(find.text('SUBSCRIPTION CONTROLS'), findsOneWidget);
    });

    testWidgets('tapping Learning analytics privacy opens modal with Switch ON by default',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSettingsScreen(
            profile: testProfile,
            onLogOut: () {},
          ),
        ),
      );

      final analyticsItem = find.text('Learning analytics privacy');
      expect(analyticsItem, findsOneWidget);
      await tester.ensureVisible(analyticsItem);
      await tester.tap(analyticsItem);
      await tester.pumpAndSettle();

      expect(find.text('Learning analytics'), findsOneWidget);
      expect(find.text('Share activity analytics'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(find.textContaining('On ·'), findsOneWidget);
    });

    testWidgets('tapping Reported Questions navigates to ReportedQuestionsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileSettingsScreen(
              profile: testProfile,
              onLogOut: () {},
            ),
          ),
        ),
      );

      final reportedItem = find.text('Reported Questions');
      expect(reportedItem, findsOneWidget);
      await tester.ensureVisible(reportedItem);
      await tester.tap(reportedItem);
      await tester.pumpAndSettle();

      expect(find.text('Reported Questions'), findsWidgets);
      expect(find.text('All Reports'), findsOneWidget);
      expect(find.text('In Review'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });
  });
}

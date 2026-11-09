import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/theme/app_theme.dart';
import 'package:prep404/core/widgets/prep_state_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('PrepFormValidator Unit Tests (State 9: Form Validation)', () {
    test('validatePhone correctly validates Bangladeshi numbers', () {
      expect(PrepFormValidator.validatePhone(null), isNotNull);
      expect(PrepFormValidator.validatePhone(''), isNotNull);
      expect(PrepFormValidator.validatePhone('12345'), isNotNull);
      expect(PrepFormValidator.validatePhone('01234567890'), isNotNull); // invalid operator 2
      expect(PrepFormValidator.validatePhone('01712345678'), isNull); // GP valid
      expect(PrepFormValidator.validatePhone('01912345678'), isNull); // Banglalink valid
      expect(PrepFormValidator.validatePhone('01812345678'), isNull); // Robi valid
      expect(PrepFormValidator.validatePhone('01312345678'), isNull); // GP valid
      expect(PrepFormValidator.validatePhone('01412345678'), isNull); // BL valid
      expect(PrepFormValidator.validatePhone('+8801712345678'), isNull); // International with prefix
      expect(PrepFormValidator.validatePhone('01712-345678'), isNull); // Whitespace / dash tolerance
    });

    test('validateFullName enforces length constraints', () {
      expect(PrepFormValidator.validateFullName(null), isNotNull);
      expect(PrepFormValidator.validateFullName(''), isNotNull);
      expect(PrepFormValidator.validateFullName('A'), isNotNull); // < 2
      expect(PrepFormValidator.validateFullName('Ab'), isNull);
      expect(PrepFormValidator.validateFullName('Hussain Ahmed'), isNull);
      expect(PrepFormValidator.validateFullName('A' * 65), isNotNull); // > 60
    });

    test('validateOtp checks length and numeric constraints', () {
      expect(PrepFormValidator.validateOtp(null), isNotNull);
      expect(PrepFormValidator.validateOtp(''), isNotNull);
      expect(PrepFormValidator.validateOtp('12'), isNotNull); // < 4
      expect(PrepFormValidator.validateOtp('1234'), isNull); // 4-digit valid
      expect(PrepFormValidator.validateOtp('123456'), isNull); // 6-digit valid
      expect(PrepFormValidator.validateOtp('12a456'), isNotNull); // non-numeric
      expect(PrepFormValidator.validateOtp('12345678'), isNotNull); // > 6
    });

    test('validateEmail checks standard email patterns', () {
      expect(PrepFormValidator.validateEmail(null), isNull); // Optional
      expect(PrepFormValidator.validateEmail(''), isNull);
      expect(PrepFormValidator.validateEmail('not-an-email'), isNotNull);
      expect(PrepFormValidator.validateEmail('candidate@prep404.com'), isNull);
    });

    test('validateRequired checks for non-empty values', () {
      expect(PrepFormValidator.validateRequired(null, 'Target College'), isNotNull);
      expect(PrepFormValidator.validateRequired('', 'Target College'), isNotNull);
      expect(PrepFormValidator.validateRequired('   ', 'Target College'), isNotNull);
      expect(PrepFormValidator.validateRequired('Notre Dame College', 'Target College'), isNull);
    });
  });

  group('PrepSuccessRate Tests (State 10: Success Rate)', () {
    test('PrepSuccessRateBadge calculates and categorizes rates safely', () {
      const zeroBadge = PrepSuccessRateBadge(correctCount: 0, totalCount: 0);
      expect(zeroBadge.rate, 0.0);
      expect(zeroBadge.getTierLabel(), 'Needs Practice');

      const highBadge = PrepSuccessRateBadge(correctCount: 8, totalCount: 10);
      expect(highBadge.rate, 80.0);
      expect(highBadge.getTierLabel(), 'High Mastery');

      const modBadge = PrepSuccessRateBadge(correctCount: 6, totalCount: 10);
      expect(modBadge.rate, 60.0);
      expect(modBadge.getTierLabel(), 'Moderate');
    });

    testWidgets('PrepSuccessRateCard renders cutoff indicators properly', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const PrepSuccessRateCard(
            correctCount: 20,
            wrongCount: 5,
            totalCount: 25,
            targetCutoffRate: 70.0,
          ),
        ),
      );

      expect(find.text('Success Rate (Accuracy)'), findsOneWidget);
      expect(find.text('20 correct / 25 attempted'), findsOneWidget);
      expect(find.textContaining('Above Cutoff'), findsOneWidget);
    });
  });

  group('States 1 to 8 Widget Rendering Tests', () {
    testWidgets('1. Empty State renders with action callback', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepEmptyStateView(
            title: 'No Question Scripts',
            actionLabel: 'Explore Drills',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Question Scripts'), findsOneWidget);
      expect(find.text('Explore Drills'), findsOneWidget);
      await tester.tap(find.text('Explore Drills'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('2. Loading State renders message', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const PrepLoadingStateView(message: 'Generating BUET Model Test...'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating BUET Model Test...'), findsOneWidget);
    });

    testWidgets('3. Error State renders retry button and invokes callback', (tester) async {
      bool retryTriggered = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepErrorStateView(
            title: 'Server Error 500',
            onRetry: () => retryTriggered = true,
          ),
        ),
      );

      expect(find.text('Server Error 500'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('4. No Internet State renders offline message', (tester) async {
      bool retry = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepNoInternetView(onRetry: () => retry = true),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retry, isTrue);
    });

    testWidgets('5. Slow Network State renders choices', (tester) async {
      bool keepWaiting = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepSlowNetworkView(
            onKeepWaiting: () => keepWaiting = true,
            onSwitchOffline: () {},
          ),
        ),
      );

      expect(find.text('Connection is Slow'), findsOneWidget);
      expect(find.text('Keep Waiting'), findsOneWidget);
      expect(find.text('Use Cached Data'), findsOneWidget);
      await tester.tap(find.text('Keep Waiting'));
      expect(keepWaiting, isTrue);
    });

    testWidgets('6. No Search Result State renders query and clear action', (tester) async {
      bool cleared = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepNoSearchResultsView(
            query: 'Quantum Gravitation',
            onClearSearch: () => cleared = true,
          ),
        ),
      );

      expect(find.text('No Results Found'), findsOneWidget);
      expect(find.textContaining('Quantum Gravitation'), findsOneWidget);
      await tester.tap(find.text('Clear Search Filter'));
      expect(cleared, isTrue);
    });

    testWidgets('7. Permission Denied State renders permission details', (tester) async {
      bool openedSettings = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepPermissionDeniedView(
            permissionName: 'Push Notifications',
            onOpenSettings: () => openedSettings = true,
          ),
        ),
      );

      expect(find.text('Push Notifications Permission Required'), findsOneWidget);
      await tester.tap(find.text('Open App Settings'));
      expect(openedSettings, isTrue);
    });

    testWidgets('8. Session Expired State renders reauth action', (tester) async {
      bool reauth = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PrepSessionExpiredView(onReauthenticate: () => reauth = true),
        ),
      );

      expect(find.text('Session Expired'), findsOneWidget);
      await tester.tap(find.text('Log In Again'));
      expect(reauth, isTrue);
    });
  });
}

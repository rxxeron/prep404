import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/auth/presentation/screens/auth_screen.dart';

void main() {
  group('Auth Flow Widget Tests', () {
    testWidgets('registration fields expose their labels to screen readers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AuthScreen(onAuthSuccess: (token, user) {}),
          ),
        );
        await tester.pumpAndSettle();

        for (final label in ['Full Name', 'Phone Number']) {
          final field = find.widgetWithText(TextFormField, label);
          expect(field, findsOneWidget);

          final data = tester.getSemantics(field).getSemanticsData();
          expect(data.flagsCollection.isTextField, isTrue);
          expect(data.label, contains(label));
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
        'OTP provider failure does not authenticate and guest preview works',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool authenticated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AuthScreen(
            onAuthSuccess: (token, user) {
              authenticated = true;
            },
          ),
        ),
      );

      await tester.pump();

      // Verify Auth screen elements in English
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Enter name and phone number
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      await tester.enterText(nameField, 'Test Candidate');
      await tester.pump();

      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      await tester.enterText(phoneField, '01712345678');
      await tester.pump();

      // Tap Send OTP
      final sendOtpBtn =
          find.widgetWithText(ElevatedButton, 'Send Verification OTP');
      await tester.ensureVisible(sendOtpBtn);
      await tester.tap(sendOtpBtn);
      await tester.pump();

      await tester.pumpAndSettle();

      // A missing Supabase provider must fail closed instead of showing a
      // verification step that cannot succeed.
      expect(find.text('Enter 4-Digit OTP'), findsNothing);
      expect(find.textContaining('Sign-in could not be completed'),
          findsOneWidget);
      expect(authenticated, isFalse);

      final guestPreview = find.text('Explore as Guest (Preview)');
      await tester.ensureVisible(guestPreview);
      await tester.tap(guestPreview);
      await tester.pump();
      expect(authenticated, isTrue);
    });
  });
}

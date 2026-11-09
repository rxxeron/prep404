import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/localization/app_strings.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:prep404/features/onboarding/presentation/widgets/medium_selector_step.dart';

void main() {
  group('MediumSelectorStep & Version Selection Tests', () {
    testWidgets('renders Bangla Medium by default with Bangla and English Version sub-options', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => MediumSelectorStep(
                controller: controller,
                language: AppLanguage.english,
              ),
            ),
          ),
        ),
      );

      // Verify header and medium cards
      expect(find.text('Select Your Academic Medium'), findsOneWidget);
      expect(find.text('Bangla Medium (NCTB)'), findsOneWidget);
      expect(find.text('English Medium'), findsOneWidget);

      // Verify Bangla Medium sub-options (Bangla Version vs English Version)
      expect(find.text('Select NCTB Version'), findsOneWidget);
      expect(find.text('Bangla Version'), findsOneWidget);
      expect(find.text('English Version'), findsOneWidget);
      expect(controller.nctbVersion, NctbVersion.bangla);

      // Switch to English Version
      await tester.tap(find.text('English Version'));
      await tester.pumpAndSettle();
      expect(controller.nctbVersion, NctbVersion.english);

      // Switch to English Medium
      await tester.tap(find.text('English Medium'));
      await tester.pumpAndSettle();

      expect(controller.medium, StudentMedium.english);
      expect(find.text('Curriculum Examination Board'), findsOneWidget);
      expect(find.text('Cambridge (CAIE)'), findsOneWidget);
      expect(find.text('Pearson Edexcel'), findsOneWidget);
    });

    testWidgets('renders English text when AppLanguage.english is selected', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = OnboardingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => MediumSelectorStep(
                controller: controller,
                language: AppLanguage.english,
              ),
            ),
          ),
        ),
      );

      // Verify English header and medium cards
      expect(find.text('Select Your Academic Medium'), findsOneWidget);
      expect(find.text('Questions and curricula will be customized based on your medium.'), findsOneWidget);
      expect(find.text('Bangla Medium (NCTB)'), findsOneWidget);
      expect(find.text('National Curriculum & Textbook Board (HSC)'), findsOneWidget);

      // Verify English NCTB version selection
      expect(find.text('Select NCTB Version'), findsOneWidget);
      expect(find.text('Bangla Version'), findsOneWidget);
      expect(find.text('English Version'), findsOneWidget);

      // Guidance card
      expect(find.text('Curriculum & Question Alignment'), findsOneWidget);
    });
  });
}

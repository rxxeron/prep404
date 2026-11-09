import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/screens/about_us_screen.dart';

void main() {
  group('AboutUsScreen Tests', () {
    testWidgets('renders Prep404 mission, core pillars, and version info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutUsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('About Us'), findsOneWidget);

      // Verify Brand Header
      expect(find.text('Prep404'), findsOneWidget);
      expect(find.text('Private University Admission Platform'), findsOneWidget);
      expect(find.text('Version 1.0.0 • 2026 Edition'), findsOneWidget);

      // Verify Mission and Pillars
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Core Innovations'), findsOneWidget);
      expect(find.text('Authentic Exam Blueprints'), findsOneWidget);
      expect(find.text('KaTeX STEM Solutions'), findsOneWidget);
      expect(find.text('FSRS-5 Spaced Repetition'), findsOneWidget);
      expect(find.text('100% Pure English Environment'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/screens/reported_questions_screen.dart';

void main() {
  group('ReportedQuestionsScreen Widget Tests', () {
    testWidgets('renders empty state when no question reports exist',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportedQuestionsScreen(userId: 'test_empty_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reported Questions'), findsOneWidget);
      expect(find.text('All Reports'), findsOneWidget);
      expect(find.text('In Review'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('No Reported Questions Yet'), findsOneWidget);
      expect(find.text('Explore Practice Arena'), findsOneWidget);
    });

    testWidgets('filter tabs toggle selection state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportedQuestionsScreen(userId: 'test_filter_user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "In Review" filter
      await tester.tap(find.text('In Review'));
      await tester.pumpAndSettle();

      // Tap "Resolved" filter
      await tester.tap(find.text('Resolved'));
      await tester.pumpAndSettle();

      // Tap "All Reports" filter
      await tester.tap(find.text('All Reports'));
      await tester.pumpAndSettle();
    });
  });
}

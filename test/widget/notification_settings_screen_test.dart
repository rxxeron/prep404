import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/dashboard/presentation/screens/notification_settings_screen.dart';

void main() {
  group('NotificationSettingsScreen Tests', () {
    testWidgets('renders all notification categories and toggle switches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Notifications'), findsOneWidget);

      // Verify Group Headers
      expect(find.text('Study Habits & Reminders'), findsOneWidget);
      expect(find.text('Admission & University Alerts'), findsOneWidget);
      expect(find.text('Content & Progress Insights'), findsOneWidget);

      // Verify Switches
      expect(find.text('Daily Practice Reminders'), findsOneWidget);
      expect(find.text('Streak Saver Alert'), findsOneWidget);
      expect(find.text('Circular & Deadline Alerts'), findsOneWidget);
      expect(find.text('Exam Reschedule Notices'), findsOneWidget);
      expect(find.text('New Exam Papers & Variants'), findsOneWidget);
      expect(find.text('Weekly Readiness Report'), findsOneWidget);

      // Toggle a switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(6));
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });
  });
}

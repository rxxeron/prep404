import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/features/analytics/presentation/screens/study_streak_detail_screen.dart';

void main() {
  testWidgets('StudyStreakDetailScreen renders streak metrics, timeline, and scoreboard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const StudyStreakDetailScreen(userId: 'test-user-id'),
      ),
    );

    // Initial load pump
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AppBar
    expect(find.text('Study Streak & Consistency'), findsOneWidget);

    // Verify Scoreboard Metrics
    expect(find.text('Streak Performance Metrics'), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Highest Streak'), findsOneWidget);
    expect(find.text('Lowest Streak'), findsOneWidget);
    expect(find.text('Total Active Days'), findsOneWidget);
    expect(find.text('Total Streak Cycles'), findsOneWidget);

    // Verify Weekly Activity Strip & Milestone Ladder
    expect(find.text("This Week's Study Activity"), findsOneWidget);
    expect(find.text('Streaked Timeline & History'), findsOneWidget);
    expect(find.text('Streak Milestone Ladder'), findsOneWidget);
    expect(find.text('Keep Streak Alive • Practice Now'), findsOneWidget);
  });
}

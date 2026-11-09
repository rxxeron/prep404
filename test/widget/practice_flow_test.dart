import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prep404/core/models/user_profile.dart';
import 'package:prep404/core/models/university_target.dart';
import 'package:prep404/core/services/api_client.dart';
import 'package:prep404/core/services/cache_service.dart';
import 'package:prep404/features/ai_tutor/services/ai_socratic_tutor.dart';
import 'package:prep404/features/practice/presentation/widgets/dynamic_practice_view.dart';
import 'package:prep404/main.dart';

void main() {
  group('Practice & Student UX Flow Tests', () {
    setUp(() {
      final sampleJson = jsonEncode([
        {
          'id': 'test_q_1',
          'stem_primary': 'If 2^(x+3) = 32, what is (x+1)^2?',
          'options': [
            {'key_original': 'A', 'text': '4', 'is_correct': false},
            {'key_original': 'B', 'text': '9', 'is_correct': true},
          ],
          'solution_markdown': 'x = 2, so (2+1)^2 = 9',
          'hints': ['Start by taking the logarithm base 2 of both sides.'],
        }
      ]);
      CacheService().write('questions_all_all_15', sampleJson);
      CacheService().write('questions_all_all_20', sampleJson);
      CacheService().write('questions_all_all_50', sampleJson);
    });

    testWidgets('DynamicPracticeView loads questions and displays FSRS rating bar upon answering', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final studyHints = SocraticStudyHintService();
      final practiceApi = ApiClient(httpClient: MockClient((request) async =>
          http.Response(jsonEncode({
            'correctOptionId': 'B',
            'explanation': 'x = 2, so (2+1)^2 = 9',
          }), 200, headers: {'content-type': 'application/json'})));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicPracticeView(studyHintService: studyHints, apiClient: practiceApi),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify question is loaded
      expect(find.textContaining('Question 1 of'), findsOneWidget);
      expect(find.text('Show Socratic hint'), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('All Topics'), findsOneWidget);
      expect(find.text('Bookmarked ★'), findsOneWidget);

      // Bookmark button exists
      expect(find.byTooltip('Bookmark Question'), findsOneWidget);

      // Select an option (tap option 'B')
      final optionB = find.text('B');
      expect(optionB, findsWidgets);
      await tester.tap(optionB.first);
      await tester.pump();

      // Verify FSRS rating bar appears
      expect(find.textContaining('Rate Difficulty (FSRS Memory Spaced Repetition)'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);

      // Tap FSRS rating 'Good'
      await tester.ensureVisible(find.text('Good'));
      await tester.tap(find.text('Good'));
      await tester.pump();
      expect(find.textContaining('FSRS: Review scheduled in'), findsOneWidget);

      // Wait for auto-advance timer to complete
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('Tapping streak icon displays student gamified streak modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testProfile = UserProfile(
        id: 'test_user',
        name: 'Rafiqul Islam',
        phone: '01700000000',
        medium: StudentMedium.bangla,
        academicBatch: "HSC '24",
        institutionName: 'Notre Dame College',
        studyStreakDays: 7,
        targetSelections: {
          'nsu': ['nsu_cse'],
          'brac': ['brac_cse'],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MainDashboardScreen(
            profile: testProfile,
            onResetProfile: () {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Question Setter Studio is gone (no admin elements)
      expect(find.byTooltip('Question Setter Studio'), findsNothing);

      // Verify streak icon exists and tap it
      final streakBtn = find.byTooltip('Streak: 7 Days');
      expect(streakBtn, findsOneWidget);
      await tester.tap(streakBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify gamified modal contents
      expect(find.text('7 Days Study Streak!'), findsOneWidget);
      expect(find.text('1.5x XP Boost Active'), findsOneWidget);
      expect(find.textContaining('1 Streak Freeze Protected'), findsOneWidget);
      expect(find.text('Keep Practicing'), findsOneWidget);

      // Tap Keep Practicing to close
      await tester.tap(find.text('Keep Practicing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('7 Days Study Streak!'), findsNothing);
    });

    testWidgets('DynamicPracticeView supports bookmarked questions and authored hints', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final studyHints = SocraticStudyHintService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicPracticeView(studyHintService: studyHints),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Bookmark filter chip is present
      expect(find.text('Bookmarked ★'), findsOneWidget);

      // Bookmark current question
      await tester.tap(find.byTooltip('Bookmark Question'));
      await tester.pump();

      // Switch to bookmarked filter
      await tester.tap(find.text('Bookmarked ★'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Bookmarked question is displayed
      expect(find.textContaining('Question 1 of'), findsOneWidget);

      // Tap the question-authored hint action
      await tester.tap(find.text('Show Socratic hint'));
      await tester.pump();
      expect(find.text('Socratic Study Hint'), findsOneWidget);
      expect(find.textContaining('AI-generated tutoring is not available'), findsOneWidget);

      // Let stream tokens arrive
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Start by taking the logarithm'), findsOneWidget);

      // Tap Got it button to dismiss modal
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();
      expect(find.text('Socratic Study Hint'), findsNothing);
    });
  });
}

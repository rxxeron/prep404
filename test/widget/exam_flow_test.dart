import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/question.dart';
import 'package:prep404/core/services/cache_service.dart';
import 'package:prep404/features/analytics/presentation/screens/exam_history_screen.dart';
import 'package:prep404/features/exam/presentation/screens/live_model_test_screen.dart';
import 'package:prep404/features/exam/presentation/screens/model_test_catalog_screen.dart';

void main() {
  group('Exam Runner & Catalog Widget Tests', () {
    const mockQuestions = [
      Question(
        id: 'q1',
        subjectId: 'sub_quant_math',
        topicId: 'top_algebra',
        text: r'If $2^{x+3} = 32$, what is $(x+1)^2$?',
        hasMath: true,
        options: [
          QuestionOption(id: 'A', text: '4'),
          QuestionOption(id: 'B', text: '9'),
          QuestionOption(id: 'C', text: '16'),
          QuestionOption(id: 'D', text: '25'),
        ],
        correctOptionId: 'B',
        explanation: 'x=2, (2+1)^2 = 9',
      ),
      Question(
        id: 'q2',
        subjectId: 'sub_english_priv',
        topicId: 'top_vocab',
        text: 'Select the synonym for "EPHEMERAL":',
        hasMath: false,
        options: [
          QuestionOption(id: 'A', text: 'Eternal'),
          QuestionOption(id: 'B', text: 'Transient'),
          QuestionOption(id: 'C', text: 'Perpetual'),
          QuestionOption(id: 'D', text: 'Resilient'),
        ],
        correctOptionId: 'B',
        explanation: 'Transient means lasting a short time.',
      ),
    ];

    testWidgets('ModelTestCatalogScreen renders filters and exams', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ModelTestCatalogScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Private University Model Tests'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('BRACU'), findsOneWidget);
      expect(find.text('NSU'), findsOneWidget);
      expect(find.text('IUB'), findsOneWidget);
    });

    testWidgets('LiveModelTestScreen displays dual mode and launches Software OMR Sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LiveModelTestScreen(
            slug: 'test-slug',
            title: 'BRACU CSE & Architecture Test',
            durationMinutes: 30,
            initialQuestions: mockQuestions,
            onExit: () {},
          ),
        ),
      );
      await tester.pump();

      // Mode Selection view
      expect(find.text('Select Exam Mode'), findsOneWidget);
      expect(find.text('In-App Digital Exam'), findsOneWidget);
      expect(find.text('OMR Bubble Sheet Simulation'), findsOneWidget);

      // Select OMR mode
      await tester.tap(find.text('OMR Bubble Sheet Simulation'));
      await tester.pumpAndSettle();

      // Should now be inside Software OMR Sheet
      expect(find.text('PREP404 • OMR ANSWER SHEET'), findsOneWidget);
      expect(find.text('Darkened: 0'), findsOneWidget);
      expect(find.text('Blank: 2'), findsOneWidget);

      // Tap bubble B on question 1 (find letter B widgets, tap the first one)
      final bWidgets = find.text('B');
      expect(bWidgets, findsWidgets);
      await tester.tap(bWidgets.first);
      await tester.pumpAndSettle();

      expect(find.text('Darkened: 1'), findsOneWidget);

      // Switch to continuous Questions list using the top bar view toggle
      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pumpAndSettle();

      // Verify question list is visible with 1 answered
      expect(find.text('QUESTION #1'), findsOneWidget);
      expect(find.text('Answered (1)'), findsOneWidget);

      // Switch back to OMR sheet
      await tester.tap(find.byIcon(Icons.radio_button_checked_rounded));
      await tester.pumpAndSettle();

      expect(find.text('PREP404 • OMR ANSWER SHEET'), findsOneWidget);
    });

    testWidgets('ExamHistoryScreen and ExamScriptReviewScreen render submission history cleanly', (tester) async {
      CacheService().saveExamScript({
        'id': 'sub_test_ewu_1',
        'examId': '289d89b2-0bed-579a-b14d-210707df4063',
        'examTitle': 'EWU Admission Test - Summer 2025 (FBS) - Section I: English',
        'date': '2026-11-03T18:48:02.857Z',
        'score': 3.75,
        'totalMarks': 40.0,
        'totalQuestions': 40,
        'correctCount': 4,
        'wrongCount': 1,
        'skippedCount': 35,
        'negativeMark': 0.25,
        'timeTakenSeconds': 98,
        'rank': 1,
        'totalCandidates': 1,
        'isPassed': false,
        'userAnswers': {'q1': 'B', 'q2': 'A'},
        'questions': mockQuestions.map((q) => q.toJson()).toList(),
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExamHistoryScreen(
              onPracticeMistakes: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to Exam Scripts Tab
      await tester.tap(find.text('Exam Scripts'));
      await tester.pumpAndSettle();

      expect(find.text('EWU Admission Test - Summer 2025 (FBS) - Section I: English'), findsOneWidget);
      expect(find.text('3.8 / 40'), findsOneWidget); // Score formatted as 3.8 / 40

      // Tap on the history card to open review
      await tester.tap(find.text('EWU Admission Test - Summer 2025 (FBS) - Section I: English'));
      await tester.pumpAndSettle();

      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Mistakes (1)'), findsOneWidget);
      expect(find.text('Correct (4)'), findsOneWidget);
    });
  });
}

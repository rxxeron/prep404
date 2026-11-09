import 'package:flutter_test/flutter_test.dart';
import 'package:prep404/core/models/question.dart';
import 'package:prep404/core/models/exam_models.dart';
import 'package:prep404/core/repositories/exam_repository.dart';

void main() {
  group('Exam & Question Models Tests', () {
    test('Question correctly parses options and math presence', () {
      const q = Question(
        id: 'q_test_1',
        subjectId: 'higher_math',
        topicId: 'calculus',
        text: r'Find $\frac{d}{dx}(\sin x)$',
        hasMath: true,
        options: [
          QuestionOption(id: 'A', text: r'$\cos x$', hasMath: true),
          QuestionOption(id: 'B', text: r'$-\cos x$', hasMath: true),
          QuestionOption(id: 'C', text: r'$\tan x$', hasMath: true),
          QuestionOption(id: 'D', text: r'$\sec^2 x$', hasMath: true),
        ],
        correctOptionId: 'A',
        explanation: r'The derivative of $\sin x$ with respect to $x$ is $\cos x$.',
      );

      expect(q.id, 'q_test_1');
      expect(q.hasMath, isTrue);
      expect(q.options.length, 4);
      expect(q.correctOptionId, 'A');

      final json = q.toJson();
      final restored = Question.fromJson(json);
      expect(restored.text, q.text);
      expect(restored.options[0].text, r'$\cos x$');
    });

    test('DailyExamDetails computes question count and total marks', () {
      const exam = DailyExamDetails(
        id: 'exam_24',
        slug: 'daily-nsu-test-24',
        title: 'Daily Model Test #24',
        track: 'Private University',
        durationMinutes: 30,
        totalMarks: 50.0,
        negativeMark: 0.25,
        questionCount: 1,
        shareableUrl: 'https://prep404.com/m/daily-nsu-test-24',
        questions: [
          Question(
            id: 'q1',
            subjectId: 'math',
            topicId: 'algebra',
            text: 'Solve for x: 2x = 10',
            options: [
              QuestionOption(id: 'A', text: '5'),
              QuestionOption(id: 'B', text: '10'),
            ],
            correctOptionId: 'A',
            explanation: 'Divide both sides by 2.',
          ),
        ],
      );

      expect(exam.questions.length, 1);
      expect(exam.negativeMark, 0.25);
      expect(exam.durationMinutes, 30);
      expect(exam.shareableUrl, 'https://prep404.com/m/daily-nsu-test-24');
    });

    test('Question.withShuffledOptions preserves correct answer mapping', () {
      const q = Question(
        id: 'q_passage_1',
        subjectId: 'english',
        topicId: 'reading_comprehension',
        text: 'What is the main topic of the passage?',
        passage: 'Humans have a fundamental need to belong...',
        options: [
          QuestionOption(id: 'A', text: 'Social psychology'),
          QuestionOption(id: 'B', text: 'Astrophysics'),
          QuestionOption(id: 'C', text: 'Marine biology'),
          QuestionOption(id: 'D', text: 'Geology'),
        ],
        correctOptionId: 'A',
        explanation: 'The passage explores social psychology.',
      );

      final shuffled = q.withShuffledOptions();
      expect(shuffled.id, q.id);
      expect(shuffled.passage, q.passage);
      expect(shuffled.options.length, 4);

      // Verify correct option ID points to the option with text 'Social psychology'
      final correctOpt = shuffled.options
          .firstWhere((opt) => opt.id == shuffled.correctOptionId);
      expect(correctOpt.text, 'Social psychology');
    });

    test('Question.withShuffledOptions protects relational options from shuffling', () {
      const q = Question(
        id: 'q_relational',
        subjectId: 'english',
        topicId: 'grammar',
        text: 'Which of the following are correct?',
        options: [
          QuestionOption(id: 'A', text: 'Sentence 1'),
          QuestionOption(id: 'B', text: 'Sentence 2'),
          QuestionOption(id: 'C', text: 'Both A and B'),
          QuestionOption(id: 'D', text: 'None of the above'),
        ],
        correctOptionId: 'C',
        explanation: 'Both 1 and 2 are grammatically sound.',
      );

      expect(q.hasRelationalOptions, isTrue);
      final notShuffled = q.withShuffledOptions();
      // Should remain identical in order
      expect(notShuffled.options[0].id, 'A');
      expect(notShuffled.options[2].text, 'Both A and B');
      expect(notShuffled.options[3].text, 'None of the above');
      expect(notShuffled.correctOptionId, 'C');
    });

    test('ExamRepository fetchLiveExams works', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final exams = await ExamRepository().fetchLiveExams();
      expect(exams, isNotNull);
    });

    test('Question.fromJson accurately parses camelCase and snake_case snapshot keys', () {
      final snapshotJson = {
        'id': '5f96bfde-8e01-4baf-a773-de2f6923bbad',
        'questionText': 'Which one is the correct electron configuration of C?',
        'options': [
          {'id': 'A', 'text': '1s^2 2s^2 2p^3'},
          {'id': 'B', 'text': '1s^2 2s^0 2p^4'},
          {'id': 'C', 'text': '1s^2 2s^2 2p^2'},
          {'id': 'D', 'text': '1s^2 2s^1 2p^3'},
        ],
        'correctOptionId': 'C',
        'explanation': 'Carbon has atomic number 6, giving the ground state configuration 1s^2 2s^2 2p^2.',
        'userAnswer': 'C',
      };

      final q = Question.fromJson(snapshotJson);
      expect(q.id, '5f96bfde-8e01-4baf-a773-de2f6923bbad');
      expect(q.text, 'Which one is the correct electron configuration of C?');
      expect(q.correctOptionId, 'C');
      expect(q.userAnswer, 'C');
      expect(q.explanation, contains('Carbon has atomic number 6'));
      expect(q.options[2].id, 'C');
      expect(q.options[2].text, '1s^2 2s^2 2p^2');

      final exported = q.toJson();
      expect(exported['correctOptionId'], 'C');
      expect(exported['userAnswer'], 'C');
      expect(exported['solution_markdown'], contains('Carbon has atomic number 6'));
    });
  });
}

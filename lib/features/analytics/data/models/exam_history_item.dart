import '../../../../core/models/question.dart';

class ExamHistoryItem {
  final String id;
  final String? examId;
  final String title;
  final String date;
  final double score;
  final double totalMarks;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final double negativeMark;
  final int skippedCount;
  final int timeTakenSeconds;
  final int rank;
  final int totalCandidates;
  final bool isPassed;
  final List<Question> questions;
  final Map<String, String> userAnswers;
  final String? universityCode;
  final bool? isPractice;
  final DateTime? submittedAt;

  bool get isPracticeMode => isPractice == true;

  const ExamHistoryItem({
    required this.id,
    this.examId,
    required this.title,
    required this.date,
    required this.score,
    required this.totalMarks,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.negativeMark,
    required this.skippedCount,
    required this.timeTakenSeconds,
    required this.rank,
    required this.totalCandidates,
    required this.isPassed,
    required this.questions,
    required this.userAnswers,
    this.universityCode,
    this.isPractice = false,
    this.submittedAt,
  });
}

class SubjectAggregate {
  final String name;
  int total = 0;
  int correct = 0;
  int wrong = 0;
  int skipped = 0;

  SubjectAggregate({required this.name});
}

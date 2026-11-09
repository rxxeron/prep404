import '../config/app_config.dart';
import 'question.dart';

/// Metadata & full question set for a live or daily model test
class DailyExamDetails {
  final String id;
  final String slug;
  final String title;
  final String track;
  final int durationMinutes;
  final double totalMarks;
  final double negativeMark;
  final int questionCount;
  final String shareableUrl;
  final List<Question> questions;

  const DailyExamDetails({
    required this.id,
    required this.slug,
    required this.title,
    required this.track,
    required this.durationMinutes,
    required this.totalMarks,
    required this.negativeMark,
    required this.questionCount,
    required this.shareableUrl,
    required this.questions,
  });

  factory DailyExamDetails.fromJson(Map<String, dynamic> json) {
    final rawList = (json['questions'] as List? ?? [])
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
        .toList();

    // Ensure MCQ & OMR exam runners only receive valid questions with at least 2 choices.
    // Filters out written descriptive / drawing prompts scraped from past papers that have 0 options.
    final mcqQuestions = rawList.where((q) => q.options.length >= 2).toList();
    final questionsList = mcqQuestions.isNotEmpty ? mcqQuestions : rawList;

    return DailyExamDetails(
      id: (json['id'] ?? json['examId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? 'Daily Model Test').toString(),
      track: (json['track'] ?? 'General').toString(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 50.0,
      negativeMark: (json['negativeMark'] as num?)?.toDouble() ?? 0.25,
      questionCount: questionsList.length,
      shareableUrl:
          (json['shareableUrl'] ?? '${AppConfig.webBaseUrl}/m/${json['slug']}')
              .toString(),
      questions: questionsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'track': track,
        'durationMinutes': durationMinutes,
        'totalMarks': totalMarks,
        'negativeMark': negativeMark,
        'questionCount': questionCount,
        'shareableUrl': shareableUrl,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

/// A server-created attempt with the question order and answer key fixed for submission.
class StartedExamSession {
  final String sessionId;
  final DailyExamDetails exam;

  const StartedExamSession({required this.sessionId, required this.exam});
}

/// Instant scoring and leaderboard ranking response from server
class ExamSubmissionResult {
  final String? submissionId;
  final String candidateName;
  final double score;
  final double totalMarks;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final int timeTakenSeconds;
  final int rank;
  final int totalParticipants;
  final String shareableResultText;
  final List<QuestionFeedback> feedback;
  final bool isPractice;
  final bool submissionPersisted;

  const ExamSubmissionResult({
    this.submissionId,
    required this.candidateName,
    required this.score,
    required this.totalMarks,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.timeTakenSeconds,
    required this.rank,
    required this.totalParticipants,
    required this.shareableResultText,
    required this.feedback,
    this.isPractice = false,
    this.submissionPersisted = false,
  });

  factory ExamSubmissionResult.fromJson(Map<String, dynamic> json) {
    final feedbackList = (json['feedback'] as List? ?? [])
        .map((f) => QuestionFeedback.fromJson(f as Map<String, dynamic>))
        .toList();

    return ExamSubmissionResult(
      submissionId: (json['submissionId'] ?? json['id'])?.toString(),
      candidateName: (json['candidateName'] ?? 'Candidate').toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 50.0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      unansweredCount: (json['unansweredCount'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ??
          (json['liveRank'] as num?)?.toInt() ??
          1,
      totalParticipants: (json['totalParticipants'] as num?)?.toInt() ?? 1,
      shareableResultText: (json['shareableResultText'] ?? '').toString(),
      feedback: feedbackList,
      isPractice: json['isPractice'] == true,
      submissionPersisted: json['submissionPersisted'] == true,
    );
  }
}

/// Detailed per-question feedback with explanation & hints
class QuestionFeedback {
  final String questionId;
  final String? selectedOption;
  final String correctOption;
  final bool isCorrect;
  final String explanation;
  final List<String> hints;

  const QuestionFeedback({
    required this.questionId,
    this.selectedOption,
    required this.correctOption,
    required this.isCorrect,
    required this.explanation,
    required this.hints,
  });

  factory QuestionFeedback.fromJson(Map<String, dynamic> json) {
    return QuestionFeedback(
      questionId: (json['questionId'] ?? '').toString(),
      selectedOption:
          (json['selectedOption'] ?? json['studentAnswer']) as String?,
      correctOption:
          (json['correctOption'] ?? json['correctAnswer'] ?? '').toString(),
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation:
          (json['explanation'] ?? json['solutionMarkdown'] ?? '').toString(),
      hints: (json['hints'] as List? ?? []).map((h) => h.toString()).toList(),
    );
  }
}

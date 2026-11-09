import 'dart:async';
import 'package:prep404/core/models/question.dart';

enum TutorStep { hint1, hint2, fullExplanation }

class SocraticHint {
  final TutorStep step;
  final String title;
  final String content;

  const SocraticHint({
    required this.step,
    required this.title,
    required this.content,
  });
}

/// Socratic study guidance based on hints authored with each question.
/// This prototype does not generate AI responses.
class SocraticStudyHintService {
  SocraticStudyHintService();

  /// Streams progressive Socratic hints for a given question.
  Stream<String> streamAuthoredHint({
    required Question question,
    required String studentChosenOptionId,
    TutorStep step = TutorStep.hint1,
  }) async* {
    // This prototype streams the hint authored with the question; it does not
    // call a language model or invent a generic answer unrelated to the item.
    if (question.hints.isEmpty || question.hints.first.trim().isEmpty) return;
    final hint = question.hints.first.trim();
    for (var start = 0; start < hint.length; start += 24) {
      await Future.delayed(const Duration(milliseconds: 60));
      final end = start + 24 < hint.length ? start + 24 : hint.length;
      yield hint.substring(start, end);
    }
  }

  /// Evaluates student attempt and returns next Socratic action
  SocraticHint getNextHint(Question question, int currentHintLevel) {
    if (question.hints.isNotEmpty && currentHintLevel < question.hints.length) {
      return SocraticHint(
        step: currentHintLevel == 0 ? TutorStep.hint1 : TutorStep.hint2,
        title: 'Hint ${currentHintLevel + 1}',
        content: question.hints[currentHintLevel],
      );
    }

    return SocraticHint(
      step: TutorStep.fullExplanation,
      title: 'Complete Solution',
      content: question.explanation,
    );
  }
}

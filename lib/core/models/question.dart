import 'dart:math';

class QuestionOption {
  final String id;
  final String text;
  final bool hasMath;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.text,
    this.hasMath = false,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: (json['key_original'] ?? json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      hasMath: json['has_math'] as bool? ?? json['hasMath'] as bool? ?? false,
      isCorrect: json['is_correct'] == true ||
          json['isCorrect'] == true ||
          json['is_correct'] == 'true',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'key_original': id,
    'text': text,
    'has_math': hasMath,
    'hasMath': hasMath,
    'is_correct': isCorrect,
    'isCorrect': isCorrect,
  };
}

class Question {
  final String id;
  final String subjectId;
  final String topicId;
  final String text;
  final String? passage;
  final String? contextSnippet;
  final bool hasMath;
  final List<QuestionOption> options;
  final String correctOptionId;
  final String explanation;
  final List<String> hints;
  final double marks;
  final double negativeMarks;
  final String? userAnswer;

  const Question({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.text,
    this.passage,
    this.contextSnippet,
    this.hasMath = false,
    required this.options,
    required this.correctOptionId,
    required this.explanation,
    this.hints = const [],
    this.marks = 1.0,
    this.negativeMarks = 0.5,
    this.userAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List? ?? []);
    final optionsList = rawOptions
        .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
        .toList();

    String detectedCorrect = (json['correct_option_id'] ??
            json['correctOptionId'] ??
            json['correct_option'] ??
            json['correctOption'] ??
            json['correctAnswer'] ??
            json['correct_answer'] ??
            '')
        .toString();
    if (detectedCorrect.isEmpty) {
      for (final opt in rawOptions) {
        if (opt is Map &&
            (opt['is_correct'] == true ||
                opt['isCorrect'] == true ||
                opt['is_correct'] == 'true')) {
          detectedCorrect =
              (opt['key_original'] ?? opt['id'] ?? '').toString();
          break;
        }
      }
    }

    final rawText = (json['stem_primary'] ??
            json['text'] ??
            json['question_text'] ??
            json['questionText'] ??
            '')
        .toString();
    final hasMathDetected = json['has_math'] as bool? ??
        json['hasMath'] as bool? ??
        (rawText.contains(r'$') || rawText.contains(r'\'));

    final rawPassage = (json['passage'] ??
            json['passageText'] ??
            json['stimulus_text'] ??
            json['content_text'] ??
            (json['stimulus'] is Map ? json['stimulus']['content_text'] : null))
        ?.toString()
        .trim();
    final rawSnippet =
        (json['context_snippet'] ?? json['contextSnippet'])?.toString().trim();

    return Question(
      id: (json['id'] ?? json['question_id'] ?? '').toString(),
      subjectId: (json['subject'] ??
              json['subject_name'] ??
              json['subjectName'] ??
              json['subject_id'] ??
              json['subjectId'] ??
              'General')
          .toString(),
      topicId: (json['topic_id'] ?? json['topicId'] ?? 'general').toString(),
      text: rawText,
      passage: (rawPassage != null && rawPassage.isNotEmpty) ? rawPassage : null,
      contextSnippet: (rawSnippet != null && rawSnippet.isNotEmpty) ? rawSnippet : null,
      hasMath: hasMathDetected,
      options: optionsList,
      correctOptionId: detectedCorrect,
      explanation: (json['solution_markdown'] ??
              json['explanation'] ??
              json['solutionMarkdown'] ??
              '')
          .toString(),
      hints: (json['hints'] as List? ?? json['socraticHints'] as List? ?? [])
          .map((h) => h.toString())
          .toList(),
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      negativeMarks: (json['negative_marks'] ?? json['negativeMark'] as num?)?.toDouble() ?? 0.25,
      userAnswer: (json['userAnswer'] ??
              json['user_answer'] ??
              json['selectedOption'] ??
              json['selected_option'])
          ?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_id': subjectId,
    'topic_id': topicId,
    'text': text,
    'questionText': text,
    'passage': passage,
    'context_snippet': contextSnippet,
    'contextSnippet': contextSnippet,
    'has_math': hasMath,
    'hasMath': hasMath,
    'options': options.map((o) => o.toJson()).toList(),
    'correct_option_id': effectiveCorrectOptionId,
    'correctOptionId': effectiveCorrectOptionId,
    'correctOption': effectiveCorrectOptionId,
    'explanation': explanation,
    'solution_markdown': explanation,
    'hints': hints,
    'marks': marks,
    'negative_marks': negativeMarks,
    'userAnswer': userAnswer,
    'user_answer': userAnswer,
  };

  /// Guaranteed correct option ID resolving fallback across options isCorrect flag
  String get effectiveCorrectOptionId {
    if (correctOptionId.trim().isNotEmpty) return correctOptionId.trim();
    for (final opt in options) {
      if (opt.isCorrect && opt.id.isNotEmpty) return opt.id;
    }
    return '';
  }

  static final _relationalPattern = RegExp(
    r'\b(all|none)\s+of\s+the\s+(above|below|mentioned)|above\s+all|none\s+of\s+these|all\s+of\s+these|\bboth\s+(\([a-d]\)|[a-d])\s+and\s+(\([a-d]\)|[a-d])\b|\bboth\s+(a\s+and\s+b|b\s+and\s+c|a\s+and\s+c)\b',
    caseSensitive: false,
  );

  /// Check whether choices contain position-dependent text (e.g. "All of the above", "Both A and B")
  bool get hasRelationalOptions =>
      options.any((opt) => _relationalPattern.hasMatch(opt.text));

  /// Return a copy of this Question with choices randomized while preserving
  /// the correct answer evaluation. Protects passage questions and relational
  /// choices from invalid scramble.
  Question withShuffledOptions({Random? random}) {
    if (options.length < 2 || hasRelationalOptions) {
      return this;
    }
    final shuffled = List<QuestionOption>.from(options)..shuffle(random);
    String newCorrectId = correctOptionId;
    final newOptions = <QuestionOption>[];

    for (int i = 0; i < shuffled.length; i++) {
      final oldOpt = shuffled[i];
      final newLetter = String.fromCharCode(65 + i); // 'A', 'B', 'C', 'D'
      if (oldOpt.id == correctOptionId) {
        newCorrectId = newLetter;
      }
      newOptions.add(QuestionOption(
        id: newLetter,
        text: oldOpt.text,
        hasMath: oldOpt.hasMath,
      ));
    }

    return Question(
      id: id,
      subjectId: subjectId,
      topicId: topicId,
      text: text,
      passage: passage,
      contextSnippet: contextSnippet,
      hasMath: hasMath,
      options: newOptions,
      correctOptionId: newCorrectId,
      explanation: explanation,
      hints: hints,
      marks: marks,
      negativeMarks: negativeMarks,
    );
  }

  Question copyWith({
    String? correctOptionId,
    String? explanation,
    List<QuestionOption>? options,
    String? userAnswer,
  }) =>
      Question(
        id: id,
        subjectId: subjectId,
        topicId: topicId,
        text: text,
        passage: passage,
        contextSnippet: contextSnippet,
        hasMath: hasMath,
        options: options ?? this.options,
        correctOptionId: correctOptionId ?? this.correctOptionId,
        explanation: explanation ?? this.explanation,
        hints: hints,
        marks: marks,
        negativeMarks: negativeMarks,
        userAnswer: userAnswer ?? this.userAnswer,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../core/models/question.dart';
import '../../../../core/theme/app_theme.dart';
import 'question_report_button.dart';

/// Renders complex math & science examination questions with native KaTeX.
class KaTeXQuestionView extends StatelessWidget {
  final Question question;
  final int? questionNumber;
  final String? selectedOptionId;
  final ValueChanged<String>? onOptionSelected;
  final bool showExplanation;
  final bool isOmrMode;
  final Map<String, int>? peerOptionDistribution;

  const KaTeXQuestionView({
    super.key,
    required this.question,
    this.questionNumber,
    this.selectedOptionId,
    this.onOptionSelected,
    this.showExplanation = false,
    this.isOmrMode = false,
    this.peerOptionDistribution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header with number badge and marks
            if (questionNumber != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOmrMode
                          ? colors.accentAmber.withValues(alpha: 0.15)
                          : colors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOmrMode ? colors.accentAmber : colors.primary,
                      ),
                    ),
                    child: Text(
                      'QUESTION #$questionNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        color: isOmrMode ? colors.accentAmber : colors.primary,
                      ),
                    ),
                  ),
                  if (isOmrMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bubble_chart, size: 12, color: colors.accentAmber),
                          const SizedBox(width: 4),
                          Text(
                            'OMR Bubble Mode',
                            style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Reading Passage / Stimulus Context
            if (question.passage != null && question.passage!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 17, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'READING PASSAGE / COMPREHENSION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      question.passage!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Cloze Blank Context Snippet (if distinct from passage)
            if (question.contextSnippet != null &&
                question.contextSnippet!.isNotEmpty &&
                (question.passage == null ||
                    !question.passage!.contains(question.contextSnippet!))) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.contextSnippet!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Question Prompt (Mixed Markdown + Math)
            _MathTextSpan(
              text: question.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            const SizedBox(height: 20),

            // Notice for non-MCQ written/drawing prompts
            if (question.options.isEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 22, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Descriptive / Written Task • Answered on physical script in actual varsity admission test',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Options List
            ...question.options.map((option) {
              final effectiveSelectedId = selectedOptionId ?? question.userAnswer;
              final isSelected = effectiveSelectedId != null &&
                  effectiveSelectedId.isNotEmpty &&
                  (effectiveSelectedId == option.id ||
                      effectiveSelectedId.toUpperCase() == option.id.toUpperCase());
              final effectiveCorrect = question.effectiveCorrectOptionId;
              final isCorrect = showExplanation &&
                  ((effectiveCorrect.isNotEmpty &&
                          (option.id == effectiveCorrect ||
                              option.id.toUpperCase() ==
                                  effectiveCorrect.toUpperCase())) ||
                      option.isCorrect);
              final isWrong = showExplanation && isSelected && !isCorrect;
              final peerPct = peerOptionDistribution?[option.id];

              Color borderColor = colors.border;
              Color bgColor = colors.surfaceElevated;
              Color textColor = colors.textPrimary;

              if (isCorrect) {
                borderColor = colors.accentEmerald;
                bgColor = colors.accentEmerald.withValues(alpha: context.isDark ? 0.2 : 0.12);
                textColor = context.isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46);
              } else if (isWrong) {
                borderColor = colors.dangerRed;
                bgColor = colors.dangerRed.withValues(alpha: context.isDark ? 0.2 : 0.12);
                textColor = context.isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
              } else if (isSelected) {
                if (isOmrMode) {
                  borderColor = colors.accentAmber;
                  bgColor = colors.accentAmber.withValues(alpha: context.isDark ? 0.25 : 0.15);
                  textColor = colors.textPrimary;
                } else {
                  borderColor = colors.primary;
                  bgColor = colors.primaryLight;
                  textColor = colors.primary;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: !showExplanation && onOptionSelected != null
                      ? () {
                          HapticFeedback.lightImpact();
                          onOptionSelected!(option.id);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(
                        color: borderColor,
                        width: isSelected || isCorrect || isWrong ? 2.0 : 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Option Badge (Digital badge vs authentic OMR bubble circle)
                        Container(
                          width: isOmrMode ? 32 : 28,
                          height: isOmrMode ? 32 : 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOmrMode
                                  ? (isSelected
                                      ? colors.accentAmber
                                      : colors.border)
                                  : borderColor,
                              width: isOmrMode ? 2.0 : 1.2,
                            ),
                            color: isCorrect
                                ? colors.accentEmerald
                                : (isWrong
                                    ? colors.dangerRed
                                    : (isSelected
                                        ? (isOmrMode
                                            ? colors.accentAmber
                                            : colors.primary)
                                        : Colors.transparent)),
                            boxShadow: isOmrMode && isSelected
                                ? [
                                    BoxShadow(
                                      color: colors.accentAmber.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isOmrMode && isSelected
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.accentAmber,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    option.id,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  option.id,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: (isSelected || isCorrect || isWrong)
                                        ? Colors.white
                                        : colors.textSecondary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MathTextSpan(
                            text: option.text,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        // Peer Option Statistics Pill (Scorecard Review)
                        if (peerPct != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? colors.accentEmerald.withValues(alpha: 0.15)
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$peerPct% peers',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? colors.accentEmerald : colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            // Premium Inline Solution & AI Explanation Section
            if (showExplanation) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'AI Explanation & Solution',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            question.options.isNotEmpty
                                ? (question.effectiveCorrectOptionId.isNotEmpty
                                    ? 'Correct Answer: (${question.effectiveCorrectOptionId})'
                                    : 'Verified Solution')
                                : 'Evaluation Rubric',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _MathTextSpan(
                      text: question.explanation.isNotEmpty
                          ? question.explanation
                          : (question.hasMath
                              ? 'Step-by-step mathematical solution is being generated for this question.'
                              : 'Detailed solution and model answer are being curated for this question.'),
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
            QuestionReportButton(questionId: question.id),
          ],
        ),
      ),
    );
  }
}

typedef _MathTextSpan = MathTextSpan;

/// Helper that formats newlines, math symbols, and splits `$math$` segments for native KaTeX rendering.
class MathTextSpan extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final double? height;

  const MathTextSpan({
    super.key,
    required this.text,
    this.fontSize = 15,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.height = 1.45,
  });

  String _cleanSymbols(String raw) {
    return raw
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        .replaceAll(r'\implies', ' ⟹ ')
        .replaceAll(r'\iff', ' ⟺ ')
        .replaceAll(r'\rightarrow', ' → ')
        .replaceAll(r'\to', ' → ')
        .replaceAll(r'\leftarrow', ' ← ')
        .replaceAll(r'\pm', ' ± ')
        .replaceAll(r'\times', ' × ')
        .replaceAll(r'\div', ' ÷ ')
        .replaceAll(r'\neq', ' ≠ ')
        .replaceAll(r'\leq', ' ≤ ')
        .replaceAll(r'\geq', ' ≥ ')
        .replaceAll(r'\approx', ' ≈ ')
        .replaceAll(r'\infty', ' ∞ ')
        .replaceAll(r'\degree', '°');
  }

  @override
  Widget build(BuildContext context) {
    final sanitized = _cleanSymbols(text);
    final lines = sanitized.split('\n');

    if (lines.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines.map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 6);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildLine(line),
          );
        }).toList(),
      );
    }

    return _buildLine(sanitized);
  }

  Widget _buildLine(String line) {
    final parts = line.split(r'$');
    if (parts.length <= 1) {
      return Text(
        line,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(parts.length, (i) {
        final part = parts[i];
        if (part.isEmpty) return const SizedBox.shrink();
        final isMath = i % 2 == 1;

        if (isMath) {
          return Math.tex(
            part,
            textStyle: TextStyle(fontSize: fontSize, color: color),
            mathStyle: MathStyle.text,
            onErrorFallback: (_) => Text(
              part,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                height: height,
              ),
            ),
          );
        } else {
          return Text(
            part,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
            ),
          );
        }
      }),
    );
  }
}

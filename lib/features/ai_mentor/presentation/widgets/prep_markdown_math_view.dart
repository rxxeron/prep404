import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../core/theme/app_theme.dart';

/// Renders Markdown (headings, bold, italic, bullets, dividers) + LaTeX math
/// (`$$...$$`, `\[...\]`, `$...$`, `\(...\)`) cleanly for Prep404 Bhaiya chat bubbles.
/// Safe during live token streaming (gracefully handles unclosed delimiters).
class PrepMarkdownMathView extends StatelessWidget {
  final String data;
  final TextStyle baseStyle;
  final bool isUserBubble;

  const PrepMarkdownMathView({
    super.key,
    required this.data,
    required this.baseStyle,
    this.isUserBubble = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final blocks = _splitBlocks(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.type == _BlockType.divider) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: isUserBubble
                  ? Colors.white.withValues(alpha: 0.25)
                  : colors.border,
            ),
          );
        }

        if (block.type == _BlockType.displayMath) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isUserBubble
                  ? Colors.white.withValues(alpha: 0.14)
                  : colors.background,
              borderRadius: BorderRadius.circular(10),
              border: isUserBubble ? null : Border.all(color: colors.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                block.text,
                mathStyle: MathStyle.display,
                textStyle: baseStyle.copyWith(fontSize: (baseStyle.fontSize ?? 14) + 1),
                onErrorFallback: (_) => Text(block.text, style: baseStyle),
              ),
            ),
          );
        }

        if (block.type == _BlockType.heading) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: _buildRichLine(
              block.text,
              baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 14) + 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        if (block.type == _BlockType.bullet) {
          return Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUserBubble ? Colors.white : colors.primary,
                  ),
                ),
                Expanded(child: _buildRichLine(block.text, baseStyle)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _buildRichLine(block.text, baseStyle),
        );
      }).toList(),
    );
  }

  List<_MdBlock> _splitBlocks(String input) {
    final result = <_MdBlock>[];
    // First split out display math blocks $$...$$ or \[...\]
    final displayPattern = RegExp(r'\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]');
    int cursor = 0;

    void addTextChunk(String chunk) {
      for (final rawLine in chunk.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(line)) {
          result.add(const _MdBlock(_BlockType.divider, ''));
        } else if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
          result.add(_MdBlock(_BlockType.heading, line.replaceFirst(RegExp(r'^#{1,3}\s+'), '')));
        } else if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
          result.add(_MdBlock(_BlockType.bullet, line.substring(2).trim()));
        } else {
          result.add(_MdBlock(_BlockType.paragraph, line));
        }
      }
    }

    for (final m in displayPattern.allMatches(input)) {
      if (m.start > cursor) {
        addTextChunk(input.substring(cursor, m.start));
      }
      final tex = (m.group(1) ?? m.group(2) ?? '').trim();
      if (tex.isNotEmpty) {
        result.add(_MdBlock(_BlockType.displayMath, tex));
      }
      cursor = m.end;
    }

    if (cursor < input.length) {
      addTextChunk(input.substring(cursor));
    }
    return result;
  }

  Widget _buildRichLine(String line, TextStyle style) {
    final spans = <InlineSpan>[];
    // Matches: inline math $...$ or \(...\), bold **...**, italic *...*, inline code `...`
    final tokenPattern = RegExp(
      r'\$([^$\n]+?)\$|\\\((.+?)\\\)|\*\*(.+?)\*\*|\*([^*\n]+?)\*|`([^`\n]+?)`',
    );

    int cursor = 0;
    for (final m in tokenPattern.allMatches(line)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, m.start), style: style));
      }

      final inlineTex = m.group(1) ?? m.group(2);
      final boldText = m.group(3);
      final italicText = m.group(4);
      final codeText = m.group(5);

      if (inlineTex != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Math.tex(
                inlineTex.trim(),
                mathStyle: MathStyle.text,
                textStyle: style,
                onErrorFallback: (_) => Text(inlineTex, style: style),
              ),
            ),
          ),
        );
      } else if (boldText != null) {
        // Handle inline math nested inside **bold** (e.g. **Weight ($mg$):**)
        spans.addAll(_parseInnerMath(
          boldText,
          style.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (italicText != null) {
        spans.addAll(_parseInnerMath(
          italicText,
          style.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (codeText != null) {
        spans.add(
          TextSpan(
            text: codeText,
            style: style.copyWith(fontFamily: 'monospace'),
          ),
        );
      }
      cursor = m.end;
    }

    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: style));
    }

    return Text.rich(TextSpan(children: spans));
  }

  List<InlineSpan> _parseInnerMath(String text, TextStyle style) {
    final innerSpans = <InlineSpan>[];
    final mathPattern = RegExp(r'\$([^$\n]+?)\$|\\\((.+?)\\\)');
    int pos = 0;
    for (final m in mathPattern.allMatches(text)) {
      if (m.start > pos) {
        innerSpans.add(TextSpan(text: text.substring(pos, m.start), style: style));
      }
      final tex = (m.group(1) ?? m.group(2) ?? '').trim();
      innerSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Math.tex(
              tex,
              mathStyle: MathStyle.text,
              textStyle: style,
              onErrorFallback: (_) => Text(tex, style: style),
            ),
          ),
        ),
      );
      pos = m.end;
    }
    if (pos < text.length) {
      innerSpans.add(TextSpan(text: text.substring(pos), style: style));
    }
    return innerSpans;
  }
}

enum _BlockType { heading, bullet, paragraph, displayMath, divider }

class _MdBlock {
  final _BlockType type;
  final String text;
  const _MdBlock(this.type, this.text);
}

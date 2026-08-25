import 'package:flutter/material.dart';
import 'package:flutter_twemoji/flutter_twemoji.dart';
import '../utils/colors.dart';

/// Renders AI text with `**bold**` and Twemoji images.
///
/// System color emoji render as `[?]` on some iOS simulators (Apple CoreText),
/// so emojis are drawn as Twemoji assets instead.
class AiRichText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? boldStyle;

  const AiRichText(
    this.text, {
    super.key,
    this.style,
    this.boldStyle,
  });

  static List<InlineSpan> parseSpans(
    String text, {
    required TextStyle base,
    required TextStyle bold,
  }) {
    if (text.isEmpty) return [TextSpan(text: '', style: base)];

    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TwemojiTextSpan(
            text: text.substring(start, match.start),
            style: base,
            emojiFontMultiplier: 1.15,
          ),
        );
      }
      spans.add(
        TwemojiTextSpan(
          text: match.group(1)!,
          style: bold,
          emojiFontMultiplier: 1.15,
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(
        TwemojiTextSpan(
          text: text.substring(start),
          style: base,
          emojiFontMultiplier: 1.15,
        ),
      );
    }
    if (spans.isEmpty) {
      spans.add(TwemojiTextSpan(text: text, style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        );
    final bold = boldStyle ??
        base.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        );

    return Text.rich(
      TextSpan(children: parseSpans(text, base: base, bold: bold)),
    );
  }
}

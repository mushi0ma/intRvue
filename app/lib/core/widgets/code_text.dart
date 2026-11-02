import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Мәтіндегі код атауларын (StatelessWidget, setState(), build()) Medeo
/// Mono-мен береді — Figma D9/D11 сияқты. Қалған мәтін [style] стилінде.
class CodeText extends StatelessWidget {
  const CodeText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  /// `name()` шақыруы немесе екі және одан көп бас әріпті CamelCase атау.
  static final _code = RegExp(
    r'\b[A-Za-z_]\w*\(\)|\b[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]*)+\b',
  );

  static List<InlineSpan> spans(String text, TextStyle base) {
    final mono = AppTypography.code(base.color ?? Colors.black)
        .copyWith(fontSize: (base.fontSize ?? 14) - 1, height: base.height);
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _code.allMatches(text)) {
      if (m.start > at) out.add(TextSpan(text: text.substring(at, m.start)));
      out.add(TextSpan(text: m.group(0), style: mono));
      at = m.end;
    }
    if (at < text.length) out.add(TextSpan(text: text.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(TextSpan(style: base, children: spans(text, base)));
  }
}

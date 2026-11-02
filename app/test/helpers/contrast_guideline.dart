import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG мәтін контрасты, бірақ экран нақты телефон тығыздығында
/// ([pixelRatio], әдепкі 3×) суретке түсіріледі.
///
/// Flutter-дің `textContrastGuideline` экранды әрқашан 1×-ке кішірейтеді:
/// 12 px жіңішке шрифтте (Medeo Regular) штрихтың барлық пикселі
/// тегістелген (жартылай түсті) болып шығады да, «ең жиі қараңғы түс» ретінде
/// мәтін түсі емес, аралас түс алынады. Мұнда алгоритм сол (түйінді
/// семантика бойынша табу, жарық/қараңғы түстердің модасы), тек сурет
/// физикалық пиксельде.
class HiDpiTextContrastGuideline extends AccessibilityGuideline {
  const HiDpiTextContrastGuideline({this.pixelRatio = 3});

  final double pixelRatio;

  @override
  String get description =>
      'Text contrast ≥ 4.5:1 (3:1 large) at ${pixelRatio}x';

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    var result = const Evaluation.pass();
    for (final view in tester.binding.renderViews) {
      final layer = view.debugLayer! as OffsetLayer;
      final root = view.owner!.semanticsOwner!.rootSemanticsNode!;
      late final int width, height;
      final data = await tester.binding.runAsync<ByteData?>(() async {
        final scale = pixelRatio / view.flutterView.devicePixelRatio;
        final image = await layer.toImage(view.paintBounds, pixelRatio: scale);
        width = image.width;
        height = image.height;
        final bytes = await image.toByteData();
        image.dispose();
        return bytes;
      });
      final checked = <Element>{};
      void visit(SemanticsNode node) {
        if (node.isInvisible ||
            node.isMergedIntoParent ||
            node.flagsCollection.isHidden ||
            node.flagsCollection.isEnabled == ui.Tristate.isFalse) {
          return;
        }
        node.visitChildren((c) {
          visit(c);
          return true;
        });
        final d = node.getSemanticsData();
        final text = d.label.isEmpty ? d.value : d.label;
        if (text.trim().isEmpty) return;
        for (final e in find.text(text).hitTestable().evaluate()) {
          if (!checked.add(e)) continue;
          result += _check(e, data!, width, height);
        }
      }

      visit(root);
    }
    return result;
  }

  Evaluation _check(Element element, ByteData data, int width, int height) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) return const Evaluation.pass();
    final widget = element.widget;
    final TextStyle style;
    if (widget is Text) {
      style = DefaultTextStyle.of(element).style.merge(widget.style);
    } else if (widget is EditableText) {
      style = widget.style;
    } else if (widget is RichText) {
      style = widget.text.style ?? const TextStyle();
    } else {
      return const Evaluation.pass();
    }
    final size = style.fontSize ?? 14;
    final bold = (style.fontWeight?.value ?? 400) >= 700;
    final large = size >= 18 || (bold && size >= 14);
    final target = large ? 3.0 : 4.5;

    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      box.paintBounds.inflate(2),
    );
    final px = Rect.fromLTRB(
      rect.left * pixelRatio,
      rect.top * pixelRatio,
      rect.right * pixelRatio,
      rect.bottom * pixelRatio,
    ).intersect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    if (px.width <= 0 || px.height <= 0) return const Evaluation.pass();

    final counts = <int, int>{};
    for (var y = px.top.floor(); y < px.bottom.ceil(); y++) {
      for (var x = px.left.floor(); x < px.right.ceil(); x++) {
        final rgba = data.getUint32((y * width + x) * 4);
        counts.update(rgba, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    final colors = counts.map(
      (rgba, c) => MapEntry(Color((rgba << 24) | (rgba >> 8) & 0xFFFFFFFF), c),
    );
    var avg = 0.0, total = 0;
    colors.forEach((c, n) {
      avg += HSLColor.fromColor(c).lightness * n;
      total += n;
    });
    avg /= total;
    MapEntry<Color, int>? light, dark;
    for (final e in colors.entries) {
      if (HSLColor.fromColor(e.key).lightness <= avg) {
        if (e.value > (dark?.value ?? 0)) dark = e;
      } else if (e.value > (light?.value ?? 0)) {
        light = e;
      }
    }
    final a = (light ?? dark)!.key, b = (dark ?? light)!.key;
    final ratio = _ratio(a, b);
    if (ratio + 0.01 >= target) return const Evaluation.pass();
    final text = widget is Text
        ? (widget.data ?? widget.textSpan?.toPlainText() ?? '')
        : widget is RichText
        ? widget.text.toPlainText()
        : (widget as EditableText).controller.text;
    return Evaluation.fail(
      '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}" at $rect: '
      '${ratio.toStringAsFixed(2)} < $target '
      '(${_hex(b)} on ${_hex(a)}, ${size}px)\n',
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static double _ratio(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }
}

const hiDpiTextContrastGuideline = HiDpiTextContrastGuideline();

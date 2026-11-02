import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'review_mark.dart';

/// Рубрика ұяшығының жолағы: 0–2 төмен, 3 орта, 4–5 жоғары.
enum ScoreBand { low, mid, high, pending, skipped }

ScoreBand bandOf(num? value) => value == null
    ? ScoreBand.pending
    : value >= 4
    ? ScoreBand.high
    : value >= 3
    ? ScoreBand.mid
    : ScoreBand.low;

/// Рубрика ұяшығы (Figma `ScoreCell`): 44 × 40, r8, сан ортасында.
/// Мағына тек түсте емес — сан әрқашан жазылады.
class ScoreCell extends StatelessWidget {
  const ScoreCell({
    super.key,
    required this.text,
    required this.band,
    this.width = 44,
    this.height = 40,
  });

  final String text;
  final ScoreBand band;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fill, border, color) = switch (band) {
      ScoreBand.low => (p.scoreLow, p.lineSubtle, p.onScore),
      ScoreBand.mid => (p.scoreMid, p.lineSubtle, p.onScore),
      ScoreBand.high => (p.scoreHigh, p.lineSubtle, p.onScore),
      ScoreBand.pending || ScoreBand.skipped => (
        p.surface,
        p.lineStrong,
        context.colors.onSurfaceVariant,
      ),
    };
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.cell),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        textScaler: TextScaler.linear(
          MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3),
        ),
        style: context.text.titleMedium!.copyWith(color: color),
      ),
    );
  }
}

/// Форманың дайындығы — рубрика жолы (Figma `K.ready`): әр міндетті
/// өріс — бір ұяшық. ✓ — дайын, ! — түзету керек, … — әлі толтырылмаған.
class ReadinessRow extends StatelessWidget {
  const ReadinessRow({super.key, required this.title, required this.items});

  final String title;

  /// (атауы, күйі): true — дайын, false — қате, null — күтілуде.
  final List<(String, bool?)> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final secondary = context.colors.onSurfaceVariant;
    final done = items.where((i) => i.$2 == true).length;
    final summary = [
      '$title: $done / ${items.length}',
      for (final (label, ok) in items)
        '$label — ${ok == true
            ? '✓'
            : ok == false
            ? '!'
            : '…'}',
    ].join('. ');
    return Semantics(
      container: true,
      label: summary,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.labelLarge)),
              Text(
                '$done / ${items.length}',
                style: context.text.labelLarge!.copyWith(color: secondary),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              for (final (label, ok) in items)
                Expanded(
                  child: Column(
                    spacing: 4,
                    children: [
                      Container(
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ok == true
                              ? p.scoreHigh
                              : ok == false
                              ? p.scoreLow
                              : p.muted,
                          borderRadius: BorderRadius.circular(AppRadius.cell),
                        ),
                        child: ok == null
                            ? Text(
                                '…',
                                style: context.text.labelLarge!.copyWith(
                                  color: secondary,
                                ),
                              )
                            : Icon(
                                ok ? AppIcons.check : AppIcons.priority,
                                size: 18,
                                color: p.onScore,
                              ),
                      ),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall!.copyWith(
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Бірнеше қадамдық сценарий (Figma: «1 · Email  2 · Хат  3 · Жаңа пароль»).
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.steps, required this.current});

  final List<String> steps;

  /// 0-ден басталатын ағымдағы қадам.
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '${current + 1} / ${steps.length}: ${steps[current]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Container(
                    height: i == current ? 3 : 2,
                    decoration: BoxDecoration(
                      color: i <= current ? p.ink : p.lineSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Text(
                    '${i + 1} · ${steps[i]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall!.copyWith(
                      color: i == current
                          ? context.colors.onSurface
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Бір мәнді таңдау — тең сегменттер, ортақ сия жиек (Figma `K.segmented`).
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = context.colors;
    // 200% масштабта сегменттер сыймаса — бағанға тізіледі.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    final children = [
      for (var i = 0; i < values.length; i++)
        _segment(context, i, stacked, p, colors),
    ];
    return Semantics(
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: p.ink),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control - 1),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final c in children) Expanded(child: c)],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    int i,
    bool stacked,
    AppPalette p,
    ColorScheme colors,
  ) {
    final value = values[i];
    final on = value == selected;
    final last = i == values.length - 1;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      button: true,
      child: Material(
        color: on ? colors.primary : p.surface,
        child: InkWell(
          onTap: () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : stacked
                  ? Border(bottom: BorderSide(color: p.ink))
                  : Border(right: BorderSide(color: p.ink)),
            ),
            child: Text(
              labelOf(value),
              textAlign: TextAlign.center,
              style: context.text.labelLarge!.copyWith(
                color: on ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Таңдау чиптері (Figma `K.chips`): таңдалған — сия фон және ✓.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.values,
    required this.isSelected,
    required this.labelOf,
    required this.onTap,
  });

  final List<T> values;
  final bool Function(T) isSelected;
  final String Function(T) labelOf;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final v in values)
          FilterChip(
            label: Text(labelOf(v)),
            selected: isSelected(v),
            onSelected: (_) => onTap(v),
            labelStyle: context.text.labelLarge!.copyWith(
              color: isSelected(v)
                  ? context.colors.onPrimary
                  : context.colors.onSurface,
            ),
          ),
      ],
    );
  }
}

/// Бірнеше өріске ортақ ескерту (Figma `K.flagGroup`): кіруде қайсысы қате
/// екені ашылмайды — жиек жолағы екі өрісті де қамтиды.
class FlagGroup extends StatelessWidget {
  const FlagGroup({
    super.key,
    required this.children,
    required this.message,
    this.gap = AppSpacing.md,
  });

  final List<Widget> children;

  /// null — ескерту жоқ, жолақ та жоқ.
  final String? message;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return ReviewGutter(
      flagged: message != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [
          ...children,
          if (message != null)
            Semantics(liveRegion: true, child: ReviewNote(message!)),
        ],
      ),
    );
  }
}

/// Мерзім шкаласы (Figma `K.timeline`): «20:16 Хат жіберілді — 20:31
/// Сілтеме ескіреді». Деректің қашан жойылатынын түспен емес, уақытпен
/// көрсетеді.
class DeadlineTimeline extends StatelessWidget {
  const DeadlineTimeline({super.key, required this.points});

  /// (уақыт, түсініктеме).
  final List<(String, String)> points;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: points.map((e) => '${e.$1} — ${e.$2}').join(', '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (time, label) in points)
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.ink, width: 2)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: -8,
                      child: Container(width: 2, height: 10, color: p.ink),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 0, top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(time, style: context.text.titleMedium),
                          Text(
                            label,
                            style: context.text.bodySmall!.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum TagKind { neutral, accent, warning, low, success, ink }

/// Шағын тег (Figma `K.tag`): «демо», «Толық емес», «Менікі».
class AppTag extends StatelessWidget {
  const AppTag(this.label, {super.key, this.kind = TagKind.neutral});

  final String label;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.colors;
    final (bg, fg) = switch (kind) {
      TagKind.neutral => (p.muted, c.onSurface),
      TagKind.accent => (p.accent, p.onAccent),
      TagKind.warning => (p.warningContainer, p.onWarningContainer),
      TagKind.low => (p.scoreLow, p.onScore),
      TagKind.success => (p.scoreHigh, p.success),
      TagKind.ink => (c.primary, c.onPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.tag),
      ),
      child: Text(label, style: context.text.bodySmall!.copyWith(color: fg)),
    );
  }
}

/// Рубрика торы (Figma Home / E2): жолдар — үш өлшем, бағандар — сұрақтар.
/// Өткізілген сұрақ «–», бағаланбаған «…».
class RubricGrid extends StatelessWidget {
  const RubricGrid({
    super.key,
    required this.rows,
    required this.columns,
    this.legend = true,
  });

  /// (өлшем атауы, әр сұрақтың баллы; null — балл жоқ).
  final List<(String, List<int?>)> rows;

  /// Баған белгілері: «1», «2» …
  final List<String> columns;
  final bool legend;

  @override
  Widget build(BuildContext context) {
    final secondary = context.colors.onSurfaceVariant;
    final small = context.text.bodySmall!.copyWith(color: secondary);
    return LayoutBuilder(
      builder: (context, c) {
        // Атау бағаны 0,28 ені (кемі 88), қалғаны сұрақтарға тең бөлінеді.
        final labelWidth = (c.maxWidth * 0.28).clamp(88.0, 140.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Text(S.rubricQuestion, style: small),
                  ),
                  for (final col in columns)
                    Expanded(
                      child: Text(
                        col,
                        style: small,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            for (final (title, scores) in rows)
              Semantics(
                label:
                    '$title: ${scores.map((v) => v?.toString() ?? '–').join(', ')}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          title,
                          style: context.text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final v in scores)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ScoreCell(
                              text: v?.toString() ?? '–',
                              band: v == null ? ScoreBand.skipped : bandOf(v),
                              width: double.infinity,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (legend) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(S.rubricLegend, style: small),
            ],
          ],
        );
      },
    );
  }
}

/// Рубрика өлшемі: балл ұяшығы + атау + түсіндірме (A5, B1).
class CriterionRow extends StatelessWidget {
  const CriterionRow({
    super.key,
    required this.score,
    required this.title,
    required this.hint,
  });

  final int score;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: AppSpacing.smd,
        children: [
          ScoreCell(text: '$score', band: bandOf(score), width: 32, height: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge),
                Text(
                  hint,
                  style: context.text.bodySmall!.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Үш өлшем қатар (Figma D9): атау үстінде, астында үлкен балл ұяшығы.
class ScoreTriplet extends StatelessWidget {
  const ScoreTriplet({
    super.key,
    required this.correctness,
    required this.completeness,
    required this.clarity,
    this.cellHeight = 56,
  });

  final int correctness;
  final int completeness;
  final int clarity;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final small = context.text.bodySmall!.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    Widget cell(String label, int v) => Expanded(
      child: Semantics(
        label: '$label: $v / 5',
        excludeSemantics: true,
        child: Column(
          spacing: 6,
          children: [
            Text(
              label,
              style: small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ScoreCell(
              text: '$v',
              band: bandOf(v),
              width: double.infinity,
              height: cellHeight,
            ),
          ],
        ),
      ),
    );
    return Row(
      spacing: AppSpacing.sm,
      children: [
        cell(S.correctness, correctness),
        cell(S.completeness, completeness),
        cell(S.clarity, clarity),
      ],
    );
  }
}

/// Жоюдың салдары (Figma C10/E3): моно тақырыпша және тізім; бірінші
/// жол — қайтарылмайтын деректер, сары фонда. Қызыл түс қолданылмайды.
class ConsequenceBox extends StatelessWidget {
  const ConsequenceBox({super.key, required this.header, required this.items});

  final String header;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cell),
        border: Border.all(color: p.lineStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: p.muted,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(AppIcons.label, size: 14, color: c.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    header,
                    style: AppTypography.code(c.onSurfaceVariant)
                        .copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            Container(
              color: i == 0 ? p.warningContainer : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '–  ',
                    style: context.text.bodyMedium!.copyWith(
                      color: i == 0 ? p.onWarningContainer : c.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      items[i],
                      style: context.text.bodyMedium!.copyWith(
                        color: i == 0 ? p.onWarningContainer : c.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

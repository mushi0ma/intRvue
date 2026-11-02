import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/models/enums.dart';
import '../../data/models/interview_session.dart';
import '../../data/repositories/session_repository.dart';

enum _StatusFilter {
  all,
  complete,
  incomplete;

  String get label => switch (this) {
    all => S.allSessions,
    complete => S.statusComplete,
    incomplete => S.statusIncomplete,
  };
}

/// S13 Тарих: сүзгілер, сессиялар тізімі, жою.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Direction? _direction;
  _StatusFilter _status = _StatusFilter.all;
  HistorySort _sort = HistorySort.newest;
  DateTimeRange? _period;

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _period,
      helpText: S.periodPick,
      saveText: S.apply,
    );
    if (picked != null && mounted) setState(() => _period = picked);
  }

  /// E2: сүзгі парағы — сессия күйі және кезең (7 / 30 күн / барлығы).
  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<(_StatusFilter, DateTimeRange?)>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      // Парақ төменгі навигацияны да жабады (Figma E2).
      useRootNavigator: true,
      builder: (_) => _FilterSheet(status: _status, period: _period),
    );
    if (result != null && mounted) {
      setState(() {
        _status = result.$1;
        _period = result.$2;
      });
    }
  }

  Future<void> _delete(InterviewSession s) async {
    final ok = await showConfirmDialog(
      context,
      title: S.deleteSessionTitle,
      body: S.irreversible,
      confirmLabel: S.delete,
      destructive: true,
      // E3: нені жоятынымыз — нақты тізім.
      extra: ConsequenceBox(
        header: '${Fmt.day(s.startedAt)} · ${s.trackLabel}',
        items: [
          S.consequenceAnswers(s.answeredCount),
          S.consequenceProgress,
          S.consequenceAccount,
        ],
      ),
    );
    if (!ok || !mounted) return;
    try {
      await context.read<SessionRepository>().delete(s.id);
      if (mounted) showAppSnackBar(context, S.sessionDeleted);
    } on AppException catch (e) {
      if (mounted) showAppSnackBar(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionRepository>().queryHistory(
      direction: _direction,
      complete: switch (_status) {
        _StatusFilter.all => null,
        _StatusFilter.complete => true,
        _StatusFilter.incomplete => false,
      },
      period: _period,
      sort: _sort,
    );
    final colors = context.colors;

    return AppPage(
      bottomNavigation: true,
      body: [
        const SizedBox(height: AppSpacing.md),
        // Бір жолдағы көлденең айналатын сүзгілер (M3 filter chips үлгісі):
        // ені мәтінге қарай, 360dp экранда «Барлық сесс…» болып қысқармайды.
        FullBleed(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
            child: Row(
              spacing: 8,
              children: [
                _FilterChipButton(
                  active: _status != _StatusFilter.all || _period != null,
                  onTap: _openFilters,
                ),
                FilterDropdown<Direction?>(
                  expand: false,
                  highlighted: _direction != null,
                  value: _direction,
                  values: const [null, ...Direction.values],
                  labelOf: (d) => d?.label ?? S.allDirections,
                  semanticLabel: S.fieldDirection,
                  onChanged: (d) => setState(() => _direction = d),
                ),
                FilterDropdown<_StatusFilter>(
                  expand: false,
                  highlighted: _status != _StatusFilter.all,
                  value: _status,
                  values: _StatusFilter.values,
                  labelOf: (f) => f.label,
                  semanticLabel: S.statusFilter,
                  onChanged: (f) => setState(() => _status = f),
                ),
                FilterDropdown<HistorySort>(
                  expand: false,
                  value: _sort,
                  values: HistorySort.values,
                  labelOf: (v) => v.label,
                  semanticLabel: S.sortLabel,
                  onChanged: (v) => setState(() => _sort = v),
                ),
                _PeriodButton(
                  period: _period,
                  onPick: _pickPeriod,
                  onClear: () => setState(() => _period = null),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sessions.isEmpty)
          EmptyState(title: S.historyEmptyTitle, body: S.historyEmptyBody)
        else ...[
          ListGroup(
            children: [
              for (final s in sessions)
                _SessionRow(session: s, onDelete: _delete),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            S.historyHint,
            style: context.text.bodySmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onDelete});

  final InterviewSession session;
  final ValueChanged<InterviewSession> onDelete;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final complete = s.isComplete;
    final done = s.answeredCount + s.skippedCount;
    final secondary = context.colors.onSurfaceVariant;

    return ItemRow(
      overline: Fmt.dayTime(s.startedAt),
      title: s.trackLabel,
      meta: complete
          ? '${S.questionsCount(s.questionCount)} · ${S.statusComplete}'
          : '$done / ${s.questionCount}',
      metaTrailing: complete
          ? null
          : AppTag(S.statusIncomplete, kind: TagKind.warning),
      onTap: () => context.push(Routes.summary(s.id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                complete ? Fmt.score(s.score!) : '—',
                semanticsLabel: complete ? null : S.scoreNotReady,
                style: context.text.headlineSmall,
              ),
              Text(
                '/ 100',
                style: context.text.bodySmall!.copyWith(color: secondary),
              ),
            ],
          ),
          // E1: жою ⋮ мәзірінде — тізімде қауіпті батырма көрінбейді.
          // onSelected — мәзір жабылғаннан кейін: диалог бірге жабылмайды.
          PopupMenuButton<bool>(
            tooltip: S.sessionActions,
            icon: const Icon(AppIcons.more, size: 20),
            position: PopupMenuPosition.under,
            onSelected: (_) => onDelete(s),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    const Icon(AppIcons.delete, size: 20),
                    const SizedBox(width: 12),
                    Text(S.delete),
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

/// Кезең сүзгісі: күн аралығын таңдау және тазарту.
/// «Сүзгі» түймесі: белсенді сүзгі болса — сиямен толтырылған.
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = context.colors;
    final fg = active ? colors.onPrimary : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: active ? colors.primary : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: p.ink),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Semantics(
            button: true,
            selected: active,
            label: S.filterTitle,
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(AppIcons.filter, size: 18, color: fg),
                    Text(
                      S.filterTitle,
                      style: context.text.labelMedium!.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PeriodPreset { week, month, all }

/// Figma E2: «Сессия күйі» тізімі, «Кезең» сегменттері, Тазарту / Қолдану.
/// Өзгерістер «Қолдану» басылғанда ғана қолданылады.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.status, required this.period});

  final _StatusFilter status;
  final DateTimeRange? period;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _StatusFilter _status = widget.status;
  late DateTimeRange? _period = widget.period;

  static DateTimeRange _last(int days) {
    final today = DateUtils.dateOnly(DateTime.now());
    return DateTimeRange(
      start: today.subtract(Duration(days: days - 1)),
      end: today,
    );
  }

  /// Ағымдағы кезең алдын ала жиынға сәйкес келе ме (күнтізбеден
  /// таңдалған еркін кезең — ешқайсысы емес).
  _PeriodPreset? get _preset {
    final p = _period;
    if (p == null) return _PeriodPreset.all;
    for (final (preset, days) in const [
      (_PeriodPreset.week, 7),
      (_PeriodPreset.month, 30),
    ]) {
      if (p == _last(days)) return preset;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(S.filterTitle, style: context.text.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.md),
            RadioCardGroup<_StatusFilter>(
              label: S.statusFilter,
              values: _StatusFilter.values,
              selected: _status,
              labelOf: (f) => f.label,
              onChanged: (f) => setState(() => _status = f),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(S.periodLabel, style: context.text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            if (preset == null) ...[
              Text(
                Fmt.period(_period!),
                style: context.text.bodySmall!.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            // Segmented үлкен мәтінде тігінен тізіледі, сөз бөлінбейді.
            Segmented<_PeriodPreset?>(
              semanticLabel: S.periodLabel,
              values: _PeriodPreset.values,
              selected: preset,
              labelOf: (v) => switch (v) {
                _PeriodPreset.week => S.period7,
                _PeriodPreset.month => S.period30,
                _ => S.periodAll,
              },
              onChanged: (v) => setState(
                () => _period = switch (v) {
                  _PeriodPreset.week => _last(7),
                  _PeriodPreset.month => _last(30),
                  _ => null,
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: AppButton.tonal(
                    label: S.filterClear,
                    onPressed: () =>
                        Navigator.of(context).pop((_StatusFilter.all, null)),
                  ),
                ),
                Expanded(
                  child: AppButton(
                    label: S.apply,
                    onPressed: () =>
                        Navigator.of(context).pop((_status, _period)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.period,
    required this.onPick,
    required this.onClear,
  });

  final DateTimeRange? period;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = period == null ? S.periodAll : Fmt.period(period!);
    final p = context.palette;
    final on = period != null;
    final fg = on ? colors.onPrimary : colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: on ? colors.primary : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          side: BorderSide(color: p.ink),
        ),
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Semantics(
            button: true,
            label: '${S.periodLabel}: $label',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 12),
                  Icon(AppIcons.dateRange, size: 18, color: fg),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: context.text.labelMedium!.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (period != null)
                    IconButton(
                      tooltip: S.periodClear,
                      onPressed: onClear,
                      icon: Icon(AppIcons.close, size: 18, color: fg),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

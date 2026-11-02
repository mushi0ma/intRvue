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

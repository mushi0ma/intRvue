import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
      body: '${Fmt.day(s.startedAt)} · ${s.trackLabel}\n${S.deleteSessionBody}',
      confirmLabel: S.delete,
      destructive: true,
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
      title: S.historyTitle,
      subtitle: S.historySubtitle,
      headerGap: 28,
      body: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: FilterDropdown<Direction?>(
                value: _direction,
                values: const [null, ...Direction.values],
                labelOf: (d) => d?.label ?? S.allDirections,
                semanticLabel: S.fieldDirection,
                onChanged: (d) => setState(() => _direction = d),
              ),
            ),
            Expanded(
              child: FilterDropdown<_StatusFilter>(
                value: _status,
                values: _StatusFilter.values,
                labelOf: (f) => f.label,
                semanticLabel: S.statusFilter,
                onChanged: (f) => setState(() => _status = f),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: FilterDropdown<HistorySort>(
                value: _sort,
                values: HistorySort.values,
                labelOf: (v) => v.label,
                semanticLabel: S.sortLabel,
                onChanged: (v) => setState(() => _sort = v),
              ),
            ),
            Expanded(
              child: _PeriodButton(
                period: _period,
                onPick: _pickPeriod,
                onClear: () => setState(() => _period = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          EmptyState(title: S.historyEmptyTitle, body: S.historyEmptyBody)
        else ...[
          for (final s in sessions) _SessionRow(session: s, onDelete: _delete),
          const SizedBox(height: 20),
          Text(
            S.historyHint,
            style: context.text.bodyMedium!.copyWith(
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
    final colors = context.colors;
    final s = session;
    final complete = s.isComplete;
    final done = s.answeredCount + s.skippedCount;
    final meta = complete
        ? '${S.questionsCount(s.questionCount)} · ${S.statusComplete}'
        : '$done / ${s.questionCount} · ${S.statusIncomplete}';

    return ListRow(
      meta: Fmt.dayTime(s.startedAt),
      title: s.trackLabel,
      subtitle: meta,
      subtitleColor: complete ? null : context.palette.onWarningContainer,
      onTap: () => context.push(Routes.summary(s.id)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            complete ? Fmt.score(s.score!) : '—',
            semanticsLabel: complete ? null : S.scoreNotReady,
            style: context.text.headlineSmall!.copyWith(
              fontSize: 24,
              color: colors.primary,
            ),
          ),
          TextButton(
            onPressed: () => onDelete(s),
            style: TextButton.styleFrom(
              foregroundColor: colors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              S.delete,
              style: context.text.labelMedium!.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    return Material(
      color: period == null ? colors.surface : colors.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.choice),
        side: BorderSide(
          color: period == null ? colors.outline : colors.primary,
        ),
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppRadius.choice),
        child: Semantics(
          button: true,
          label: '${S.periodLabel}: $label',
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.date_range,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (period != null)
                  IconButton(
                    tooltip: S.periodClear,
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 18),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

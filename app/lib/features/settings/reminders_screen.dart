import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../app/routes.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/reminder_scheduler.dart';

/// «Дайындыққа уақыт»: апта күндері мен уақыт. Сақтағанда Android
/// хабарламалары жоспарланады; рұқсат болмаса — түсіндіру экраны.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final _settings = context.read<SettingsRepository>();
  late bool _enabled = _settings.reminders.enabled;
  late final Set<int> _days = {..._settings.reminders.days};
  late TimeOfDay _time = _settings.reminders.time;
  String? _error;
  bool _saving = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: S.pickTime,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_enabled && _days.isEmpty) {
      setState(() => _error = S.remindersPickDay);
      return;
    }
    final scheduler = context.read<ReminderScheduler>();
    setState(() => _saving = true);
    try {
      await _settings.setReminders(
        ReminderSettings(enabled: _enabled, days: _days, time: _time),
      );
      if (!_enabled) {
        await scheduler.cancelAll();
        if (!mounted) return;
        showAppSnackBar(context, S.remindersTurnedOff);
        context.popOr(Routes.settings);
        return;
      }
      // Рұқсатты контекстте, яғни дәл қосқан сәтте сұраймыз.
      final granted =
          await scheduler.isPermitted() || await scheduler.requestPermission();
      if (!mounted) return;
      if (!granted) {
        context.pushReplacement(Routes.notificationsDenied);
        return;
      }
      await scheduler.scheduleWeekly(
        days: _days,
        time: _time,
        title: S.reminderNotificationTitle,
        body: S.reminderNotificationBody,
      );
      if (mounted) context.pushReplacement(Routes.remindersEnabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, S.remindersScheduleFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = context.text.labelMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );

    return AppPage(
      showBack: true,
      title: S.remindersTitle,
      subtitle: S.remindersSubtitle,
      headerGap: 36,
      body: [
        MergeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Text(S.remindersEnable, style: context.text.titleMedium),
              ),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() {
                  _enabled = v;
                  _error = null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(S.remindersDays, style: label),
        const SizedBox(height: 12),
        // Жеті күн екі қатарда: 4 + 3, әрқайсысы 48 dp.
        for (final row in const [
          [1, 2, 3, 4],
          [5, 6, 7],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              spacing: 8,
              children: [
                for (final day in row)
                  _DayChip(
                    label: Fmt.weekdaysShort[day]!,
                    semanticLabel: Fmt.weekdaysFull[day]!,
                    selected: _days.contains(day),
                    enabled: _enabled,
                    onTap: () => setState(() {
                      _days.contains(day) ? _days.remove(day) : _days.add(day);
                      _error = null;
                    }),
                  ),
              ],
            ),
          ),
        if (_error != null)
          Text(
            _error!,
            style: context.text.bodyMedium!.copyWith(
              color: colors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        const SizedBox(height: 24),
        AppTextField(
          key: ValueKey(_time),
          label: S.remindersTime,
          initialValue: Fmt.timeOfDay(_time),
          readOnly: true,
          enabled: _enabled,
          onTap: _pickTime,
          suffixIcon: Icon(Icons.schedule, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 40),
        InfoSection(
          title: S.remindersPermissionTitle,
          body: S.remindersPermissionBody,
        ),
      ],
      actions: [
        AppButton(
          label: _enabled ? S.remindersSave : S.save,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      // Өшірулі кезде M3 disabled мөлдірлігі — белсенді емес екені көрінеді.
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: Material(
          color: selected ? colors.primary : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: selected ? colors.primary : colors.outline),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Text(
                  label,
                  style: context.text.labelMedium!.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

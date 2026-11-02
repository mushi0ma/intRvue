import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../app/routes.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/reminder_coordinator.dart';
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

  /// Android рұқсаты: null — әлі тексерілген жоқ. Баптаулардан оралғанда
  /// қайта тексеріледі (BUG-8.05: рұқсат бар кезде де «қажет» деп тұратын).
  bool? _permitted;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _checkPermission);
    _checkPermission();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final permitted = await context.read<ReminderScheduler>().isPermitted();
    if (mounted && permitted != _permitted) {
      setState(() => _permitted = permitted);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: S.pickTime,
      // Flutter мәтін режимінде сағатты жүйелік 12/24 баптауымен оқиды, ал
      // циферблат — тіл пішімімен. kk/ru — 24 сағат: «02» 14:00 болмауы
      // үшін пішімді тілден аламыз (BUG-8.04).
      builder: (context, child) {
        final format = MaterialLocalizations.of(context).timeOfDayFormat();
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: hourFormat(of: format) != HourFormat.h,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_enabled && _days.isEmpty) {
      setState(() => _error = S.remindersPickDay);
      return;
    }
    final scheduler = context.read<ReminderScheduler>();
    final coordinator = context.read<ReminderCoordinator>();
    setState(() => _saving = true);
    try {
      await _settings.setReminders(
        ReminderSettings(enabled: _enabled, days: _days, time: _time),
      );
      if (!_enabled) {
        await scheduler.cancelAll();
        if (!mounted) return;
        showAppSnackBar(context, S.remindersTurnedOff);
        context.popOr(Routes.profile);
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
      // Мәтін мен кесте деректерден: аяқталмаған сессия, әлсіз тақырып.
      await coordinator.refresh(force: true);
      if (mounted) context.pushReplacement(Routes.remindersEnabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, S.remindersScheduleFailed);
    }
  }

  void _setEnabled(bool v) => setState(() {
    _enabled = v;
    _error = null;
  });

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
      body: [
        // Бүкіл жол басылады — тек ауыстырғыш емес (BUG-8.03).
        ListGroup(
          children: [
            SwitchListTile(
              title: Text(S.remindersEnable, style: context.text.bodyLarge),
              value: _enabled,
              onChanged: _setEnabled,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.remindersDays, style: label),
        const SizedBox(height: AppSpacing.sm),
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
        if (_error != null) ReviewNote(_error!),
        const SizedBox(height: 24),
        AppTextField(
          key: ValueKey(_time),
          label: S.remindersTime,
          initialValue: Fmt.timeOfDay(_time),
          readOnly: true,
          enabled: _enabled,
          onTap: _pickTime,
          suffixIcon: Icon(AppIcons.schedule, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_permitted ?? false)
          InfoSection(
            title: S.remindersPermissionGrantedTitle,
            body: S.remindersPermissionGrantedBody,
          )
        else
          InfoSection(
            title: S.remindersPermissionTitle,
            body: S.remindersPermissionBody,
          ),
      ],
      actions: [
        AppButton(
          label: _enabled && !(_permitted ?? false) ? S.remindersSave : S.save,
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
          color: selected ? context.palette.ink : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            side: BorderSide(color: context.palette.ink),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: Text(
                  label,
                  style: context.text.labelMedium!.copyWith(
                    color: selected ? colors.surface : colors.onSurface,
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

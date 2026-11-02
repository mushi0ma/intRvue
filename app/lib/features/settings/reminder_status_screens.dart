import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/reminder_coordinator.dart';
import '../../data/services/reminder_scheduler.dart';
import '../profile/profile_screen.dart';

/// «Еске салу қосулы» (Figma 7:334): жоспарланған күндер мен уақыт.
class RemindersEnabledScreen extends StatelessWidget {
  const RemindersEnabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<SettingsRepository>().reminders;
    return AppPage(
      showBack: true,
      onBack: () => context.go(Routes.profile),
      title: S.remindersEnabledTitle,
      subtitle: S.remindersEnabledSubtitle,
      body: [
        Semantics(
          liveRegion: true,
          child: Text(
            ProfileScreen.reminderLabel(reminders),
            style: context.text.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          S.remindersEnabledBody,
          style: context.text.bodyLarge!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
      actions: [
        AppButton.tonal(
          label: S.remindersChange,
          onPressed: () => context.pushReplacement(Routes.reminders),
        ),
        AppButton(
          label: S.backToSettings,
          onPressed: () => context.go(Routes.profile),
        ),
      ],
    );
  }
}

/// «Хабарламаға рұқсат жоқ» (Figma 7:220): жаттығу бұғатталмайды,
/// рұқсатты Android баптауларында беруге болады. Баптаулардан оралғанда
/// рұқсат қайта тексеріледі: берілсе — кесте жоспарланып, «қосулы» экраны.
class NotificationsDeniedScreen extends StatefulWidget {
  const NotificationsDeniedScreen({super.key});

  @override
  State<NotificationsDeniedScreen> createState() =>
      _NotificationsDeniedScreenState();
}

class _NotificationsDeniedScreenState extends State<NotificationsDeniedScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _recheck);
  }

  Future<void> _recheck() async {
    if (_checking) return;
    _checking = true;
    try {
      final scheduler = context.read<ReminderScheduler>();
      final coordinator = context.read<ReminderCoordinator>();
      if (!await scheduler.isPermitted()) return;
      await coordinator.refresh(force: true);
      if (mounted) context.pushReplacement(Routes.remindersEnabled);
    } catch (_) {
      if (mounted) showAppSnackBar(context, S.remindersScheduleFailed);
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: true,
      onBack: () => context.go(Routes.profile),
      title: S.reminders,
      subtitle: S.notificationsOffSubtitle,
      body: [
        InfoSection(
          title: S.notificationsOffTitle,
          body: S.notificationsOffBody,
        ),
      ],
      actions: [
        AppButton(
          label: S.openAndroidSettings,
          onPressed: () =>
              context.read<ReminderScheduler>().openSystemSettings(),
        ),
        AppButton.text(
          label: S.notNow,
          onPressed: () => context.go(Routes.profile),
        ),
      ],
    );
  }
}

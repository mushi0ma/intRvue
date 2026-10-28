import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/reminder_scheduler.dart';
import 'settings_screen.dart';

/// «Еске салу қосулы» (Figma 7:334): жоспарланған күндер мен уақыт.
class RemindersEnabledScreen extends StatelessWidget {
  const RemindersEnabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<SettingsRepository>().reminders;
    return AppPage(
      showBack: true,
      onBack: () => context.go(Routes.settings),
      title: S.remindersEnabledTitle,
      subtitle: S.remindersEnabledSubtitle,
      headerGap: 40,
      body: [
        Semantics(
          liveRegion: true,
          child: Text(
            SettingsScreen.reminderLabel(reminders),
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
          onPressed: () => context.go(Routes.settings),
        ),
      ],
    );
  }
}

/// «Хабарламаға рұқсат жоқ» (Figma 7:220): жаттығу бұғатталмайды,
/// рұқсатты Android баптауларында беруге болады.
class NotificationsDeniedScreen extends StatelessWidget {
  const NotificationsDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: true,
      onBack: () => context.go(Routes.settings),
      title: S.reminders,
      subtitle: S.notificationsOffSubtitle,
      headerGap: 40,
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
          onPressed: () => context.go(Routes.settings),
        ),
      ],
    );
  }
}

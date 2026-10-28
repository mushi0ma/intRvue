import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// S15 Баптаулар.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => S.themeSystem,
    ThemeMode.light => S.themeLight,
    ThemeMode.dark => S.themeDark,
  };

  static String reminderLabel(ReminderSettings r) {
    if (!r.enabled) return S.remindersOff;
    final days = (r.days.toList()..sort()).map((d) => Fmt.weekdaysShort[d]);
    return '${days.join(', ')} · ${Fmt.timeOfDay(r.time)}';
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: S.logoutTitle,
      body: S.logoutBody,
      confirmLabel: S.logoutAction,
    );
    if (!ok || !context.mounted) return;
    await context.read<AuthRepository>().logout();
    if (context.mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().user;
    final settings = context.watch<SettingsRepository>();
    final colors = context.colors;

    return AppPage(
      bottomNavigation: true,
      title: S.settingsTitle,
      subtitle: S.settingsSubtitle,
      headerGap: 36,
      body: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(user?.name ?? '', style: context.text.titleLarge),
                  Text(
                    user?.trackLabel ?? '',
                    style: context.text.bodyMedium!.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.profile),
              child: Text(S.profileLink),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        SettingsRow(
          title: S.interfaceLanguage,
          value: settings.language.label,
          onTap: () => context.push(Routes.appearance),
        ),
        SettingsRow(
          title: S.theme,
          value: themeLabel(settings.themeMode),
          onTap: () => context.push(Routes.appearance),
        ),
        SettingsRow(
          title: S.reminders,
          value: reminderLabel(settings.reminders),
          onTap: () => context.push(Routes.reminders),
        ),
        SettingsRow(
          title: S.fieldInterviewLanguage,
          value: user?.interviewLanguage.label ?? '',
          onTap: () => context.push(Routes.profileEdit),
        ),
        const SizedBox(height: 20),
        AppLink(
          label: S.privacy,
          onPressed: () => context.push(Routes.privacy),
        ),
        AppLink(label: S.logout, onPressed: () => _logout(context)),
        AppLink(
          label: S.deleteAccount,
          color: colors.error,
          onPressed: () => context.push(Routes.deleteAccount),
        ),
        const SizedBox(height: 16),
        Text(
          S.settingsFooter,
          style: context.text.bodySmall!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

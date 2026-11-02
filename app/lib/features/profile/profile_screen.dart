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
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/sync_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../settings/sync_screen.dart';

/// F1 Профиль — төменгі навигацияның төртінші бөлімі. Бұрынғы «Профиль»
/// (S20) мен «Баптаулар» (S15) бір экранға біріктірілді.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
    if (user == null) return const SizedBox.shrink();
    final settings = context.watch<SettingsRepository>();
    final sync = context.watch<SyncRepository>();
    final favorites = context.watch<TopicRepository>().favorites.length;
    final secondary = context.colors.onSurfaceVariant;

    return AppPage(
      bottomNavigation: true,
      body: [
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Monogram(initial: user.initial),
            const SizedBox(width: AppSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Semantics(
                    header: true,
                    child: Text(user.name, style: context.text.titleLarge),
                  ),
                  Text(
                    user.email,
                    style: context.text.bodyMedium!.copyWith(color: secondary),
                  ),
                  Text(
                    '${user.trackLabel} · ${user.interviewLanguage.label}',
                    style: context.text.bodySmall!.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.outlined(
              tooltip: S.editProfile,
              onPressed: () => context.push(Routes.profileEdit),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                side: BorderSide(color: context.palette.ink),
              ),
              icon: const Icon(AppIcons.edit, size: 20),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GroupHeader(icon: AppIcons.settings, title: S.profileGroupPractice),
        ListGroup(
          children: [
            GroupRow(
              title: S.favoriteTopics,
              value: '$favorites',
              onTap: () => context.push(Routes.favorites),
            ),
            GroupRow(
              title: S.reminders,
              value: reminderLabel(settings.reminders),
              onTap: () => context.push(Routes.reminders),
            ),
            GroupRow(
              title: S.syncTitle,
              value: SyncScreen.statusLabel(sync),
              onTap: () => context.push(Routes.sync),
            ),
          ],
        ),
        GroupHeader(icon: AppIcons.info, title: S.profileGroupMore),
        ListGroup(
          children: [
            GroupRow(
              title: S.appearanceTitle,
              value:
                  '${settings.language.label} · '
                  '${themeLabel(settings.themeMode)}',
              onTap: () => context.push(Routes.appearance),
            ),
            GroupRow(
              title: S.privacy,
              onTap: () => context.push(Routes.privacy),
            ),
            GroupRow(
              title: S.logout,
              trailing: AppIcons.logout,
              onTap: () => _logout(context),
            ),
            GroupRow(
              title: S.deleteAccount,
              subtitle: S.deleteAccountRowHint,
              onTap: () => context.push(Routes.deleteAccount),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          S.settingsFooter,
          textAlign: TextAlign.center,
          style: context.text.bodySmall!.copyWith(color: secondary),
        ),
      ],
    );
  }
}

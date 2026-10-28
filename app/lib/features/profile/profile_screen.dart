import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';

/// S20 Профиль (View).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().user;
    if (user == null) return const SizedBox.shrink();
    final colors = context.colors;
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );

    Widget field(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(label, style: muted),
          Text(value, style: context.text.titleMedium),
        ],
      ),
    );

    return AppPage(
      showBack: true,
      title: S.profileTitle,
      subtitle: S.profileSubtitle,
      headerGap: 40,
      body: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(user.name, style: context.text.headlineMedium),
                  Text(
                    user.email,
                    style: context.text.bodyLarge!.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppAvatar(initial: user.initial, size: 56),
          ],
        ),
        const SectionDivider(vertical: 24),
        field(S.fieldDirection, user.direction.label),
        field(S.fieldLevel, user.level.label),
        field(S.fieldInterviewLanguage, user.interviewLanguage.label),
      ],
      actions: [
        AppButton(
          label: S.editProfile,
          onPressed: () => context.push(Routes.profileEdit),
        ),
        AppButton.tonal(
          label: S.favoriteTopics,
          onPressed: () => context.push(Routes.favorites),
        ),
        AppLink(
          label: S.toSettings,
          alignment: Alignment.center,
          onPressed: () => context.go(Routes.settings),
        ),
      ],
    );
  }
}

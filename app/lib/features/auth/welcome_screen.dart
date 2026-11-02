import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/settings_repository.dart';

/// S01 Таныстыру: өнім идеясы және тіркелуге шақыру.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secondary = colors.onSurfaceVariant;
    return AppPage(
      leading: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Wordmark(),
      ),
      trailing: SizedBox(
        width: 136,
        child: FilterDropdown<InterfaceLanguage>(
          value: context.watch<SettingsRepository>().language,
          values: InterfaceLanguage.values,
          labelOf: (l) => l.label,
          icon: AppIcons.language,
          semanticLabel: S.interfaceLanguage,
          // Тіл бірден ауысады және баптауларда сақталады.
          onChanged: (l) {
            final settings = context.read<SettingsRepository>();
            settings.setAppearance(settings.themeMode, l);
          },
        ),
      ),
      body: [
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(S.welcomeHero, style: context.text.headlineLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          S.welcomeBody,
          style: context.text.bodyMedium!.copyWith(color: secondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.welcomeAssessmentTitle, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        // Рубрика үлгісі: бір жауап — үш өлшем, 0–5.
        CriterionRow(score: 5, title: S.correctness, hint: S.correctnessHint),
        const Divider(),
        CriterionRow(score: 4, title: S.completeness, hint: S.completenessHint),
        const Divider(),
        CriterionRow(score: 3, title: S.clarity, hint: S.clarityHint),
        const Divider(),
        const SizedBox(height: AppSpacing.smd),
        Text(
          '${S.aiDisclaimer} ${S.notHiringDecision}',
          style: context.text.bodySmall!.copyWith(color: secondary),
        ),
      ],
      actions: [
        AppButton.accent(
          label: S.continueAction,
          onPressed: () => context.push(Routes.register),
        ),
        AppButton.tonal(
          label: S.haveAccountLogin,
          onPressed: () => context.push(Routes.login),
        ),
      ],
    );
  }
}

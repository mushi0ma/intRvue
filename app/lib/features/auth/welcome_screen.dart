import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/settings_repository.dart';

/// S01 Таныстыру: өнім идеясы және тіркелуге шақыру.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPage(
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: Wordmark(),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 124,
          child: FilterDropdown<InterfaceLanguage>(
            value: context.watch<SettingsRepository>().language,
            values: InterfaceLanguage.values,
            labelOf: (l) => l.label,
            semanticLabel: S.interfaceLanguage,
            // Тіл бірден ауысады және баптауларда сақталады.
            onChanged: (l) {
              final settings = context.read<SettingsRepository>();
              settings.setAppearance(settings.themeMode, l);
            },
          ),
        ),
      ),
      body: [
        const SizedBox(height: 32),
        Semantics(
          header: true,
          child: Text(S.welcomeHero, style: context.text.displayMedium),
        ),
        const SizedBox(height: 24),
        Text(
          S.welcomeBody,
          style: context.text.bodyLarge!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        TrainingBlock(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
          children: [
            Text(
              S.welcomeAssessmentTitle,
              style: context.text.titleLarge!.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            AssessmentScales(
              correctness: 4,
              completeness: 3,
              clarity: 5,
              labels: (S.correctness, S.completeness, S.clarity),
              onBlock: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${S.aiDisclaimer}\n${S.notHiringDecision}',
          style: context.text.bodyMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
      actions: [
        AppButton(
          label: S.continueAction,
          onPressed: () => context.push(Routes.register),
        ),
        AppLink(
          label: S.haveAccountLogin,
          alignment: Alignment.center,
          onPressed: () => context.push(Routes.login),
        ),
      ],
    );
  }
}

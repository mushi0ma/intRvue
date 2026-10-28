import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';

/// S06 Басты бет: белсенді сессия, келесі жаттығу, соңғы нәтиже.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().user;
    final sessions = context.watch<SessionRepository>();
    final active = sessions.active;
    final last = sessions.lastComplete;
    final colors = context.colors;
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );
    final onBlock = TextStyle(color: colors.onPrimaryContainer);

    return AppPage(
      bottomNavigation: true,
      body: [
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      S.greeting(user?.name ?? ''),
                      style: context.text.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(S.homeSubtitle, style: muted),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: S.openProfile,
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => context.push(Routes.profile),
                radius: 28,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: AppAvatar(initial: user?.initial ?? '?'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 44),
        TrainingBlock(
          children: [
            Text(
              active != null ? S.homeResumeTitle : S.homeStartTitle,
              style: context.text.headlineMedium!.merge(onBlock),
            ),
            const SizedBox(height: 14),
            if (active != null) ...[
              Text(
                '${active.trackLabel} · ${active.language.label}',
                style: context.text.bodyMedium!.merge(onBlock),
              ),
              const SizedBox(height: 4),
              Text(
                '${S.progressOf(active.currentIndex + 1, active.questionCount)}'
                ' · ${S.draftStored}',
                style: context.text.bodyMedium!.merge(onBlock),
              ),
            ] else
              Text(
                S.homeStartBody,
                style: context.text.bodyMedium!.merge(onBlock),
              ),
            const SizedBox(height: 38),
            AppButton(
              label: active != null ? S.continueAction : S.homeStartAction,
              onPressed: () => context.push(
                active != null ? Routes.interview : Routes.practiceTopics,
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Text(S.homeNextTitle, style: context.text.titleLarge),
        const SizedBox(height: 12),
        Text(
          active != null ? S.homeNextBody : S.homeNextBodyFree,
          style: muted,
        ),
        const SizedBox(height: 24),
        AppButton.tonal(
          label: S.homeCatalog,
          onPressed: () => context.push(Routes.topics),
        ),
        const SizedBox(height: 28),
        const Divider(),
        if (last != null)
          InkWell(
            onTap: () => context.push(Routes.summary(last.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Text(S.homeLastResult, style: muted),
                        Text(last.trackLabel, style: context.text.titleMedium),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.score(last.score!),
                        style: context.text.headlineLarge!.copyWith(
                          color: colors.primary,
                        ),
                      ),
                      Text(S.outOf100, style: muted),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(S.homeNoResult, style: muted),
          ),
      ],
    );
  }
}

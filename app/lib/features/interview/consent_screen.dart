import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/session_repository.dart';

/// Алғашқы сессия алдындағы ЖИ-ге жіберуге келісім.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: true,
      title: S.consentTitle,
      body: [
        InfoSection(title: S.consentWhatTitle, body: S.consentWhatBody),
        SectionDivider(vertical: 32),
        InfoSection(title: S.consentAdviceTitle, body: S.consentAdviceBody),
      ],
      actions: [
        AppButton(
          label: S.consentAccept,
          onPressed: () async {
            await context.read<SessionRepository>().giveConsent();
            if (context.mounted) context.pushReplacement(Routes.preparing);
          },
        ),
        AppButton.tonal(
          label: S.notNow,
          onPressed: () => context.popOr(Routes.home),
        ),
      ],
    );
  }
}

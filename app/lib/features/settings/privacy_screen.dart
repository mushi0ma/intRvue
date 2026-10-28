import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/widgets.dart';

/// Құпиялылық: ЖИ-ге не жіберіледі, не сақталады, қалай жоюға болады.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: true,
      title: S.privacy,
      subtitle: S.privacySubtitle,
      headerGap: 40,
      body: [
        InfoSection(title: S.privacyAiTitle, body: S.privacyAiBody),
        SectionDivider(vertical: 28),
        InfoSection(title: S.privacyStoredTitle, body: S.privacyStoredBody),
        SectionDivider(vertical: 28),
        InfoSection(title: S.privacyManageTitle, body: S.privacyManageBody),
        SectionDivider(vertical: 28),
        InfoSection(title: S.privacyOfflineTitle, body: S.privacyOfflineBody),
      ],
    );
  }
}

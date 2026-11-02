import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/widgets.dart';

/// F15 Құпиялылық: ЖИ-ге не жіберіледі, не сақталады, қалай жоюға болады.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showBack: true,
      title: S.privacy,
      subtitle: S.privacySubtitle,
      body: [
        FullBleed(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              for (final (icon, title, body) in [
                (AppIcons.psychology, S.privacyAiTitle, S.privacyAiBody),
                (AppIcons.database, S.privacyStoredTitle, S.privacyStoredBody),
                (AppIcons.cloud, S.privacySyncTitle, S.privacySyncBody),
                (AppIcons.delete, S.privacyManageTitle, S.privacyManageBody),
                (AppIcons.offline, S.privacyOfflineTitle, S.privacyOfflineBody),
              ]) ...[
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ExcludeSemantics(child: Icon(icon, size: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
                                  style: context.text.titleSmall,
                                ),
                              ),
                              Text(
                                body,
                                style: context.text.bodySmall!.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

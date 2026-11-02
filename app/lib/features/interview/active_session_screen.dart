import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/session_repository.dart';

/// «Бір сессия аяқталмаған»: бір уақытта тек бір белсенді сессия.
class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.read<SessionRepository>();
    final active = sessions.active;
    final colors = context.colors;

    return AppPage(
      showBack: true,
      title: S.activeTitle,
      body: [
        Text(
          S.activeBody,
          style: context.text.bodyMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (active != null)
          ListGroup(
            children: [
              ItemRow(
                overline: active.trackLabel,
                title: S.progressOf(
                  active.currentIndex + 1,
                  active.questionCount,
                ),
                meta: S.draftStored,
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Ерте аяқтаудың салдары — қызыл емес, жиектегі белгімен.
        FullBleed(
          child: InfoBanner(
            kind: BannerKind.warning,
            title: S.statusIncomplete,
            body: S.activeWarning,
          ),
        ),
      ],
      actions: [
        AppButton(
          label: S.activeResume,
          onPressed: () {
            sessions.pending = null;
            context.go(Routes.interview);
          },
        ),
        AppButton.tonal(
          label: S.activeFinishAndNew,
          onPressed: () async {
            try {
              await sessions.finishActive();
            } on AppException catch (e) {
              if (context.mounted) showAppSnackBar(context, e.message);
              return;
            }
            if (!context.mounted) return;
            context.pushReplacement(
              sessions.consentGiven ? Routes.preparing : Routes.consent,
            );
          },
        ),
      ],
    );
  }
}

/// B5: аяқталмаған сессия бар кезде жаңасын бастау — диалог.
/// true — ерте аяқтап, жаңасын бастау; false — жалғастыру; null — жабылды.
Future<bool?> showActiveConflictDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.activeTitle),
        content: Text('${S.activeBody} ${S.activeWarning}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.activeFinishAndNew),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.activeResumeShort),
          ),
        ],
      ),
    );

/// Жаңа жаттығуды ашу. Аяқталмаған сессия болса — алдымен B5 диалогы:
/// жалғастыру сессияға апарады, аяқтау оны «Толық емес» етіп сақтайды.
/// [then] — диалогтан кейін (не сессия жоқ болса) не істеу.
Future<void> resolveActiveThen(BuildContext context, VoidCallback then) async {
  final sessions = context.read<SessionRepository>();
  if (sessions.active == null) return then();
  final finish = await showActiveConflictDialog(context);
  if (finish == null || !context.mounted) return;
  if (!finish) {
    sessions.pending = null;
    context.go(Routes.interview);
    return;
  }
  try {
    await sessions.finishActive();
  } on AppException catch (e) {
    if (context.mounted) showAppSnackBar(context, e.message);
    return;
  }
  if (context.mounted) then();
}

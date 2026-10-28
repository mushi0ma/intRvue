import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/session_repository.dart';
import '../results/assessment_details.dart';

/// S10 Кері байланыс: үш өлшем, дәлел, нені толықтыру керек.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  /// Экраннан кетіп жатырмыз: күй өзгерсе де қайта бағыттамаймыз.
  bool _leaving = false;

  Future<void> _next(SessionRepository sessions) async {
    final session = sessions.active!;
    final id = session.id;
    final last = session.isLastQuestion;
    setState(() => _leaving = true);
    try {
      await sessions.next();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _leaving = false);
      showAppSnackBar(context, e.message);
      return;
    }
    if (mounted) context.go(last ? Routes.summary(id) : Routes.interview);
  }

  @override
  Widget build(BuildContext context) {
    if (_leaving) return const Scaffold();
    final sessions = context.watch<SessionRepository>();
    final session = sessions.active;
    final assessment = session?.current.assessment;
    if (session == null || assessment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(session == null ? Routes.home : Routes.interview);
        }
      });
      return const Scaffold();
    }
    final index = session.currentIndex;
    final record = session.current;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: AppPage(
        // Бұл — ағымдағы орын белгісі, сілтеме емес (Figma S10).
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            S.feedbackHeader(index + 1, session.questionCount),
            style: context.text.labelLarge!.copyWith(
              color: context.colors.primary,
            ),
          ),
        ),
        title: assessment.headline,
        subtitle: assessment.advice,
        subtitleStyle: context.text.bodyLarge,
        body: [
          AssessmentDetails(
            record: record,
            onDispute: () => context.push(Routes.dispute(session.id, index)),
          ),
        ],
        actions: [
          AppButton.tonal(
            label: S.readModelAnswer,
            onPressed: () =>
                context.push(Routes.modelAnswer(session.id, index)),
          ),
          AppButton(
            label: session.isLastQuestion ? S.finishSession : S.nextQuestion,
            onPressed: () => _next(sessions),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/local/db_errors.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/topic_repository.dart';
import '../results/assessment_details.dart';
import 'practice_bar.dart';

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
    final topic = context.read<TopicRepository>().tryById(
      record.question.topicId,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: AppPage(
        leading: PracticeBar(
          icon: AppIcons.close,
          tooltip: S.pauseHome,
          onPressed: () => context.go(Routes.home),
          label: S.feedbackLabel,
          counter: '${index + 1} / ${session.questionCount}',
          counterSemantics: S.feedbackHeader(index + 1, session.questionCount),
        ),
        body: [
          const SizedBox(height: AppSpacing.sm),
          QuestionProgress(total: session.questionCount, done: index + 1),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    assessment.headline,
                    style: context.text.headlineLarge,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AppTag(S.demoTag, kind: TagKind.warning),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          CodeText(
            assessment.advice,
            style: context.text.bodyMedium!.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AssessmentDetails(
            record: record,
            showDisputeLink: false,
            onDispute: () => context.push(Routes.dispute(session.id, index)),
          ),
          // D10: әлсіз жауап — тақырыпты қайталау туралы ескерту.
          if (assessment.total < 9 && topic != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FullBleed(
              child: InfoBanner(
                kind: BannerKind.warning,
                title: S.weakAnswerTitle,
                body: S.weakAnswerBody(topic.title),
              ),
            ),
          ],
        ],
        actions: [
          AppButton.accent(
            label: session.isLastQuestion ? S.finishSession : S.nextQuestion,
            onPressed: () => _next(sessions),
          ),
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: AppButton.tonal(
                  label: S.modelAnswerTitle,
                  icon: AppIcons.book,
                  onPressed: () =>
                      context.push(Routes.modelAnswer(session.id, index)),
                ),
              ),
              if (!record.disputed)
                Expanded(
                  child: AppButton.tonal(
                    label: S.disagreeShort,
                    icon: AppIcons.flag,
                    onPressed: () =>
                        context.push(Routes.dispute(session.id, index)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

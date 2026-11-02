import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/interview_session.dart';

/// Түсіндірілген баға: үш өлшем, дәлел, жетіспейтін ұғымдар.
/// S10 Кері байланыс пен сақталған жауапта бірдей қолданылады.
class AssessmentDetails extends StatelessWidget {
  const AssessmentDetails({
    super.key,
    required this.record,
    required this.onDispute,
    this.showDisputeLink = true,
  });

  final AnswerRecord record;
  final VoidCallback onDispute;

  /// false — «Келіспеймін» экранның төменгі әрекеттерінде (D9).
  final bool showDisputeLink;

  @override
  Widget build(BuildContext context) {
    final assessment = record.assessment!;
    final colors = context.colors;
    final p = context.palette;
    final muted = context.text.bodyMedium!.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScoreTriplet(
          correctness: assessment.correctness,
          completeness: assessment.completeness,
          clarity: assessment.clarity,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.evidenceTitle, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        // Дәлел — жауаптан алынған үзінді: сол жақта сия сызық (Figma D9).
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(left: BorderSide(color: p.ink, width: 2)),
          ),
          child: Text(assessment.evidence, style: context.text.bodyMedium),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(S.missingTitle, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        if (assessment.missing.isEmpty)
          Text(S.nothingMissing, style: muted)
        else
          for (final item in assessment.missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 20,
                      child: Text('+', style: context.text.bodyMedium),
                    ),
                  ),
                  Expanded(child: Text(item, style: context.text.bodyMedium)),
                ],
              ),
            ),
        const SizedBox(height: 16),
        if (record.disputed)
          Semantics(
            container: true,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.flag, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.disputeReason == null
                              ? S.disputeSent
                              : '${S.yourFeedback}: ${record.disputeReason}',
                          style: context.text.labelMedium!.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((record.disputeComment ?? '').isNotEmpty)
                    Text(
                      '«${record.disputeComment}»',
                      style: context.text.bodyMedium!.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  Text(
                    S.disputeScoreUnchanged,
                    style: context.text.bodySmall!.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (showDisputeLink)
          AppLink(label: S.disagree, onPressed: onDispute),
      ],
    );
  }
}

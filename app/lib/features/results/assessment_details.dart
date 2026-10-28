import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/interview_session.dart';

/// Түсіндірілген баға: үш өлшем, дәлел, жетіспейтін ұғымдар.
/// S10 Кері байланыс пен сақталған жауапта бірдей қолданылады.
class AssessmentDetails extends StatelessWidget {
  const AssessmentDetails({
    super.key,
    required this.record,
    required this.onDispute,
  });

  final AnswerRecord record;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    final assessment = record.assessment!;
    final colors = context.colors;
    final muted = context.text.bodyLarge!.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssessmentScales(
          correctness: assessment.correctness,
          completeness: assessment.completeness,
          clarity: assessment.clarity,
          labels: (S.correctness, S.completeness, S.clarity),
        ),
        const SectionDivider(vertical: 24),
        Text(S.evidenceTitle, style: context.text.titleMedium),
        const SizedBox(height: 12),
        Text(assessment.evidence, style: muted),
        const SizedBox(height: 24),
        Text(S.missingTitle, style: context.text.titleMedium),
        const SizedBox(height: 12),
        if (assessment.missing.isEmpty)
          Text(S.nothingMissing, style: muted)
        else
          for (final item in assessment.missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $item', style: muted),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check, size: 18, color: colors.primary),
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
        else
          AppLink(label: S.disagree, onPressed: onDispute),
      ],
    );
  }
}

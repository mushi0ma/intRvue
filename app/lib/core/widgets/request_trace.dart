import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Сұрау жолы (Figma F13/F17): телефон — желі — сервер, үзілген жерде «!».
/// Қызыл мәтіннің орнына — сұрау қай жерде тоқтағанын көрсететін сызба.
class RequestTrace extends StatelessWidget {
  const RequestTrace({
    super.key,
    required this.request,
    this.reachedNetwork = true,
  });

  /// «GET 10.0.2.2:8787/v1/topics».
  final String request;

  /// false — желінің өзі жоқ (офлайн): үзіліс телефон мен желі арасында.
  final bool reachedNetwork;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.colors;
    Widget node(IconData icon, String label, {bool dim = false}) => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: dim ? p.muted : p.surface,
            border: Border.all(color: dim ? p.lineStrong : p.ink),
            borderRadius: BorderRadius.circular(AppRadius.cell),
          ),
          child: Icon(icon, size: 20, color: dim ? c.onSurfaceVariant : null),
        ),
        Text(
          label,
          textScaler: TextScaler.noScaling,
          style: context.text.bodySmall!.copyWith(
            fontSize: 11,
            color: dim ? c.onSurfaceVariant : null,
          ),
        ),
      ],
    );
    Widget line({bool broken = false}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: broken
            ? Row(
                children: [
                  Expanded(
                    child: Container(height: 2, color: p.warningContainer),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.warningContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      AppIcons.priority,
                      size: 12,
                      color: p.onWarningContainer,
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: p.lineStrong)),
                ],
              )
            : Container(height: 2, color: p.ink),
      ),
    );
    return Semantics(
      label: '$request → ${S.traceNoResponse}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              node(AppIcons.phone, S.traceDevice),
              line(broken: !reachedNetwork),
              node(AppIcons.wifi, S.traceNetwork, dim: !reachedNetwork),
              line(broken: reachedNetwork),
              node(AppIcons.server, S.traceServer, dim: true),
            ],
          ),
          Text(
            '$request → ${S.traceNoResponse}',
            style: AppTypography.code(c.onSurfaceVariant)
                .copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

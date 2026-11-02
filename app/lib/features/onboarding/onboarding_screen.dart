import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/auth_repository.dart';

/// O1–O3: үш таныстыру беті. «Өткізу» кез келген беттен S01-ге апарады.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  static List<(String, String)> get _content => [
    (S.onboarding1Title, S.onboarding1Body),
    (S.onboarding2Title, S.onboarding2Body),
    (S.onboarding3Title, S.onboarding3Body),
  ];

  bool get _isLast => _index == _content.length - 1;

  Future<void> _finish() async {
    await context.read<AuthRepository>().completeOnboarding();
    if (mounted) context.go(Routes.welcome);
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_index - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A2–A4: «1 / 3» және «Өткізу»; артқа — жүйелік қимыл.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
                    child: SizedBox(
                      height: AppSpacing.touchTarget,
                      child: Row(
                        children: [
                          Text(
                            '${_index + 1} / ${_content.length}',
                            style: context.text.bodySmall!.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (!_isLast)
                            TextButton(onPressed: _finish, child: Text(S.skip)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: _content.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _OnboardingPage(
                        index: i,
                        title: _content[i].$1,
                        body: _content[i].$2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: PageIndicator(count: _content.length, index: _index),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: AppButton.accent(
                      label: _isLast ? S.start : S.next,
                      onPressed: _isLast ? _finish : () => _go(_index + 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: p.lineSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              child: switch (index) {
                0 => const _AnswerPreview(),
                1 => const _AssessmentPreview(),
                _ => const _WeakTopicsPreview(),
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(title, style: context.text.headlineLarge),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: context.text.bodyMedium!.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _AnswerPreview extends StatelessWidget {
  const _AnswerPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = context.palette;
    final small = context.text.bodySmall!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.code, size: 16, color: colors.onSurface),
              const SizedBox(width: 6),
              Expanded(child: Text('Flutter виджеттері', style: small)),
              Text(
                '2 / 5',
                style: small.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smd),
          Text(
            'StatelessWidget пен StatefulWidget-тің айырмашылығы неде?',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.smd),
          Text(S.onboardingYourAnswer, style: context.text.labelLarge),
          const SizedBox(height: 6),
          Container(
            height: 84,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: p.ink, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Text(
              'StatelessWidget өзгермейтін интерфейсті көрсетеді…',
              style: context.text.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(AppIcons.check, size: 14, color: p.success),
              const SizedBox(width: 4),
              Text(
                '${S.draftSaved} · 17:42',
                style: small.copyWith(color: p.success),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentPreview extends StatelessWidget {
  const _AssessmentPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = context.palette;
    final small = context.text.bodySmall!;
    Widget cell(String label, int v) => Expanded(
      child: Column(
        spacing: 6,
        children: [
          Text(label, style: small.copyWith(color: colors.onSurfaceVariant)),
          ScoreCell(
            text: '$v',
            band: bandOf(v),
            width: double.infinity,
            height: 48,
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              cell(S.correctness, 4),
              cell(S.completeness, 3),
              cell(S.clarity, 5),
            ],
          ),
          const SizedBox(height: AppSpacing.smd),
          Container(
            padding: const EdgeInsets.all(AppSpacing.smd),
            decoration: BoxDecoration(
              color: p.muted,
              borderRadius: BorderRadius.circular(AppRadius.cell),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  S.evidenceTitle,
                  style: small.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  '«Өзгермейтін интерфейс» дұрыс түсіндірілген.',
                  style: context.text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              AppTag(S.demoTag, kind: TagKind.warning),
              Expanded(
                child: Text(
                  S.demoAssessmentNote,
                  style: small.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeakTopicsPreview extends StatelessWidget {
  const _WeakTopicsPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = context.palette;
    final small = context.text.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );
    Widget row(String name, String score) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.bodyLarge),
                Text('Mobile · Бастапқы', style: small),
              ],
            ),
          ),
          Text(score, style: context.text.bodyMedium),
          const SizedBox(width: 8),
          Icon(AppIcons.forward, size: 18, color: colors.onSurface),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: p.muted,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(S.onboardingWeakTopics, style: small),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ListGroup(
            children: [
              row('Асинхрондылық', '60 / 100'),
              row('Күйді басқару', '66 / 100'),
              row('Dart негіздері', '72 / 100'),
            ],
          ),
        ),
      ],
    );
  }
}

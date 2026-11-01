import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: SizedBox(
                      height: AppSpacing.touchTarget,
                      child: Row(
                        children: [
                          if (_index == 0)
                            const Flexible(
                              child: Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Wordmark(),
                              ),
                            )
                          else
                            AppBackLink(onPressed: () => _go(_index - 1)),
                          const Spacer(),
                          if (!_isLast)
                            TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: Text(S.skip),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  PageIndicator(count: _content.length, index: _index),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: AppButton(
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: switch (index) {
                    0 => const _AnswerPreview(),
                    1 => const _AssessmentPreview(),
                    _ => const _WeakTopicsPreview(),
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.headlineLarge),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: context.text.bodyLarge!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
    final small = context.text.bodySmall!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Flutter виджеттері',
          style: context.text.labelMedium!.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'StatelessWidget пен\nStatefulWidget айырмасы?',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          S.onboardingYourAnswer,
          style: context.text.labelMedium!.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 84,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Text(
            'Stateless өзгермейтін интерфейс,\nStateful күйге қарай жаңарады.',
            style: context.text.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(S.draftSaved, style: small.copyWith(color: colors.primary)),
            const Spacer(),
            Text(
              '58 / 4000',
              style: small.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssessmentPreview extends StatelessWidget {
  const _AssessmentPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Негізгі ой дұрыс.', style: context.text.titleMedium),
        const SizedBox(height: 20),
        AssessmentScales(
          correctness: 4,
          completeness: 3,
          clarity: 5,
          labels: (S.correctness, S.completeness, S.clarity),
          spacing: 16,
        ),
        const SizedBox(height: 16),
        Text(
          '«Күйі өзгергенде интерфейс жаңарады»',
          style: context.text.bodySmall!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WeakTopicsPreview extends StatelessWidget {
  const _WeakTopicsPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.text.titleSmall!;
    Widget row(String name, String score) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(name, style: title)),
          Text(score, style: title.copyWith(color: colors.primary)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.onboardingWeakTopics,
          style: context.text.labelMedium!.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        row('Күйді басқару', '58,0'),
        const Divider(),
        row('Асинхрондылық', '61,3'),
        const Divider(),
        row('Dart негіздері', '66,7'),
        const SizedBox(height: 12),
        Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            S.onboardingPractice,
            style: context.text.labelMedium!.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

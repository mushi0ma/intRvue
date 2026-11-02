import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/wordmark.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/reminder_coordinator.dart';

/// S00 Splash: логотип және 1,5 с жүктелу жолағы.
/// Кейін: онбординг → таныстыру → немесе бірден басты бет.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 1500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: SplashScreen.duration,
  )..forward().whenComplete(_next);

  Future<void> _next() async {
    if (!mounted) return;
    final auth = context.read<AuthRepository>();
    // Қосымшаны еске салу хабарламасы ашса — басты беттің үстінен сол экран.
    final launch = await context.read<ReminderCoordinator>().takeLaunchRoute();
    if (!mounted) return;
    final target = auth.isLoggedIn
        ? Routes.home
        : auth.onboardingSeen
        ? Routes.welcome
        : Routes.onboarding;
    context.go(target);
    if (launch != null) context.push(launch);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final muted = context.text.bodySmall!.copyWith(color: p.onPanelMuted);
    // A1: қараңғы панель екі тақырыпта да; күй жолағы ақ.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.panel,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 5),
                Semantics(
                  header: true,
                  child: const Wordmark(large: true, onPanel: true),
                ),
                const SizedBox(height: AppSpacing.smd),
                Text(
                  S.splashTagline,
                  style: context.text.titleLarge!.copyWith(
                    color: p.onPanelMuted,
                  ),
                ),
                const Spacer(flex: 6),
                // Жүктелу: үш сегмент кезекпен толады.
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    final v = Curves.easeOut.transform(_progress.value) * 3;
                    return Row(
                      spacing: 4,
                      children: [
                        for (var i = 0; i < 3; i++)
                          SizedBox(
                            width: 24,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: LinearProgressIndicator(
                                value: (v - i).clamp(0, 1),
                                minHeight: 3,
                                color: p.accent,
                                backgroundColor: p.onPanelMuted.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.smd),
                Text(S.splashFooter, style: muted),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
    final colors = context.colors;
    final muted = context.text.bodyLarge!.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 5),
            Semantics(
              header: true,
              child: Text(
                S.appName,
                textAlign: TextAlign.center,
                style: context.text.displayLarge!.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(S.splashTagline, style: muted, textAlign: TextAlign.center),
            const SizedBox(height: 64),
            Center(
              child: SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: Curves.easeOut.transform(_progress.value),
                      minHeight: 4,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 6),
            Text(S.splashFooter, style: muted, textAlign: TextAlign.center),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

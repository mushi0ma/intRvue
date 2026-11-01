import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/reminder_coordinator.dart';
import '../data/services/reminder_scheduler.dart';
import '../l10n/gen/app_localizations.dart';
import 'bootstrap.dart';
import 'router.dart';
import 'routes.dart';

/// Тәуелділіктерді ағашқа береді: AppServices → Provider.
class IntRvueApp extends StatefulWidget {
  const IntRvueApp({
    super.key,
    required this.services,
    this.initialLocation = Routes.splash,
  });

  final AppServices services;
  final String initialLocation;

  @override
  State<IntRvueApp> createState() => _IntRvueAppState();
}

class _IntRvueAppState extends State<IntRvueApp> {
  late final GoRouter router = buildRouter(
    widget.services.auth,
    initial: widget.initialLocation,
  );

  StreamSubscription<String>? _reminderTaps;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Қосымша қайта ашылды: үзілген live-байланысты кідіріссіз қалпына
    // келтіріп, үзіліс кезіндегі өзгерістерді қуып жетеміз.
    _lifecycle = AppLifecycleListener(
      onResume: widget.services.sync.live.retryNow,
    );
    // Ашық қосымшада басылған еске салу: сол сәттегі деректерге сай экран.
    _reminderTaps = widget.services.reminderCoordinator.openRequests.listen(
      _openFromReminder,
    );
  }

  void _openFromReminder(String route) {
    final here = router.state.uri.path;
    if (here == Routes.splash) return; // Splash өзі launch маршрутын ашады.
    if (here == Uri.parse(route).path) return;
    router.push(route);
  }

  @override
  void dispose() {
    _reminderTaps?.cancel();
    _lifecycle.dispose();
    router.dispose();
    super.dispose();
  }

  Locale? _locale;

  /// S мәтіндері статикалық оқылады, сондықтан тіл ауысқанда бүкіл ағашты
  /// қайта құрамыз — навигация мен экран күйі сақталады.
  void _applyLocale(Locale locale) {
    if (_locale == locale) return;
    final changed = _locale != null;
    _locale = locale;
    S.use(locale);
    if (!changed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element e) {
        e.markNeedsBuild();
        e.visitChildren(rebuild);
      }

      if (mounted) (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: s.auth),
        ChangeNotifierProvider.value(value: s.settings),
        ChangeNotifierProvider.value(value: s.topics),
        ChangeNotifierProvider.value(value: s.sessions),
        ChangeNotifierProvider.value(value: s.sync),
        ChangeNotifierProvider.value(value: s.cloud),
        Provider<ReminderScheduler>.value(value: s.reminders),
        Provider<ReminderCoordinator>.value(value: s.reminderCoordinator),
      ],
      // Android 12+: жүйе тұсқағаз түстерін береді; басқа жерде — null.
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) => Consumer<SettingsRepository>(
          builder: (context, settings, _) {
            final system =
                settings.systemColors &&
                lightDynamic != null &&
                darkDynamic != null;
            final locale = Locale(settings.language.name);
            _applyLocale(locale);
            return MaterialApp.router(
              title: 'intRvue',
              debugShowCheckedModeBanner: false,
              theme: system
                  ? AppTheme.fromSystem(lightDynamic, Brightness.light)
                  : AppTheme.light,
              darkTheme: system
                  ? AppTheme.fromSystem(darkDynamic, Brightness.dark)
                  : AppTheme.dark,
              themeMode: settings.themeMode,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

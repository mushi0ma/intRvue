import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/startup_error_app.dart';
import 'core/log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  try {
    final services = await AppServices.start();
    // Желі қайта пайда болды → live кідірісті күтпей бірден қосылады.
    Connectivity().onConnectivityChanged
        .where((r) => r.any((c) => c != ConnectivityResult.none))
        .listen(
          (_) => services.sync.live.retryNow(),
          onError: (Object e) => Log.warn('net', 'connectivity: $e'),
        );
    runApp(IntRvueApp(services: services));
  } catch (error, stack) {
    Log.error('startup', 'failed', '$error\n$stack');
    // Деректер қоры ашылмаса — түсінікті хабарлама және қайталау батырмасы.
    runApp(StartupErrorApp(onRetry: _start));
  }
}

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  try {
    final services = await AppServices.start();
    runApp(IntRvueApp(services: services));
  } catch (error, stack) {
    debugPrint('Startup failed: $error\n$stack');
    // Деректер қоры ашылмаса — түсінікті хабарлама және қайталау батырмасы.
    runApp(StartupErrorApp(onRetry: _start));
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/app/app.dart';
import 'package:intrvue/app/bootstrap.dart';
import 'package:intrvue/data/remote/sync_api.dart';
import 'package:intrvue/data/services/reminder_scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Figma экранының өлшемі (412 × 892) және жүйелік жолақтар.
const figmaSize = Size(412, 892);
const statusBar = 44.0;
const gestureBar = 24.0;

bool _fontsLoaded = false;

/// Medeo, Material Symbols және Material Icons-ты тест ортасына жүктейді —
/// скриншоттар нақты шрифтпен салынады.
Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Medeo Sans', [
    for (final w in ['Regular', 'Medium', 'SemiBold'])
      'assets/fonts/MedeoSans-$w.ttf',
  ]);
  await load('Medeo Sans Display', [
    for (final w in ['Light', 'Regular', 'Medium'])
      'assets/fonts/MedeoSansDisplay-$w.ttf',
  ]);
  await load('Medeo Mono', [
    for (final w in ['Regular', 'Medium']) 'assets/fonts/MedeoMono-$w.ttf',
  ]);
  // Пакет қарпі тестте `packages/<пакет>/<отбасы>` атымен ізделеді.
  final symbols = _packageRoot('material_symbols_icons');
  await load('packages/material_symbols_icons/MaterialSymbolsSharp', [
    '$symbols/lib/fonts/MaterialSymbolsSharp.ttf',
  ]);
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/.flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
  _fontsLoaded = true;
}

/// `.dart_tool/package_config.json` бойынша пакеттің түбірлік қалтасы.
String _packageRoot(String name) {
  final config = jsonDecode(
    File('.dart_tool/package_config.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final pkg = (config['packages']! as List)
      .cast<Map<String, Object?>>()
      .firstWhere((p) => p['name'] == name);
  final root = Uri.parse(pkg['rootUri']! as String);
  return root.isAbsolute
      ? root.toFilePath()
      : Directory('.dart_tool').uri.resolveUri(root).toFilePath();
}

/// Қосымшаны берілген маршрутта ашады.
Future<void> pumpApp(
  WidgetTester tester, {
  required String location,
  bool loggedIn = true,
  Map<String, Object> prefs = const {},
  ThemeMode theme = ThemeMode.light,
  Size size = figmaSize,
  double pixelRatio = 1,
  double textScale = 1,
  bool noFavorites = false,
  String? databasePath,
  ReminderScheduler? reminders,
  SyncApi Function(Uri)? syncApi,
}) async {
  tester.view
    ..physicalSize = size * pixelRatio
    ..devicePixelRatio = pixelRatio
    ..padding = FakeViewPadding(
      top: statusBar * pixelRatio,
      bottom: gestureBar * pixelRatio,
    )
    ..viewPadding = FakeViewPadding(
      top: statusBar * pixelRatio,
      bottom: gestureBar * pixelRatio,
    );
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  SharedPreferences.setMockInitialValues({
    'onboarding.seen': true,
    'settings.theme': theme.name,
    // Демо аккаунт деректер қорына бірінші болып жазылады: id = 1.
    if (loggedIn) 'auth.userId': 1,
    ...prefs,
  });
  final services = await tester.runAsync(
    () => startServices(
      path: databasePath,
      noFavorites: noFavorites,
      reminders: reminders,
      syncApi: syncApi,
    ),
  );
  addTearDown(() => tester.runAsync(services!.dispose));
  await tester.pumpWidget(
    IntRvueApp(services: services!, initialLocation: location),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Әр тестке жеке SQLite қоры: әдепкіде жадта, [path] берілсе — файлда
/// (қайта іске қосуды тексеру үшін).
Future<AppServices> startServices({
  String? path,
  bool noFavorites = false,
  ReminderScheduler? reminders,
  SyncApi Function(Uri)? syncApi,
}) async {
  final services = await AppServices.start(
    factory: databaseFactoryFfiNoIsolate,
    databasePath: path ?? inMemoryDatabasePath,
    reminders: reminders ?? const NoopReminderScheduler(),
    syncApi: syncApi,
  );
  if (noFavorites) {
    await services.database.db.delete('favorites');
    await services.topics.loadFor(services.auth.user);
  }
  return services;
}

/// Провайдерден репозиторийді алу.
T repo<T>(WidgetTester tester) =>
    Provider.of<T>(tester.element(find.byType(Scaffold).first), listen: false);

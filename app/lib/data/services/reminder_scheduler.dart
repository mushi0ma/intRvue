import 'dart:io';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Еске салу хабарламаларын жоспарлау.
abstract interface class ReminderScheduler {
  /// Рұқсат бар ма (Android 13+ POST_NOTIFICATIONS).
  Future<bool> isPermitted();

  /// Рұқсат сұрау. Пайдаланушы бас тартса — false.
  Future<bool> requestPermission();

  /// Таңдалған апта күндері [time]-да апта сайын қайталанатын хабарламалар.
  Future<void> scheduleWeekly({
    required Set<int> days,
    required TimeOfDay time,
    required String title,
    required String body,
  });

  Future<void> cancelAll();

  /// Android-тағы қосымша баптаулары (рұқсатты қолмен беру үшін).
  Future<void> openSystemSettings();
}

/// Android-та flutter_local_notifications, басқа платформаларда ештеңе
/// жасамайды (десктоп пен тесттер).
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler._(this._plugin);

  static const _channelId = 'reminders';
  static const _channelName = 'Еске салу';

  /// Апта күні 1–7 → хабарлама id 101–107.
  static int _id(int weekday) => 100 + weekday;

  final FlutterLocalNotificationsPlugin? _plugin;

  static Future<ReminderScheduler> create() async {
    if (!Platform.isAndroid) return const NoopReminderScheduler();
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Белгісіз аймақ: UTC-мен қаламыз, уақыт сағатпен жылжуы мүмкін.
    }
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    return LocalReminderScheduler._(plugin);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      ?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> isPermitted() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<void> scheduleWeekly({
    required Set<int> days,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    await cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    for (final weekday in days) {
      await _plugin!.zonedSchedule(
        id: _id(weekday),
        title: title,
        body: body,
        scheduledDate: nextInstance(tz.TZDateTime.now(tz.local), weekday, time),
        notificationDetails: details,
        // Дәл уақытқа арнайы рұқсат керек емес; бірнеше минут ауытқуы мүмкін.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// [now]-нан кейінгі ең жақын [weekday] (1 = дүйсенбі) күні [time].
  static tz.TZDateTime nextInstance(
    tz.TZDateTime now,
    int weekday,
    TimeOfDay time,
  ) {
    var date = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  @override
  Future<void> cancelAll() async {
    for (var d = 1; d <= 7; d++) {
      await _plugin?.cancel(id: _id(d));
    }
  }

  @override
  Future<void> openSystemSettings() => openAppSettings();
}

/// Хабарлама жоқ платформалар және тесттер үшін.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler({this.permitted = true});

  final bool permitted;

  @override
  Future<bool> isPermitted() async => permitted;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<void> scheduleWeekly({
    required Set<int> days,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> openSystemSettings() async {}
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';

/// Еске салу кестесі: апта күндері (1 = дүйсенбі) және уақыт.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = false,
    this.days = const {1, 3, 5},
    this.time = const TimeOfDay(hour: 19, minute: 0),
    this.skipIfPracticed = true,
    this.remindUnfinished = true,
  });

  final bool enabled;
  final Set<int> days;
  final TimeOfDay time;

  /// Бүгін сессия аяқталса, бүгінгі еске салу өткізіледі (Figma F4).
  final bool skipIfPracticed;

  /// Аяқталмаған сессия болса, еске салу соны жалғастыруды ұсынады.
  final bool remindUnfinished;

  ReminderSettings copyWith({
    bool? enabled,
    Set<int>? days,
    TimeOfDay? time,
    bool? skipIfPracticed,
    bool? remindUnfinished,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      days: days ?? this.days,
      time: time ?? this.time,
      skipIfPracticed: skipIfPracticed ?? this.skipIfPracticed,
      remindUnfinished: remindUnfinished ?? this.remindUnfinished,
    );
  }
}

class SettingsRepository extends ChangeNotifier {
  SettingsRepository(this._prefs) {
    _themeMode = ThemeMode.values.byName(
      _prefs.getString(_themeKey) ?? ThemeMode.system.name,
    );
    // Әдепкіде бренд түстері: жүйелік палитра intRvue-дің жасыл
    // бірегейлігін көкке ауыстырып жібереді (эмуляторда тексерілді).
    _systemColors = _prefs.getBool(_systemColorsKey) ?? false;
    _language = InterfaceLanguage.values.byName(
      _prefs.getString(_languageKey) ?? InterfaceLanguage.kk.name,
    );
    final days = _prefs.getStringList(_reminderDaysKey);
    _reminders = ReminderSettings(
      enabled: _prefs.getBool(_reminderOnKey) ?? false,
      days: days == null ? const {1, 3, 5} : days.map(int.parse).toSet(),
      time: TimeOfDay(
        hour: _prefs.getInt(_reminderHourKey) ?? 19,
        minute: _prefs.getInt(_reminderMinuteKey) ?? 0,
      ),
      skipIfPracticed: _prefs.getBool(_reminderSkipKey) ?? true,
      remindUnfinished: _prefs.getBool(_reminderUnfinishedKey) ?? true,
    );
  }

  static const _themeKey = 'settings.theme';
  static const _languageKey = 'settings.language';
  static const _systemColorsKey = 'settings.systemColors';
  static const _reminderOnKey = 'settings.reminder.on';
  static const _reminderDaysKey = 'settings.reminder.days';
  static const _reminderHourKey = 'settings.reminder.hour';
  static const _reminderMinuteKey = 'settings.reminder.minute';
  static const _reminderSkipKey = 'settings.reminder.skipIfPracticed';
  static const _reminderUnfinishedKey = 'settings.reminder.unfinished';

  final SharedPreferences _prefs;
  late ThemeMode _themeMode;
  late bool _systemColors;
  late InterfaceLanguage _language;
  late ReminderSettings _reminders;

  ThemeMode get themeMode => _themeMode;

  /// Android 12+ тұсқағаз түстері (Material You). Ескі нұсқаларда intRvue
  /// палитрасы қолданылады.
  bool get systemColors => _systemColors;
  InterfaceLanguage get language => _language;
  ReminderSettings get reminders => _reminders;

  Future<void> setAppearance(
    ThemeMode mode,
    InterfaceLanguage language, {
    bool? systemColors,
  }) async {
    _themeMode = mode;
    _language = language;
    _systemColors = systemColors ?? _systemColors;
    notifyListeners();
    await _prefs.setString(_themeKey, mode.name);
    await _prefs.setString(_languageKey, language.name);
    await _prefs.setBool(_systemColorsKey, _systemColors);
  }

  Future<void> setReminders(ReminderSettings value) async {
    _reminders = value;
    notifyListeners();
    await _prefs.setBool(_reminderOnKey, value.enabled);
    await _prefs.setStringList(
      _reminderDaysKey,
      value.days.map((d) => '$d').toList(),
    );
    await _prefs.setInt(_reminderHourKey, value.time.hour);
    await _prefs.setInt(_reminderMinuteKey, value.time.minute);
    await _prefs.setBool(_reminderSkipKey, value.skipIfPracticed);
    await _prefs.setBool(_reminderUnfinishedKey, value.remindUnfinished);
  }
}

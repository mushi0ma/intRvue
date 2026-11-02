import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Көрсету форматтары: үтірлі ондық бөлшек, ай мен апта күндері
/// интерфейс тілінде.
abstract final class Fmt {
  /// Ай атауы (ілік септік формасы) интерфейс тілінде, 1 = қаңтар.
  /// «қазан»
  static String month(DateTime d) => _month(d.month);

  static String _month(int m) => switch (m) {
    1 => S.month1,
    2 => S.month2,
    3 => S.month3,
    4 => S.month4,
    5 => S.month5,
    6 => S.month6,
    7 => S.month7,
    8 => S.month8,
    9 => S.month9,
    10 => S.month10,
    11 => S.month11,
    _ => S.month12,
  };

  /// Апта күндерінің қысқа атаулары, 1 = дүйсенбі.
  static Map<int, String> get weekdaysShort => {
    1: S.weekdayShort1,
    2: S.weekdayShort2,
    3: S.weekdayShort3,
    4: S.weekdayShort4,
    5: S.weekdayShort5,
    6: S.weekdayShort6,
    7: S.weekdayShort7,
  };

  /// Экран оқу құралы үшін толық атаулар.
  static Map<int, String> get weekdaysFull => {
    1: S.weekdayFull1,
    2: S.weekdayFull2,
    3: S.weekdayFull3,
    4: S.weekdayFull4,
    5: S.weekdayFull5,
    6: S.weekdayFull6,
    7: S.weekdayFull7,
  };

  /// 80.0 → «80,0»
  static String score(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  /// «19 қазан»
  static String day(DateTime d) => '${d.day} ${_month(d.month)}';

  /// «1–19 қазан», «28 қыркүйек – 3 қазан»
  static String period(DateTimeRange r) {
    final a = r.start, b = r.end;
    if (DateUtils.isSameDay(a, b)) return day(a);
    if (a.month == b.month && a.year == b.year) {
      return '${a.day}–${b.day} ${_month(a.month)}';
    }
    return '${day(a)} – ${day(b)}';
  }

  /// «19 қазан · 18:42»
  static String dayTime(DateTime d) => '${day(d)} · ${time(d)}';

  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String timeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Диаграмма осі үшін: «19.10»
  static String shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

// Табылған қателердің қайта тексерісі (практикалық №7, қателер тізімі).
// Әр тест — бір қате: түзетуге дейін құлайды, кейін өтеді.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intrvue/core/constants/app_strings.dart';
import 'package:intrvue/core/theme/app_theme.dart';
import 'package:intrvue/core/widgets/widgets.dart';

void main() {
  setUp(() => S.use(const Locale('kk')));

  Widget host(Widget child, {ThemeData? theme, double scale = 1}) =>
      MaterialApp(
        theme: theme ?? AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(body: child),
        ),
      );

  testWidgets('BUG-07: сөз-белгі 200% мәтінде екі жолға бөлінбейді', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Center(child: SizedBox(width: 312, child: Wordmark(large: true))),
        scale: 2,
      ),
    );
    // Күтілетін: бір жол (≈ 1,2 × 104 px), ені 312-ден аспайды.
    // Түзетуге дейін: 360 dp-де үш жолға бөлінді (биіктігі 342 px).
    final text = tester.getSize(find.text(S.appName));
    expect(text.height, lessThan(52 * 2 * 1.6));
    expect(tester.getSize(find.byType(Wordmark)).width, lessThanOrEqualTo(312));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BUG-08: қараңғы тақырыпта мәзір беттен ажырайды', (
    tester,
  ) async {
    final theme = AppTheme.dark;
    await tester.pumpWidget(
      host(
        FilterDropdown<int>(
          value: 1,
          values: const [1, 2],
          labelOf: (v) => 'Нұсқа $v',
          onChanged: (_) {},
        ),
        theme: theme,
      ),
    );
    await tester.tap(find.text('Нұсқа 1'));
    await tester.pumpAndSettle();

    final menu = tester.widget<Material>(
      find
          .ancestor(of: find.text('Нұсқа 2'), matching: find.byType(Material))
          .last,
    );
    // Күтілетін: мәзір түсі бет фонынан өзгеше және шекарасы бар.
    expect(menu.color, isNot(theme.scaffoldBackgroundColor));
    expect(
      (menu.shape! as RoundedRectangleBorder).side.style,
      BorderStyle.solid,
    );
  });
}

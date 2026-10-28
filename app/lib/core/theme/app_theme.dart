import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Қосымшаның жарық және қараңғы тақырыптары. Барлық экран түсті, шрифтті
/// және пішінді осы жерден алады — виджеттерде түстер қатаң жазылмайды.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, AppPalette.light);
  static ThemeData get dark => _build(AppColors.dark, AppPalette.dark);

  /// Material You: жүйелік түстер, семантикалық рөлдер (қате, ескерту)
  /// intRvue палитрасынан қалады.
  static ThemeData fromSystem(ColorScheme scheme, Brightness brightness) {
    final brand = brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final palette = brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    return _build(
      scheme.copyWith(
        error: brand.error,
        onError: brand.onError,
        errorContainer: brand.errorContainer,
        onErrorContainer: brand.onErrorContainer,
      ),
      // Графиктің бұлыңғыр бағандары да жүйелік палитрадан — әйтпесе
      // бренд жасылы мен жүйелік түс араласып кетеді.
      palette.copyWith(
        navigationBar: scheme.surfaceContainerHighest,
        chartMuted: scheme.secondary,
      ),
    );
  }

  static ThemeData _build(ColorScheme colors, AppPalette palette) {
    final text = AppTypography.textTheme(colors);
    final isDark = colors.brightness == Brightness.dark;
    const buttonShape = StadiumBorder();
    const buttonSize = Size.fromHeight(AppSpacing.controlHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      extensions: [palette],
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          disabledBackgroundColor: palette.disabledContainer,
          disabledForegroundColor: palette.onDisabled,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: colors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: text.bodyLarge!.copyWith(color: colors.onSurfaceVariant),
        errorStyle: text.bodySmall!.copyWith(color: colors.error),
        errorMaxLines: 3,
        helperMaxLines: 3,
        border: border(colors.outline),
        enabledBorder: border(colors.outline),
        focusedBorder: border(colors.primary, 2),
        errorBorder: border(colors.error),
        focusedErrorBorder: border(colors.error, 2),
        disabledBorder: border(colors.outlineVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        side: BorderSide(color: colors.onSurfaceVariant, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.outline,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : colors.outline,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: text.bodyLarge!.copyWith(
          color: colors.onInverseSurface,
          height: 1.2,
        ),
        actionTextColor: colors.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.snackbar),
        ),
        insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? colors.surfaceContainerHigh : colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        titleTextStyle: text.titleLarge!.copyWith(fontWeight: FontWeight.w500),
        contentTextStyle: text.bodyMedium!.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: palette.navigationBar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.navigationBar,
        indicatorColor: colors.secondaryContainer,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: text.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelSmall!.copyWith(
          color: colors.onSurfaceVariant,
        ),
        selectedIconTheme: IconThemeData(color: colors.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.secondaryContainer,
        stopIndicatorColor: Colors.transparent,
        trackGap: 0,
        // ignore: deprecated_member_use
        year2023: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

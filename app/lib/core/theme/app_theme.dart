import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_icons.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Қосымшаның жарық және қараңғы тақырыптары (Figma «v2 · Components»).
/// Барлық экран түсті, шрифтті және пішінді осы жерден алады — виджеттерде
/// түстер қатаң жазылмайды.
///
/// Қате қызыл түспен белгіленбейді: өріс шекарасы — сия (line/ink),
/// хабарлама — сия мәтін, белгі — рубриканың төменгі жолағы (score/low).
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, AppPalette.light);
  static ThemeData get dark => _build(AppColors.dark, AppPalette.dark);

  /// Material You: беттер жүйелік түстерден, мағыналық рөлдер (ескерту,
  /// рубрика жолақтары) intRvue палитрасынан қалады.
  static ThemeData fromSystem(ColorScheme scheme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final brand = dark ? AppColors.dark : AppColors.light;
    final palette = dark ? AppPalette.dark : AppPalette.light;
    return _build(
      scheme.copyWith(
        error: brand.error,
        onError: brand.onError,
        errorContainer: brand.errorContainer,
        onErrorContainer: brand.onErrorContainer,
        surfaceTint: Colors.transparent,
      ),
      palette.fromScheme(scheme),
    );
  }

  static ThemeData _build(ColorScheme colors, AppPalette palette) {
    final text = AppTypography.textTheme(colors);
    final isDark = colors.brightness == Brightness.dark;
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );
    const buttonSize = Size(64, AppSpacing.controlHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 16);
    final label = text.labelLarge!;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      extensions: [palette],
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Material Symbols Sharp, Light (300), толтырусыз.
      iconTheme: IconThemeData(
        color: colors.onSurface,
        size: 24,
        weight: 300,
        fill: 0,
        opticalSize: 24,
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(AppIcons.back),
        closeButtonIconBuilder: (_) => const Icon(AppIcons.close),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: colors.onSurface, weight: 300),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: control,
          textStyle: label,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: palette.disabledContainer,
          disabledForegroundColor: palette.onDisabled,
          iconSize: 20,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: control,
          textStyle: label,
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.ink),
          iconSize: 20,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.touchTarget,
            AppSpacing.touchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: control,
          textStyle: label,
          foregroundColor: palette.ink,
          iconSize: 20,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurface,
          minimumSize: const Size.square(AppSpacing.touchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: text.bodyLarge!.copyWith(color: colors.onSurfaceVariant),
        helperStyle: text.bodySmall!.copyWith(color: colors.onSurfaceVariant),
        // Қате — қызыл емес: сия мәтін, белгіні AppTextField салады.
        errorStyle: text.bodySmall!.copyWith(color: colors.onSurface),
        errorMaxLines: 4,
        helperMaxLines: 4,
        border: border(palette.lineStrong),
        enabledBorder: border(palette.lineStrong),
        focusedBorder: border(palette.ink, 1.5),
        errorBorder: border(palette.ink, 1.5),
        focusedErrorBorder: border(palette.ink, 1.5),
        disabledBorder: border(palette.lineSubtle),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyLarge,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.surface),
          shape: WidgetStatePropertyAll(control),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mark),
        ),
        side: BorderSide(color: palette.lineStrong, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colors.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : palette.lineStrong,
        ),
      ),
      // Figma toggle: қосулы — сия жолақ + жасыл түйін, өшірулі — бұлыңғыр.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return palette.onDisabled;
          return s.contains(WidgetState.selected)
              ? palette.accent
              : palette.lineStrong;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) {
            return palette.disabledContainer;
          }
          return s.contains(WidgetState.selected)
              ? colors.primary
              : palette.muted;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : palette.lineStrong,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? BorderSide.none
              : BorderSide(color: palette.lineStrong),
        ),
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : palette.surface,
        ),
        labelStyle: label.copyWith(color: colors.onSurface),
        secondaryLabelStyle: label.copyWith(color: colors.onPrimary),
        checkmarkColor: colors.onPrimary,
        iconTheme: IconThemeData(size: 18, color: colors.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: true,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSpacing.touchTarget),
          ),
          shape: WidgetStatePropertyAll(control),
          side: WidgetStatePropertyAll(BorderSide(color: palette.ink)),
          textStyle: WidgetStatePropertyAll(label),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? colors.primary
                : palette.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? colors.onPrimary
                : colors.onSurface,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: label,
        unselectedLabelStyle: text.bodyMedium,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: palette.ink, width: 2),
        ),
        dividerColor: palette.lineSubtle,
        dividerHeight: 1,
        tabAlignment: TabAlignment.start,
        labelPadding: const EdgeInsets.only(right: 20),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: palette.lineSubtle),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall!.copyWith(
          color: colors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 14,
      ),
      dividerTheme: DividerThemeData(
        color: palette.lineSubtle,
        thickness: AppSpacing.hairline,
        space: AppSpacing.hairline,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.panel,
        contentTextStyle: text.bodyMedium!.copyWith(color: palette.onPanel),
        actionTextColor: palette.onPanelAccent,
        shape: control,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: palette.lineSubtle),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              side: BorderSide(color: palette.lineSubtle),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: palette.scrim,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          side: BorderSide(color: palette.lineSubtle),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge!.copyWith(
          color: colors.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: palette.scrim,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.lineStrong,
        dragHandleSize: const Size(32, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        hourMinuteShape: control,
        dayPeriodShape: control,
        dialBackgroundColor: palette.muted,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.panel,
          borderRadius: BorderRadius.circular(AppRadius.tag),
        ),
        textStyle: text.bodySmall!.copyWith(color: palette.onPanel),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: palette.nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: palette.accent,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelPadding: const EdgeInsets.only(top: 4),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected)
                ? palette.onNavActive
                : palette.onNav,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            weight: 300,
            color: s.contains(WidgetState.selected)
                ? palette.onAccent
                : palette.onNav,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.nav,
        indicatorColor: palette.accent,
        indicatorShape: const StadiumBorder(),
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: text.labelSmall!.copyWith(
          color: palette.onNavActive,
        ),
        unselectedLabelTextStyle: text.labelSmall!.copyWith(
          color: palette.onNav,
        ),
        selectedIconTheme: IconThemeData(color: palette.onAccent, weight: 300),
        unselectedIconTheme: IconThemeData(color: palette.onNav, weight: 300),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: palette.muted,
        circularTrackColor: Colors.transparent,
        stopIndicatorColor: Colors.transparent,
        linearMinHeight: 4,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        trackGap: 0,
        // ignore: deprecated_member_use
        year2023: false,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.ink,
        selectionColor: palette.accent.withValues(alpha: 0.6),
        selectionHandleColor: palette.ink,
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

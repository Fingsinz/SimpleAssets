import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'theme_presets.dart';

class AppTheme {
  AppTheme._();

  /// 默认（靛青）浅色主题，供不关心配色的测试与局部预览使用。
  static ThemeData get light => lightFor(AppThemePreset.indigo);

  /// 默认（靛青）深色主题。
  static ThemeData get dark => darkFor(AppThemePreset.indigo);

  static ThemeData lightFor(AppThemePreset preset) =>
      _build(preset, Brightness.light);

  static ThemeData darkFor(AppThemePreset preset) =>
      _build(preset, Brightness.dark);

  static ThemeData forPreset(AppThemePreset preset, Brightness brightness) =>
      _build(preset, brightness);

  static ThemeData _build(AppThemePreset preset, Brightness brightness) {
    final look = preset.lookFor(brightness);
    final base = ColorScheme.fromSeed(
      seedColor: preset.seed,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: look.primary,
      onPrimary: look.onPrimary,
      primaryContainer: look.primaryContainer,
      onPrimaryContainer: look.onPrimaryContainer,
      secondary: look.primary,
      onSecondary: look.onPrimary,
      secondaryContainer: look.primaryContainer,
      onSecondaryContainer: look.onPrimaryContainer,
      tertiary: look.tertiary,
      onTertiary: brightness == Brightness.dark
          ? look.onPrimary
          : Colors.white,
      tertiaryContainer: look.tertiaryContainer,
      onTertiaryContainer: look.onTertiaryContainer,
      surface: look.surface,
      onSurface: look.onSurface,
      onSurfaceVariant: look.onSurfaceVariant,
      inverseSurface: look.onSurface,
      onInverseSurface: look.surface,
      inversePrimary: brightness == Brightness.dark
          ? look.hero
          : look.primaryContainer,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: look.surface,
      surfaceContainerLow: look.surface,
      surfaceContainer: look.surface,
      surfaceContainerHigh: look.surfaceContainerHighest,
      surfaceContainerHighest: look.surfaceContainerHighest,
      outline: look.outline,
      outlineVariant: look.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _tabularTextTheme(
        ThemeData(brightness: brightness, useMaterial3: true).textTheme,
      ),
      extensions: [AppPalette(look: look, preset: preset)],
      scaffoldBackgroundColor: look.background,
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: look.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: look.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(preset.cardRadius),
          side: BorderSide(color: look.border, width: 0.8),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: look.surface,
        modalBackgroundColor: look.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(preset.headerRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: look.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(preset.cardRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: look.primary),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: look.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(preset.controlRadius),
          borderSide: BorderSide(color: look.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(preset.controlRadius),
          borderSide: BorderSide(color: look.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(preset.controlRadius),
          borderSide: BorderSide(color: look.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(preset.controlRadius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(preset.controlRadius),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: look.navBar,
        indicatorColor: look.primaryContainer,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? look.primary
                : look.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? look.onPrimaryContainer
                : look.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(preset.controlRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: look.onSurface,
        contentTextStyle: TextStyle(color: look.surface),
        actionTextColor: brightness == Brightness.dark
            ? look.hero
            : look.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: look.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: look.primary,
        linearTrackColor: look.primaryContainer,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: look.primary,
        selectionColor: look.primary.withValues(alpha: 0.22),
        selectionHandleColor: look.primary,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStatePropertyAll(
          look.onSurfaceVariant.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

TextTheme _tabularTextTheme(TextTheme base) {
  TextStyle? t(TextStyle? style) =>
      style == null ? null : AppTypography.tabular(style);
  return TextTheme(
    displayLarge: t(base.displayLarge),
    displayMedium: t(base.displayMedium),
    displaySmall: t(base.displaySmall),
    headlineLarge: t(base.headlineLarge),
    headlineMedium: t(base.headlineMedium),
    headlineSmall: t(base.headlineSmall),
    titleLarge: t(base.titleLarge),
    titleMedium: t(base.titleMedium),
    titleSmall: t(base.titleSmall),
    bodyLarge: t(base.bodyLarge),
    bodyMedium: t(base.bodyMedium),
    bodySmall: t(base.bodySmall),
    labelLarge: t(base.labelLarge),
    labelMedium: t(base.labelMedium),
    labelSmall: t(base.labelSmall),
  );
}

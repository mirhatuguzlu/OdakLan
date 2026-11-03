import 'package:flutter/material.dart';

/// Same palette as site/src/app/globals.css — keep them in sync.
/// One accent (amber = Enerji); green/red only carry game meaning
/// (focused / fortress damage). The app is dark-only.
abstract final class AppColors {
  static const background = Color(0xFF0D0E11);
  static const surface = Color(0xFF16181D);
  static const raised = Color(0xFF1D2026);
  static const border = Color(0xFF2A2D35);
  static const text = Color(0xFFECEDEF);
  static const textMuted = Color(0xFF8B8F98);
  static const accent = Color(0xFFF5A524);
  static const success = Color(0xFF3CCB7F);
  static const danger = Color(0xFFF0564A);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: AppColors.background,
        secondary: AppColors.success,
        // Selected chips/segments: neutral fill, amber text.
        secondaryContainer: AppColors.raised,
        onSecondaryContainer: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        // Neutral containers: the amber seed would tint dialogs/sheets brown.
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: AppColors.surface,
        surfaceContainer: AppColors.surface,
        surfaceContainerHigh: AppColors.raised,
        surfaceContainerHighest: AppColors.raised,
        error: AppColors.danger,
        outline: AppColors.border,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

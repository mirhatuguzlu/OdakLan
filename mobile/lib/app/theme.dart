import 'package:flutter/material.dart';

/// Cyberpunk palette; the app is dark-only.
abstract final class AppColors {
  static const background = Color(0xFF0B0B14);
  static const surface = Color(0xFF151527);
  static const border = Color(0xFF2A2A45);
  static const text = Color(0xFFE8E8F0);
  static const textMuted = Color(0xFF8A8AA3);
  static const neonCyan = Color(0xFF00F0FF);
  static const neonPink = Color(0xFFFF2E88);
  static const success = Color(0xFF3DFF9A);
  static const danger = Color(0xFFFF4D4D);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.neonCyan,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.neonCyan,
        secondary: AppColors.neonPink,
        surface: AppColors.surface,
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
      indicatorColor: AppColors.neonCyan.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

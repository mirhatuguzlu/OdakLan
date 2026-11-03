import 'package:flutter/material.dart';

/// Same palette as mobile/lib/app/theme.dart — keep them in sync.
abstract final class SiteColors {
  static const background = Color(0xFF0B0B14);
  static const surface = Color(0xFF151527);
  static const border = Color(0xFF2A2A45);
  static const text = Color(0xFFE8E8F0);
  static const textMuted = Color(0xFF8A8AA3);
  static const neonCyan = Color(0xFF00F0FF);
  static const neonPink = Color(0xFFFF2E88);
  static const neonViolet = Color(0xFF8B5CFF);
  static const success = Color(0xFF3DFF9A);
  static const danger = Color(0xFFFF4D4D);

  static const brandGradient = LinearGradient(
    colors: [neonCyan, neonViolet, neonPink],
  );
}

ThemeData buildSiteTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SiteColors.neonCyan,
      brightness: Brightness.dark,
    ).copyWith(primary: SiteColors.neonCyan, secondary: SiteColors.neonPink),
    scaffoldBackgroundColor: SiteColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: SiteColors.text,
      displayColor: SiteColors.text,
    ),
  );
}

/// Layout breakpoint shared by all sections.
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

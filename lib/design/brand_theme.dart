import 'package:flutter/material.dart';

/// Screen palette transcribed from the Mushuc Runa identity manual.
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF7A0708);
  static const primaryDk = Color(0xFF5E0000);
  static const primaryDeep = primaryDk;
  static const green = Color(0xFF004F18);
  static const gold = Color(0xFFBEA458);
  static const ink = Color(0xFF0A0203);

  // Screen neutrals derived from the official wine, gold, ink, and white.
  static const primarySoft = Color(0xFFF5E7E7);
  static const goldDk = Color(0xFF806C36);
  static const coral = primary;
  static const orange = goldDk;
  static const yellow = gold;
  static const inkSoft = Color(0xFF706467);
  static const line = Color(0xFFE8DFC8);
  static const surface = Color(0xFFFAF7EF);
  static const cardBg = Colors.white;
  static const mapGreen = green;
}

/// Typographic roles from the manual, without bundling proprietary font files.
class BrandType {
  const BrandType._();

  static const institutional = TextStyle(
    fontFamily: 'serif',
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const wordmark = TextStyle(
    fontWeight: FontWeight.w900,
    letterSpacing: -.5,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDk,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      secondaryContainer: Color(0xFFF4EDD9),
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.green,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE2EEE5),
      onTertiaryContainer: AppColors.green,
      surface: AppColors.cardBg,
      onSurface: AppColors.ink,
      outline: AppColors.line,
      error: AppColors.primaryDk,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: scheme,
      fontFamily: 'System',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: AppColors.ink,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(color: AppColors.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.line,
      ),
    );
  }
}

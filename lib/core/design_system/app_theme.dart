import 'package:flutter/material.dart';

abstract final class AppColors {
  // A warm, calm palette that keeps health information approachable and legible.
  static const plum = Color(0xFF542043),
      berry = Color(0xFFB04370),
      rose = Color(0xFFF1B5C6),
      lavender = Color(0xFFD9BDD8),
      ivory = Color(0xFFFFF8F7),
      ink = Color(0xFF352634),
      muted = Color(0xFF766976),
      line = Color(0xFFEEDFE6),
      success = Color(0xFF5F8975),
      warning = Color(0xFFC47B4A),
      critical = Color(0xFFB74E59),
      fertility = Color(0xFF946A9C),
      pregnancy = Color(0xFFC06991);
}

abstract final class AppSpace {
  static const xxs = 4.0,
      xs = 8.0,
      sm = 12.0,
      md = 16.0,
      lg = 24.0,
      xl = 32.0,
      xxl = 40.0,
      hero = 48.0;
}

abstract final class AppRadius {
  static const small = 12.0, medium = 20.0, large = 28.0, sheet = 32.0;
}

ThemeData lunaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF1D171D) : AppColors.ivory;
  final surface = dark ? const Color(0xFF2A222B) : const Color(0xFFFFFDFC);
  final text = dark ? const Color(0xFFF7EDF2) : AppColors.ink;
  final muted = dark ? const Color(0xFFCDBEC7) : AppColors.muted;
  return ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.berry,
          brightness: brightness,
          surface: surface,
          onSurface: text,
        ).copyWith(
          primary: dark ? const Color(0xFFF0AFC6) : AppColors.berry,
          secondary: dark ? const Color(0xFFE7BED9) : AppColors.pregnancy,
          tertiary: dark ? const Color(0xFFE3CEE3) : AppColors.lavender,
        ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Georgia',
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        height: .95,
        fontWeight: FontWeight.w500,
        color: text,
      ),
      displayMedium: TextStyle(
        fontSize: 37,
        height: 1,
        fontWeight: FontWeight.w500,
        color: text,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      headlineMedium: TextStyle(
        fontSize: 23,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: muted),
      labelLarge: TextStyle(
        fontSize: 13,
        letterSpacing: .7,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: muted,
      ),
    ),
    dividerColor: dark ? const Color(0xFF453945) : AppColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF2A222B) : const Color(0xFFFFFCFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF564553) : AppColors.line,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF564553) : AppColors.line,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.berry, width: 1.5),
      ),
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}

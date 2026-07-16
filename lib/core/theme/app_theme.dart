import 'package:flutter/material.dart';

abstract final class GloColors {
  static const background = Color(0xFF07090F);
  static const surface = Color(0xFF0D1426);
  static const surfaceStrong = Color(0xFF111B31);
  static const border = Color(0x1FFFFFFF);
  static const text = Color(0xFFEEF2FF);
  static const muted = Color(0xFF8292B2);
  static const textMuted = muted;
  static const leagueOne = Color(0xFF1E6FDB);
  static const primary = leagueOne;
  static const leagueTwo = Color(0xFF16A34A);
  static const accent = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
}

abstract final class AppTheme {
  static ThemeData dark({Color primary = GloColors.leagueOne}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: GloColors.surface,
      error: GloColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GloColors.background,
      colorScheme: scheme,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: GloColors.background,
        foregroundColor: GloColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: GloColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GloColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF090D17),
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? GloColors.text : GloColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GloColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GloColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GloColors.border),
        ),
      ),
      dividerColor: GloColors.border,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w900),
        titleMedium: TextStyle(fontWeight: FontWeight.w800),
        bodyMedium: TextStyle(color: GloColors.text),
        bodySmall: TextStyle(color: GloColors.muted),
      ),
    );
  }
}

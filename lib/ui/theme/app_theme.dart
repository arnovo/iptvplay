import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF131B2E);
  static const Color surfaceLight = Color(0xFF1E2942);
  static const Color border = Color(0xFF2B3A5A);
  static const Color primary = Color(0xFF00E5FF); // Vibrant Cyan
  static const Color primaryGlow = Color(0x3300E5FF);
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentGreen = Color(0xFF10B981);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
    ),
    fontFamily: '-apple-system',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_pallete.dart';

class AppTheme {
  // ============= DARK THEME =============
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppPallete.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPallete.primary,
      brightness: Brightness.dark,
      primary: AppPallete.primary,
      secondary: AppPallete.secondary,
      error: AppPallete.error,
      surface: AppPallete.surface,
    ),

    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppPallete.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppPallete.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPallete.textPrimary),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppPallete.textSecondary,
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(20),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(AppPallete.primary),
      errorBorder: _border(AppPallete.error),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppPallete.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  // ============= LIGHT THEME =============
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPallete.lightBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPallete.lightPrimary,
      brightness: Brightness.light,
      primary: AppPallete.lightPrimary,
      secondary: AppPallete.lightSecondary,
      error: AppPallete.error,
      surface: AppPallete.lightSurface,
    ),

    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppPallete.lightTextPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppPallete.lightTextPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: AppPallete.lightTextPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: AppPallete.lightTextSecondary,
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.all(20),
      border: _lightBorder(),
      enabledBorder: _lightBorder(),
      focusedBorder: _lightBorder(AppPallete.lightPrimary),
      errorBorder: _lightBorder(AppPallete.error),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppPallete.lightPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  static OutlineInputBorder _border([Color color = Colors.transparent]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: color == Colors.transparent ? Colors.grey.withAlpha(50) : color,
        width: 2,
      ),
    );
  }

  static OutlineInputBorder _lightBorder([Color color = Colors.transparent]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: color == Colors.transparent ? Colors.grey.shade300 : color,
        width: 1.5,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_pallete.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppPallete.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPallete.primary,
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
      filled: true,
      fillColor: Colors.white,
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

  static OutlineInputBorder _border([Color color = Colors.transparent]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: color == Colors.transparent ? Colors.grey.withAlpha(50) : color,
        width: 2,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppPallete {
  static const Color primary = Color(0xFF2979FF); // Performance Blue
  static const Color secondary = Color(0xFF00B0FF); // Light Blue Accent
  static const Color background = Color(0xFF0F172A); // Light Dark (Slate 900)
  static const Color surface = Color(0xFF1E293B); // Slate 800

  static const Color textPrimary = Color(0xFFE2E8F0); // Off-White
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400

  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFEA00);

  static const Color glassBorder = Colors.white24;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x1FFFFFFF), Color(0x05FFFFFF)], // Darker glass
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PausaColors {
  // Base
  static const black = Color(0xFF0A0A0A);
  static const surface = Color(0xFF161616);
  static const surfaceAlt = Color(0xFF1E1E1E);
  static const white = Color(0xFFF0F0F0);
  static const whiteStrong = Color(0xFFFFFFFF);

  // Acento
  static const red = Color(0xFFE24B4A);
  static const redMuted = Color(0xFF3D1A1A);

  // Texto
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF888888);
  static const textMuted = Color(0xFF444444);

  // Bordes
  static const border = Color(0xFF2A2A2A);
  static const borderStrong = Color(0xFF3A3A3A);
}

class PausaTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PausaColors.black,
    colorScheme: const ColorScheme.dark(
      primary: PausaColors.white,
      secondary: PausaColors.red,
      surface: PausaColors.surface,
      error: PausaColors.red,
    ),
    textTheme: _textTheme,
    useMaterial3: true,
  );

  static TextTheme get _textTheme => TextTheme(
    // Display — DM Serif Display
    displayLarge: GoogleFonts.dmSerifDisplay(
      fontSize: 48,
      fontWeight: FontWeight.w400,
      color: PausaColors.textPrimary,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.dmSerifDisplay(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: PausaColors.textPrimary,
      height: 1.15,
    ),
    displaySmall: GoogleFonts.dmSerifDisplay(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: PausaColors.textPrimary,
      height: 1.2,
    ),

    // Headlines — DM Sans
    headlineLarge: GoogleFonts.dmSans(
      fontSize: 24,
      fontWeight: FontWeight.w300,
      color: PausaColors.textPrimary,
      letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.dmSans(
      fontSize: 20,
      fontWeight: FontWeight.w300,
      color: PausaColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: PausaColors.textPrimary,
    ),

    // Body — DM Sans
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: PausaColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: PausaColors.textSecondary,
      height: 1.6,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: PausaColors.textMuted,
      letterSpacing: 0.06,
    ),

    // Label — DM Sans uppercase
    labelLarge: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: PausaColors.textPrimary,
      letterSpacing: 0.08,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: PausaColors.textMuted,
      letterSpacing: 0.12,
    ),
  );
}
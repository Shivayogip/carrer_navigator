import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Coder's Palette
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color primaryNeon = Color(0xFF2EA44F); // Success Green
  static const Color secondaryBlue = Color(0xFF58A6FF); // Logic Blue
  static const Color accentPurple = Color(0xFFBC8CFF); // Syntax Purple
  static const Color borderSubtle = Color(0xFF30363D);
  static const Color textMain = Color(0xFFC9D1D9);
  static const Color textDim = Color(0xFF8B949E);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryBlue,
        surface: darkSurface,
        background: darkBg,
        error: Color(0xFFF85149),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textMain,
        onBackground: textMain,
      ),
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.jetBrainsMono(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.jetBrainsMono(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.jetBrainsMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: accentPurple,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textMain,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textDim,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: primaryNeon,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryNeon, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryNeon,
        foregroundColor: Colors.white,
      ),

      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 24,
      ),
    );
  }
}

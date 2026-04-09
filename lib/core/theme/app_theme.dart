import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color gold = Color(0xFFD4AF35);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color emerald = Color(0xFF064E3B);
  
  // Neutral Colors
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF252525);
  
  // Functional Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.emerald,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSurface: Colors.white,
      ),
      
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      
      // Component Themes
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
          letterSpacing: 2,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

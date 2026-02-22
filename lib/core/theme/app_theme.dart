import 'package:flutter/material.dart';

class AppColors {
  static const Color gold = Color(0xFFD4AF35);
  static const Color emerald = Color(0xFF064E3B);
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color cardGrey = Color(0xFF1A1A1A);
}

// Global Theme Data
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBg,
  primaryColor: AppColors.gold,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
  ),
);
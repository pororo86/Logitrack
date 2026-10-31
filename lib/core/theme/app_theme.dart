import 'package:flutter/material.dart';

class AppColors {
  // Diselaraskan dengan export Figma (Full UI Board).
  static const primary = Color(0xFF0D63FA);
  static const bg = Color(0xFFF5FAFF);
  static const text = Color(0xFF1B2437);
  static const muted = Color(0xFF7A869A);
  static const border = Color(0xFFE3E9F3);
  static const softBlue = Color(0xFFE3F0FF);
  static const success = Color(0xFF22A06B);
  static const softGreen = Color(0xFFE0F7E8);
  static const danger = Color(0xFFE5484D);
  static const softRed = Color(0xFFFDE8E8);
  static const warning = Color(0xFFF59E0B);
}

ThemeData buildAppTheme() {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.text,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary),
    ),
  );
}

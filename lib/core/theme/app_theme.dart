import 'package:flutter/material.dart';

class AppColors {
  // Palet sesuai desain Figma LogiTrack
  static const primary = Color(0xFF3478F6);
  static const secondary = Color(0xFF18A6A6);
  static const success = Color(0xFF20A36B);
  static const warning = Color(0xFFF3B84B);
  static const danger = Color(0xFFEF4444);
  static const text = Color(0xFF183153);
  static const bg = Color(0xFFF2F7FD);

  // Turunan (soft) untuk chip / badge
  static const muted = Color(0xFF6B7A90);
  static const border = Color(0xFFDCE6F3);
  static const softBlue = Color(0xFFE6EFFE);
  static const softGreen = Color(0xFFDDF4E8);
  static const softYellow = Color(0xFFFDF1D6);
  static const softRed = Color(0xFFFDE2E2);

  // Alias agar nama lama tetap jalan
  static const error = danger;
  static const surface = Colors.white;
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF0E110F);
  static const Color sidebar = Color(0xFF0A0C0B);
  static const Color surface = Color(0xFF181B19);
  static const Color surfaceHigh = Color(0xFF232724);
  static const Color accent = Color(0xFFA6F36B);
  static const Color text = Color(0xFFF2F4F1);
  static const Color muted = Color(0xFF9AA19B);
  static const Color outline = Color(0xFF2E332F);
  static const Color accentDisabled = Color(0x4DA6F36B);
  static const Color selectedTint = Color(0xFF1F3325);

  // Pre-baked translucent colors (avoids deprecated withOpacity).
  static const Color scrim = Color(0xB3000000);
  static const Color scrimSoft = Color(0x33000000);
  static const Color glow = Color(0x22FFFFFF);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.sidebar,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
        ),
      ),
    ),
  );
}

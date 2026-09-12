import 'package:flutter/material.dart';

class AresColors {
  static const Color background = Color(0xFF020B14);
  static const Color surface = Color(0xFF071728);
  static const Color primary = Color(0xFF00E5FF);
  static const Color primaryDark = Color(0xFF00B3CC);
  static const Color accent = Color(0xFF00E5FF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
}

class AresTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AresColors.background,
      primaryColor: AresColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AresColors.primary,
        surface: AresColors.surface,
      ),
    );
  }
}

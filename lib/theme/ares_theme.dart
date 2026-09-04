import 'package:flutter/material.dart';

class AresColors {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF4834D4);
  static const Color accent = Color(0xFF00D2D3);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B949E);
}

class AresTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AresColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AresColors.primary,
        surface: AresColors.surface,
      ),
    );
  }
}

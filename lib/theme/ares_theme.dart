import 'package:flutter/material.dart';

class AresColors {
  static const Color background = Color(0xFF0F172A); 
  static const Color surface = Color(0xFF1E293B);    
  static const Color primary = Color(0xFF6366F1);    
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF22D3EE);     
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class AresTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AresColors.background,
      cardColor: AresColors.surface,
      primaryColor: AresColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AresColors.primary,
        secondary: AresColors.accent,
        surface: AresColors.surface,
      ),
    );
  }
}

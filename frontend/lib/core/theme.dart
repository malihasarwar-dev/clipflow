import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the dark, glowing SaaS look.
class CF {
  static const bg = Color(0xFF07070D);
  static const surface = Color(0xFF11111B);
  static const violet = Color(0xFF7C3AED);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFEC4899);
  static const textDim = Color(0xFF9CA3B4);
  static const danger = Color(0xFFF87171);
  static const success = Color(0xFF34D399);

  static const brandGradient = LinearGradient(
    colors: [violet, Color(0xFF5B8CFF), cyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const hotGradient = LinearGradient(colors: [violet, pink]);

  static ThemeData theme() {
    final base = ThemeData.dark(useMaterial3: true);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: Colors.white, displayColor: Colors.white);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: text,
      colorScheme: const ColorScheme.dark(primary: violet, secondary: cyan, surface: surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        hintStyle: const TextStyle(color: textDim),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: cyan, width: 1.4)),
      ),
    );
  }
}

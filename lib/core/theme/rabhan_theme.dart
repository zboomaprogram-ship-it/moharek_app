import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';

class RabhanThemeData {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RabhanTheme.background,
      primaryColor: RabhanTheme.primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: RabhanTheme.primaryGreen,
        secondary: RabhanTheme.gold,
        surface: RabhanTheme.card,
        background: RabhanTheme.background,
        error: RabhanTheme.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: RabhanTheme.textPrimary,
        onBackground: RabhanTheme.textPrimary,
        onError: Colors.white,
      ),
      textTheme:
          GoogleFonts.cairoTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).apply(
            bodyColor: RabhanTheme.textPrimary,
            displayColor: RabhanTheme.textPrimary,
          ),
      cardTheme: CardThemeData(
        color: RabhanTheme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: RabhanTheme.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: RabhanTheme.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RabhanTheme.primaryGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF080B12);
  static const Color cardColor = Color(0xFF111827);
  static const Color primaryGreen = Color(0xFF2EE59D);
  static const Color primaryBlue = Color(0xFF3B82F6);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final cairoTextTheme = GoogleFonts.cairoTextTheme(base.textTheme);

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: primaryBlue,
        surface: cardColor,
        background: background,
      ),
      textTheme: cairoTextTheme
          .apply(bodyColor: Colors.white, displayColor: Colors.white)
          .copyWith(
            bodyLarge: cairoTextTheme.bodyLarge?.copyWith(height: 1.6),
            bodyMedium: cairoTextTheme.bodyMedium?.copyWith(height: 1.6),
          ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: primaryGreen.withValues(alpha: 0.1),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return GoogleFonts.cairo(
              color: primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }
          return GoogleFonts.cairo(color: Colors.grey, fontSize: 11);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: Colors.grey, size: 24);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: GoogleFonts.cairo(color: Colors.grey),
        hintStyle: GoogleFonts.cairo(color: Colors.grey),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primaryGreen,
        labelColor: primaryGreen,
        unselectedLabelColor: Colors.grey,
      ),
    );
  }
}

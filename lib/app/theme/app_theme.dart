import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF00796B); // Teal 700 (Hijau Desa)
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // Soft White
  static const Color errorColor = Color(0xFFD32F2F); // Red 700

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // Almost Black
  static const Color textSecondary = Color(0xFF424242); // Dark Grey

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: primaryColor,
        secondary: primaryColor,
        error: errorColor,
      ),

      // 1. Typography & Readability
      textTheme: TextTheme(
        // Headlines
        headlineSmall: GoogleFonts.lato(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.lato(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        // Body
        bodyLarge: GoogleFonts.lato(
          fontSize: 18.0, // Large body text
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 16.0, // Standard body text (min 16)
          color: textSecondary,
        ),
        // Subtitles/Captions
        bodySmall: GoogleFonts.lato(
          fontSize: 14.0, // Min 14 for smallest text
          color: textSecondary,
        ),
        // Button Text
        labelLarge: GoogleFonts.lato(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // 2. Interactive Elements (Buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50.0), // Min height 50
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // 3. Input Fields (High Contrast)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.grey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.lato(fontSize: 16.0, color: textSecondary),
        hintStyle: GoogleFonts.lato(fontSize: 16.0, color: Colors.grey[600]),
      ),

      // 4. Cards
      // 4. Cards
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // 5. AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 28.0, // Larger icons
        ),
      ),

      // 6. Icons
      iconTheme: const IconThemeData(size: 28.0, color: textPrimary),
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {

  // AKOP Ana Renkleri
  static const Color primaryColor = Color(0xFF162F49);
  static const Color backgroundColor = Color(0xFFF6FAFD);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Yardımcı Renkler
  static const Color secondaryColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE5EDF0);

  // Durum Renkleri
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF16A34A);
  static const Color errorColor = Color(0xFFDC2626);

  // Açık Tema
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Renk Sistemi
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        surface: cardColor,
        error: errorColor,
      ),

      // Genel Arka Plan
      scaffoldBackgroundColor: backgroundColor,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),

      // Kartlar
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: borderColor,
          ),
        ),
      ),

      // Butonlar
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // Metin Kutuları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRose = Color(0xFFFF3A70);
  static const Color darkRose = Color(0xFFCF4067);
  static const Color softPink = Color(0xFFFFF0F4);
  static const Color pinkCard = Color(0xFFFCE4EC);
  static const Color lightPink = Color(0xFFFFD6E4);
  static const Color cream = Color(0xFFFFF8F2);
  static const Color text = Color(0xFF5A3E48);
  static const Color muted = Color(0xFF8D6A75);
  static const Color goldAccent = Color(0xFFC9965B);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRose,
        primary: primaryRose,
        secondary: darkRose,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: cream,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: text,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryRose,
        unselectedItemColor: muted,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
      ),
    );
  }
}

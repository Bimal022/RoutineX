import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF4F46E5);
  static const secondary = Color(0xFF06B6D4);
  static const background = Color(0xFFF5F7FB);
  static const card = Colors.white;

  static ThemeData lightTheme = ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}
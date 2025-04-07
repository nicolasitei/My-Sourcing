
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF0085AF),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  fontFamily: 'Open Sans',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.black,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF0085AF)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF0085AF), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0085AF),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF0085AF),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF0085AF),
      side: const BorderSide(color: Color(0xFF0085AF)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF0085AF),
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
    displaySmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
    headlineMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
    headlineSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
    bodyMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    bodySmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
    labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
    labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    labelSmall: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
  ),
);

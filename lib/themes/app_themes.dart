import 'package:flutter/material.dart';

class AppThemes {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1976D2),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1976D2),
      secondary: Color(0xFF388E3C),
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
      bodyMedium: TextStyle(fontSize: 12, color: Colors.grey),
      bodySmall: TextStyle(fontSize: 10, color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.grey),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.red,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    primaryColor: const Color(0xFF42A5F5),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5),
      secondary: Color(0xFF66BB6A),
      surface: Colors.grey,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 12, color: Colors.grey),
      bodySmall: TextStyle(fontSize: 10, color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.black,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.red,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
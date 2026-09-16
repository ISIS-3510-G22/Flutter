import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const coral = Color(0xFFFF6B4A);
  static const black = Color(0xFF000000);
  static const greyDark = Color(0xFF4A4A4A);
  static const greyLight = Color(0xFFE5E5E5);
  static const white = Color(0xFFFFFFFF);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: coral,
      onPrimary: white,
      surface: white,
      onSurface: black,
      onSurfaceVariant: greyDark,
      outline: greyLight,
      surfaceContainerHighest: greyLight,
    ),
    scaffoldBackgroundColor: white,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: black),
      labelLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}
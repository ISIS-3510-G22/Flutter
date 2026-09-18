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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: white,
      indicatorColor: coral.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? coral : greyDark);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? coral : greyDark,
        );
      }),
    ),
  );
}

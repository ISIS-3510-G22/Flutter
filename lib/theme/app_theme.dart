import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const coral = Color(0xFFFF6B4A);
  static const black = Color(0xFF000000);
  static const greyDark = Color(0xFF4A4A4A);
  static const greyLight = Color(0xFFE5E5E5);
  static const white = Color(0xFFFFFFFF);

  static final light = _build(
    const ColorScheme.light(
      primary: coral,
      onPrimary: white,
      surface: white,
      onSurface: black,
      onSurfaceVariant: greyDark,
      outline: greyLight,
      surfaceContainerHighest: greyLight,
      secondaryContainer: Color(0xFFFFF0EC),
      onSecondaryContainer: black,
    ),
  );

  static final dark = _build(
    const ColorScheme.dark(
      primary: coral,
      onPrimary: white,
      surface: Color(0xFF121212),
      onSurface: white,
      onSurfaceVariant: Color(0xFFB3B3B3),
      outline: greyDark,
      surfaceContainerHighest: Color(0xFF2C2C2C),
      surfaceContainerLow: Color(0xFF1E1E1E),
      secondaryContainer: Color(0xFF592D23),
      onSecondaryContainer: white,
    ),
  );

  static ThemeData _build(ColorScheme c) => ThemeData(
    useMaterial3: true,
    colorScheme: c,
    scaffoldBackgroundColor: c.surface,
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: c.onSurface,
      ),
      labelLarge: TextStyle(fontWeight: FontWeight.bold),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primary.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? c.primary : c.onSurfaceVariant);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? c.primary : c.onSurfaceVariant,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.surface
            : c.onSurfaceVariant,
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: c.primary,
      checkmarkColor: c.onPrimary,
      side: BorderSide(color: c.outline),
      labelStyle: TextStyle(
        color: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onPrimary : c.onSurface,
        ),
      ),
    ),
  );
}

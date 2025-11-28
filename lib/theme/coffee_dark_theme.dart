import 'package:flutter/material.dart';

ThemeData coffeeDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1B1512),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFFC8A27A), // Light coffee
    secondary: const Color(0xFFD3B08F), // Caramel
    surface: const Color(0xFF2A221E),
    onPrimary: Colors.black,
    onSurface: Colors.white,
  ),
  cardColor: const Color(0xFF2A221E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1B1512),
    foregroundColor: Color(0xFFC8A27A),
    elevation: 0,
  ),
);

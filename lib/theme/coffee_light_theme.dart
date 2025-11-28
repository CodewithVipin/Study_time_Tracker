import 'package:flutter/material.dart';

ThemeData coffeeLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4EFE7),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF6F4E37), // Coffee brown
    secondary: const Color(0xFFA97458), // Mocha
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Colors.black,
  ),
  cardColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF4EFE7),
    elevation: 0,
    foregroundColor: Color(0xFF6F4E37),
  ),
);

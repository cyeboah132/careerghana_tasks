import 'package:flutter/material.dart';

const kBg = Color(0xFF0E0E0E);
const kSurface = Color(0xFF1A1A1A);
const kMuted = Color(0xFF9A9A9A);
const kAccent = Color(0xFF4DB6AC); // one calm accent, used sparingly

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(primary: kAccent, surface: kSurface),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBg,
    elevation: 0,
    foregroundColor: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
    bodyLarge: TextStyle(color: Colors.white),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurface,
    labelStyle: const TextStyle(color: kMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAccent,
      foregroundColor: Colors.black,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

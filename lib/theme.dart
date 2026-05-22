import 'package:flutter/material.dart';

const Color kInk = Color(0xFF070B1D);
const Color kPanel = Color(0xFF101735);
const Color kPanelSoft = Color(0xFF18214B);
const Color kGlowBlue = Color(0xFF3DDCFF);
const Color kGlowPink = Color(0xFFFF4FD8);
const Color kGold = Color(0xFFFFD05A);
const Color kSafeGreen = Color(0xFF49E68B);
const Color kDangerRed = Color(0xFFFF5A6E);

ThemeData buildPaveTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kGlowBlue,
    brightness: Brightness.dark,
    surface: kPanel,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kInk,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0),
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
      bodyMedium: TextStyle(height: 1.25),
    ),
  );
}

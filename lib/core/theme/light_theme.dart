import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFF6C000),
    primary: const Color(0xFFF6C000),
    onPrimary: const Color(0xFF121212),
    secondary: const Color(0xFF121212),
    onSecondary: Colors.white,
    surface: const Color(0xFFFFFDF7),
    onSurface: const Color(0xFF121212),
    error: const Color(0xFFF44336),
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFFFFDF7),
  brightness: Brightness.light,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.2),
    bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w500),
    bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFDF7),
    foregroundColor: Color(0xFF121212),
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.04),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEAE5DD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF121212), width: 1.5),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF6C000),
      foregroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF121212),
      side: const BorderSide(color: Color(0xFFEAE5DD), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF121212),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
);

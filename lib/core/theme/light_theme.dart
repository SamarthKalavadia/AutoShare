import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF084E31),
    primary: const Color(0xFF084E31),
    onPrimary: Colors.white,
    secondary: const Color(0xFFE5A93C),
    onSecondary: Colors.white,
    primaryContainer: const Color(0xFFE8F5EE),
    onPrimaryContainer: const Color(0xFF084E31),
    surface: Colors.white,
    onSurface: const Color(0xFF0F1713),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAF9),
    surfaceContainer: const Color(0xFFF0F4F2),
    surfaceContainerHighest: const Color(0xFFE5ECE8),
    outline: const Color(0xFFD4DFDA),
    error: const Color(0xFFE53935),
    onError: Colors.white,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF6F9F7),
  brightness: Brightness.light,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: const Color(0xFF0F1713),
    ),
    headlineMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: const Color(0xFF0F1713),
    ),
    titleLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: const Color(0xFF0F1713),
    ),
    titleMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: const Color(0xFF0F1713),
    ),
    bodyLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w500,
      color: const Color(0xFF0F1713),
    ),
    bodyMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      color: const Color(0xFF6B7E75),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF0F1713),
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
    elevation: 2,
    shadowColor: Colors.black.withValues(alpha: 0.04),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3EBE6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF084E31), width: 1.5),
    ),
    filled: true,
    fillColor: const Color(0xFFF5F7F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF084E31),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF084E31),
      side: const BorderSide(color: Color(0xFFC4E3D4), width: 1.5),
      backgroundColor: const Color(0xFFF0F7F4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF084E31),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
);

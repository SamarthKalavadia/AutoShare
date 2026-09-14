import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF10B981),
    primary: const Color(0xFF10B981),
    onPrimary: const Color(0xFF06281C),
    secondary: const Color(0xFFE5A93C),
    onSecondary: const Color(0xFF121212),
    primaryContainer: const Color(0xFF1A382B),
    onPrimaryContainer: const Color(0xFFA7F3D0),
    surface: const Color(0xFF18221D),
    onSurface: const Color(0xFFFFFFFF),
    surfaceContainerLowest: const Color(0xFF101714),
    surfaceContainerLow: const Color(0xFF141D18),
    surfaceContainer: const Color(0xFF1E2B25),
    surfaceContainerHigh: const Color(0xFF26362F),
    surfaceContainerHighest: const Color(0xFF2E4038),
    outline: const Color(0xFF374B42),
    error: const Color(0xFFEF5350),
    onError: Colors.white,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF101714),
  brightness: Brightness.dark,
  textTheme:
      GoogleFonts.interTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          color: const Color(0xFFA0B2AA),
        ),
      ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF18221D),
    selectedItemColor: Color(0xFF10B981),
    unselectedItemColor: Color(0xFF768E82),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF18221D),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: const Color(0xFF18221D),
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF18221D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF2D3F37)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
    ),
    filled: true,
    fillColor: const Color(0xFF1E2B25),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF10B981),
      foregroundColor: const Color(0xFF06281C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFA7F3D0),
      side: const BorderSide(color: Color(0xFF374B42), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF10B981),
      foregroundColor: const Color(0xFF06281C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
    ),
  ),
);

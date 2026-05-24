import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hanken Grotesk type scale, sizes taken from DESIGN.md `typography`.
class AppTypography {
  const AppTypography._();

  static TextStyle display(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 32,
        height: 1.2,
        letterSpacing: -0.64,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle headlineLg(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 24,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: c,
      );

  static TextStyle headlineMd(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: c,
      );

  static TextStyle bodyLg(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle bodyMd(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle labelCaps(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        height: 1,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
        color: c,
      );

  static TextStyle labelSm(Color c) => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w500,
        color: c,
      );
}

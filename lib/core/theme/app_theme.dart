import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_accent.dart';
import 'app_colors.dart';

/// Builds light/dark [ThemeData] from the [AppColors] tokens.
/// Radius language from DESIGN.md: cards 12px, inputs 10px, pills full.
class AppTheme {
  const AppTheme._();

  static ThemeData light(AppAccent accent) {
    final p = accent.palette;
    final c = AppColors.light
        .copyWith(primary: p.lightPrimary, onPrimary: p.lightOnPrimary);
    return _build(c, Brightness.light);
  }

  static ThemeData dark(AppAccent accent) {
    final p = accent.palette;
    final c = AppColors.dark
        .copyWith(primary: p.darkPrimary, onPrimary: p.darkOnPrimary);
    return _build(c, Brightness.dark);
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        surface: c.surface,
        onSurface: c.onSurface,
        error: c.error,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: GoogleFonts.hankenGroteskTextTheme(base.textTheme).apply(
        bodyColor: c.onSurface,
        displayColor: c.onSurface,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: c.primary,
        inactiveTrackColor: c.outlineVariant,
        thumbColor: c.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        overlayColor: c.primary.withOpacity(0.15),
      ),
      splashColor: c.primary.withOpacity(0.08),
      highlightColor: c.primary.withOpacity(0.04),
    );
  }
}

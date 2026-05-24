import 'package:flutter/material.dart';

/// Accent presets the user can pick from Settings. Each preset supplies a
/// `primary` color for both light and dark variants — surfaces and text
/// remain locked to the project's neutral palette in [AppColors].
enum AppAccent { indigo, teal, rose, amber, emerald, slate }

class AccentPalette {
  const AccentPalette({
    required this.lightPrimary,
    required this.lightOnPrimary,
    required this.darkPrimary,
    required this.darkOnPrimary,
  });
  final Color lightPrimary;
  final Color lightOnPrimary;
  final Color darkPrimary;
  final Color darkOnPrimary;
}

const Map<AppAccent, AccentPalette> kAccentPalettes = {
  // Default — matches the original "Mindful Equilibrium" palette.
  AppAccent.indigo: AccentPalette(
    lightPrimary: Color(0xFF4F378A),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF8B8BF0),
    darkOnPrimary: Color(0xFF121212),
  ),
  AppAccent.teal: AccentPalette(
    lightPrimary: Color(0xFF00796B),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF4DD0E1),
    darkOnPrimary: Color(0xFF002B30),
  ),
  AppAccent.rose: AccentPalette(
    lightPrimary: Color(0xFFB91C5C),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFF472B6),
    darkOnPrimary: Color(0xFF3F0719),
  ),
  AppAccent.amber: AccentPalette(
    lightPrimary: Color(0xFFB45309),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFFF59E0B),
    darkOnPrimary: Color(0xFF1A0F00),
  ),
  AppAccent.emerald: AccentPalette(
    lightPrimary: Color(0xFF047857),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF34D399),
    darkOnPrimary: Color(0xFF002A1B),
  ),
  AppAccent.slate: AccentPalette(
    lightPrimary: Color(0xFF334155),
    lightOnPrimary: Color(0xFFFFFFFF),
    darkPrimary: Color(0xFF94A3B8),
    darkOnPrimary: Color(0xFF0F172A),
  ),
};

extension AppAccentX on AppAccent {
  AccentPalette get palette => kAccentPalettes[this]!;

  static AppAccent fromCode(String? code) =>
      AppAccent.values.firstWhere((a) => a.name == code,
          orElse: () => AppAccent.indigo);

  String get tKey => 'settings.accent.$name';
}

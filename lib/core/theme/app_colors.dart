import 'package:flutter/material.dart';

/// Design tokens ported verbatim from DESIGN.md / the Stitch HTML mockups.
/// Exposed as a [ThemeExtension] so widgets read colors via
/// `context.colors` instead of hardcoding hex values (keeps View dumb).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.tertiary,
    required this.error,
    required this.errorContainer,
    required this.positive,
    required this.negative,
  });

  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color tertiary;
  final Color error;
  final Color errorContainer;
  final Color positive;
  final Color negative;

  // Dark theme — from the HTML tailwind.config (#121212 canvas, #8B8BF0 accent).
  static const AppColors dark = AppColors(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceContainer: Color(0xFF2A2A2A),
    surfaceContainerLow: Color(0xFF232323),
    surfaceContainerHigh: Color(0xFF333333),
    onSurface: Color(0xFFECECEC),
    onSurfaceVariant: Color(0xFFC4C4C4),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    primary: Color(0xFF8B8BF0),
    onPrimary: Color(0xFF121212),
    secondary: Color(0xFFCDC0E9),
    tertiary: Color(0xFFE7C365),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    positive: Color(0xFF34D399),
    negative: Color(0xFFEF4444),
  );

  // Light theme — from DESIGN.md frontmatter (Mindful Equilibrium).
  static const AppColors light = AppColors(
    background: Color(0xFFFDF7FF),
    surface: Color(0xFFFDF7FF),
    surfaceContainer: Color(0xFFF2ECF4),
    surfaceContainerLow: Color(0xFFF8F2FA),
    surfaceContainerHigh: Color(0xFFECE6EE),
    onSurface: Color(0xFF1D1B20),
    onSurfaceVariant: Color(0xFF494551),
    outline: Color(0xFF7A7582),
    outlineVariant: Color(0xFFCBC4D2),
    primary: Color(0xFF4F378A),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF63597C),
    tertiary: Color(0xFF765B00),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    positive: Color(0xFF1D9E75),
    negative: Color(0xFFD85A30),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerHigh,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? tertiary,
    Color? error,
    Color? errorContainer,
    Color? positive,
    Color? negative,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

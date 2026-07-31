import 'package:flutter/material.dart';

/// Semantic colour palette for Vynqix.
///
/// The token names and values are the single source of truth for the whole
/// app — widgets should never hard-code a hex value. Read them through
/// `Theme.of(context).extension<AppColors>()!` or the `context.colors`
/// shorthand in `core/extensions/context_x.dart`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.foreground,
    required this.muted,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.overlay,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color foreground;
  final Color muted;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color overlay;

  static const light = AppColors(
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF6366F1),
    accent: Color(0xFF8B5CF6),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F5F9),
    foreground: Color(0xFF111827),
    muted: Color(0xFF6B7280),
    border: Color(0xFFE5E7EB),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    overlay: Color(0x66000000),
  );

  static const dark = AppColors(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF818CF8),
    accent: Color(0xFFA78BFA),
    background: Color(0xFF0F1117),
    surface: Color(0xFF1A1D27),
    surfaceAlt: Color(0xFF242736),
    foreground: Color(0xFFF1F5F9),
    muted: Color(0xFF9CA3AF),
    border: Color(0xFF2D3148),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    overlay: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? foreground,
    Color? muted,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? overlay,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}

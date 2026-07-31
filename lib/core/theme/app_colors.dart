import 'package:flutter/material.dart';

/// Semantic colour palette for Vynqix.
///
/// The app is light-only by design, so every value here is tuned for dark
/// text on white surfaces. Notably, `success`, `warning` and `error` are
/// deeper than their usual Tailwind-style equivalents — the lighter shades
/// fail contrast when used as text or small icons on white.
///
/// Widgets should never hard-code a hex value. Read tokens through
/// `context.colors` (see `core/extensions/context_x.dart`).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.foreground,
    required this.muted,
    required this.faint,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.overlay,
  });

  /// Brand indigo. Buttons, checkboxes, selected states, progress.
  final Color primary;

  /// Tinted primary for selected-row and indicator backgrounds.
  final Color primarySoft;

  final Color secondary;
  final Color accent;

  /// Page background — a hint off-white so white cards read as raised.
  final Color background;

  /// Cards, sheets, app bar, nav bar.
  final Color surface;

  /// Inputs and inert fills.
  final Color surfaceAlt;

  /// Primary text. 15.8:1 on [surface].
  final Color foreground;

  /// Secondary text and icons. 5.1:1 on [surface] — passes AA for body text.
  final Color muted;

  /// Disabled text and inactive glyphs. Decorative use only; too low for
  /// anything the user must read.
  final Color faint;

  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color overlay;

  static const light = AppColors(
    primary: Color(0xFF4F46E5),
    primarySoft: Color(0xFFEEF0FE),
    secondary: Color(0xFF6366F1),
    accent: Color(0xFF7C3AED),
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F3F7),
    foreground: Color(0xFF1A1D26),
    muted: Color(0xFF6B7280),
    faint: Color(0xFFA1A7B3),
    border: Color(0xFFE4E7EC),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    error: Color(0xFFDC2626),
    overlay: Color(0x591A1D26),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? foreground,
    Color? muted,
    Color? faint,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
    Color? overlay,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
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
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}

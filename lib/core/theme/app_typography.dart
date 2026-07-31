import 'package:flutter/material.dart';

/// Typography scale from `design.md`.
///
/// Sizes are expressed in logical pixels and map 1:1 onto the design table so
/// that a designer reading the spec can find the matching style here.
abstract final class AppTypography {
  static const _family = null; // Use the platform default (SF Pro / Roboto).

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.6,
  );

  static const titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  );

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.2,
  );

  /// Tabular figures for timers and counters so digits do not jitter.
  static const timer = TextStyle(
    fontFamily: _family,
    fontSize: 64,
    fontWeight: FontWeight.w200,
    height: 1.0,
    letterSpacing: -2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextTheme textTheme(Color foreground, Color muted) {
    return TextTheme(
      displayLarge: display.copyWith(color: foreground),
      displayMedium: titleLarge.copyWith(color: foreground),
      titleLarge: titleLarge.copyWith(color: foreground),
      titleMedium: title.copyWith(color: foreground),
      titleSmall: subtitle.copyWith(color: foreground),
      bodyLarge: body.copyWith(color: foreground),
      bodyMedium: bodySmall.copyWith(color: foreground),
      bodySmall: caption.copyWith(color: muted),
      labelLarge: subtitle.copyWith(color: foreground),
      labelMedium: bodySmall.copyWith(color: muted),
      labelSmall: caption.copyWith(color: muted),
    );
  }
}

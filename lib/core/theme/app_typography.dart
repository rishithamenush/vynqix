import 'package:flutter/material.dart';

/// Typography scale, set in Inter.
///
/// Inter is the de-facto face for productivity apps — it was drawn for UI at
/// small sizes, so counters stay open and `1/l/I` stay distinct in a dense
/// task list, which the platform defaults do less well.
///
/// Sizes track the scale in `design.md`; the negative letter-spacing on
/// larger sizes is Inter's own optical correction, without which headings
/// look loose.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.7,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    height: 1.26,
    letterSpacing: -0.5,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
  );

  /// Task titles and body copy.
  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  /// Tabular figures so a running countdown does not jitter.
  static const timer = TextStyle(
    fontFamily: fontFamily,
    fontSize: 62,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: -2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Numbers in stat tiles and charts.
  static const numeric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
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

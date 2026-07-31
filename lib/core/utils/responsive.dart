import 'package:flutter/widgets.dart';

/// Layout breakpoints, following Material 3's window size classes.
///
/// The cutoffs are deliberately based on *width* only. Height varies far more
/// (keyboards, notches, split-screen) and is a poor signal for how a layout
/// should be arranged.
abstract final class Breakpoints {
  /// Phones in portrait, and small phones in landscape.
  static const compact = 600.0;

  /// Large phones in landscape, small tablets.
  static const medium = 840.0;

  /// Tablets and desktop windows.
  static const expanded = 1200.0;

  /// Widest a column of text or a form should ever get.
  ///
  /// Beyond roughly this width, lines get long enough that the eye loses its
  /// place returning to the next line, so content is centred instead of
  /// stretched.
  static const readableContent = 640.0;

  /// Cap for list-style screens, which tolerate a little more width than
  /// prose because each row is short.
  static const listContent = 760.0;
}

enum WindowSize {
  /// < 600dp. Bottom navigation, single column, full-bleed content.
  compact,

  /// 600–839dp. Side rail, content starts to be centred.
  medium,

  /// >= 840dp. Side rail with labels, multi-column grids.
  expanded,
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  WindowSize get windowSize {
    final width = screenWidth;
    if (width < Breakpoints.compact) return WindowSize.compact;
    if (width < Breakpoints.medium) return WindowSize.medium;
    return WindowSize.expanded;
  }

  bool get isCompact => windowSize == WindowSize.compact;

  bool get isMedium => windowSize == WindowSize.medium;

  bool get isExpanded => windowSize == WindowSize.expanded;

  /// True once there is room for a side rail instead of a bottom bar.
  bool get useSideNav => !isCompact;

  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True on genuinely small phones (iPhone SE and similar), where fixed
  /// paddings and font sizes need to give a little.
  bool get isSmallPhone => screenWidth < 360;

  /// Short viewports — usually a phone in landscape — where tall hero
  /// elements have to shrink or the content will not fit.
  bool get isShort => screenHeight < 620;

  /// Picks a value for the current window size, falling back down the scale
  /// when a larger size is not supplied.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    return switch (windowSize) {
      WindowSize.compact => compact,
      WindowSize.medium => medium ?? compact,
      WindowSize.expanded => expanded ?? medium ?? compact,
    };
  }

  /// Horizontal screen gutter, which grows a little with the window.
  double get gutter => responsive(
    compact: isSmallPhone ? 16.0 : 20.0,
    medium: 24.0,
    expanded: 32.0,
  );

  /// Columns for a stat/tile grid at this width.
  int get statColumns => responsive(compact: 2, medium: 3, expanded: 4);
}

import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Centres and width-caps a screen's content.
///
/// On a phone this is a no-op beyond the gutter. On a tablet or in landscape
/// it stops a task list from stretching into 1000dp-wide rows, which is the
/// single biggest thing that makes a phone layout look broken on a big
/// screen.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.applyGutter = true,
  });

  final Widget child;

  /// Defaults to [Breakpoints.listContent]. Use
  /// [Breakpoints.readableContent] for prose and forms.
  final double? maxWidth;

  /// Set false when the child already handles its own horizontal padding
  /// (a `ListView` with its own `padding`, for example).
  final bool applyGutter;

  @override
  Widget build(BuildContext context) {
    final cap = maxWidth ?? Breakpoints.listContent;
    final gutter = applyGutter ? context.gutter : 0.0;

    // Centring with `Align` would make this fill the height it is *offered*,
    // which breaks any caller that expects the child's own height: a
    // `bottomNavigationBar` is measured against the full screen height, and a
    // `Column` child is measured with no height bound at all. Turning the
    // leftover width into padding leaves the vertical constraints — min and
    // max — exactly as they arrived.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inset = width.isFinite && width > cap ? (width - cap) / 2 : 0.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: inset + gutter),
          child: child,
        );
      },
    );
  }
}

/// Sliver equivalent of [PageBody], for `CustomScrollView` screens.
class SliverPageBody extends StatelessWidget {
  const SliverPageBody({super.key, required this.sliver, this.maxWidth});

  final Widget sliver;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    final cap = maxWidth ?? Breakpoints.listContent;
    // Convert the leftover width into symmetric padding, which is the only
    // way to centre a sliver without wrapping the whole scroll view.
    final inset = width > cap ? (width - cap) / 2 : 0.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: sliver,
    );
  }
}

/// Padding that adapts its horizontal gutter to the window size.
class GutterPadding extends StatelessWidget {
  const GutterPadding({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.gutter, top, context.gutter, bottom),
      child: child,
    );
  }
}

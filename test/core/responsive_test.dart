import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/responsive.dart';

/// Renders a probe at a given logical size and hands back its BuildContext,
/// so breakpoint behaviour can be asserted without booting the whole app.
Future<BuildContext> contextAtSize(WidgetTester tester, Size size) async {
  late BuildContext captured;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('window size classes', () {
    testWidgets('a phone in portrait is compact', (tester) async {
      final context = await contextAtSize(tester, const Size(390, 844));

      expect(context.windowSize, WindowSize.compact);
      expect(context.isCompact, isTrue);
      expect(context.useSideNav, isFalse, reason: 'phones keep a bottom bar');
    });

    testWidgets('a small phone is flagged for tighter spacing', (
      tester,
    ) async {
      final context = await contextAtSize(tester, const Size(320, 568));

      expect(context.isSmallPhone, isTrue);
      expect(context.gutter, lessThan(20));
      expect(context.isShort, isTrue);
    });

    testWidgets('a phone in landscape is short and wide enough for the rail', (
      tester,
    ) async {
      final context = await contextAtSize(tester, const Size(844, 390));

      expect(context.isShort, isTrue, reason: '390dp tall is short');
      // 844dp wide crosses into expanded, so the rail takes over.
      expect(context.useSideNav, isTrue);
    });

    testWidgets('a small tablet is medium and uses the side rail', (
      tester,
    ) async {
      final context = await contextAtSize(tester, const Size(768, 1024));

      expect(context.windowSize, WindowSize.medium);
      expect(context.useSideNav, isTrue);
      expect(context.isExpanded, isFalse);
    });

    testWidgets('a large tablet is expanded', (tester) async {
      final context = await contextAtSize(tester, const Size(1280, 800));

      expect(context.windowSize, WindowSize.expanded);
      expect(context.isExpanded, isTrue);
      expect(context.statColumns, 4);
    });

    testWidgets('the 600dp boundary belongs to medium', (tester) async {
      final context = await contextAtSize(tester, const Size(600, 900));

      expect(context.windowSize, WindowSize.medium);
    });
  });

  group('responsive values', () {
    testWidgets('falls back down the scale when a size is omitted', (
      tester,
    ) async {
      final context = await contextAtSize(tester, const Size(1280, 800));

      // Only `compact` supplied, so expanded resolves to it.
      expect(context.responsive(compact: 'a'), 'a');
      // `medium` supplied but not `expanded`, so expanded falls back.
      expect(context.responsive(compact: 'a', medium: 'b'), 'b');
      expect(
        context.responsive(compact: 'a', medium: 'b', expanded: 'c'),
        'c',
      );
    });

    testWidgets('gutters and columns grow with the window', (tester) async {
      final phone = await contextAtSize(tester, const Size(390, 844));
      final phoneGutter = phone.gutter;
      final phoneColumns = phone.statColumns;

      final tablet = await contextAtSize(tester, const Size(1280, 800));

      expect(tablet.gutter, greaterThan(phoneGutter));
      expect(tablet.statColumns, greaterThan(phoneColumns));
    });
  });
}

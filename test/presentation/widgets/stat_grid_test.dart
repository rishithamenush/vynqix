import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/presentation/widgets/common.dart';

const _tiles = [
  StatTile(
    value: '128',
    label: 'Tasks completed',
    icon: Icons.check_circle_outline_rounded,
  ),
  StatTile(
    value: '12',
    label: 'Longest streak',
    icon: Icons.local_fire_department_outlined,
  ),
  StatTile(value: '4h 20m', label: 'Time focused', icon: Icons.timer_outlined),
  StatTile(
    value: '3',
    label: 'Perfect days',
    icon: Icons.auto_awesome_outlined,
  ),
];

Future<void> pumpGrid(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: StatGrid(children: _tiles),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('StatGrid', () {
    testWidgets('does not overflow on a small phone at a large text size', (
      tester,
    ) async {
      await pumpGrid(tester, size: const Size(320, 568), textScale: 1.6);

      // A fixed childAspectRatio clipped the label here — "BOTTOM OVERFLOWED
      // BY N PIXELS" surfaces as an exception in tests.
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays four tiles out in two rows on a phone', (tester) async {
      await pumpGrid(tester, size: const Size(390, 844));

      final rects = tester
          .widgetList<StatTile>(find.byType(StatTile))
          .map((tile) => tester.getRect(find.byWidget(tile)))
          .toList();

      expect(rects, hasLength(4));
      expect(rects[0].top, rects[1].top, reason: 'first row shares a top');
      expect(rects[2].top, greaterThan(rects[0].bottom));
      expect(rects[0].width, closeTo(rects[1].width, 0.5));
    });

    testWidgets('tiles in a row share the tallest tile height', (tester) async {
      await pumpGrid(tester, size: const Size(320, 568), textScale: 1.4);

      final rects = tester
          .widgetList<StatTile>(find.byType(StatTile))
          .map((tile) => tester.getRect(find.byWidget(tile)))
          .toList();

      expect(rects[0].height, closeTo(rects[1].height, 0.5));
      expect(rects[2].height, closeTo(rects[3].height, 0.5));
    });

    testWidgets('widens to four columns on a large tablet', (tester) async {
      await pumpGrid(tester, size: const Size(1280, 800));

      final rects = tester
          .widgetList<StatTile>(find.byType(StatTile))
          .map((tile) => tester.getRect(find.byWidget(tile)))
          .toList();

      expect(rects.every((r) => r.top == rects.first.top), isTrue);
    });
  });
}

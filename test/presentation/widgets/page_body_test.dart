import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/responsive.dart';
import 'package:vynqix/presentation/widgets/page_body.dart';

Future<void> pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  group('PageBody', () {
    testWidgets('takes only the height it needs in a bottom bar', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const Size(390, 844),
        Scaffold(
          body: ListView(children: const [SizedBox(height: 2000)]),
          bottomNavigationBar: PageBody(
            maxWidth: Breakpoints.readableContent,
            child: FilledButton(
              onPressed: () {},
              child: const Text('Continue'),
            ),
          ),
        ),
      );

      // A bar that fills the window would push the body off screen — the bug
      // this guards against.
      final bar = tester.getRect(find.byType(PageBody));
      expect(bar.height, lessThan(120));
      expect(bar.bottom, closeTo(844, 0.5));
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(600));
    });

    testWidgets('shrink-wraps inside a Column', (tester) async {
      await pumpAt(
        tester,
        const Size(390, 844),
        Scaffold(
          body: Column(
            children: [
              const PageBody(child: SizedBox(height: 40)),
              Expanded(child: Container(color: const Color(0xFF000000))),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PageBody)).height, 40);
    });

    testWidgets('caps and centres its content on a wide window', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const Size(1280, 800),
        Scaffold(
          body: PageBody(
            maxWidth: Breakpoints.readableContent,
            applyGutter: false,
            child: Container(key: const Key('content'), color: Colors.red),
          ),
        ),
      );

      final content = tester.getRect(find.byKey(const Key('content')));
      expect(content.width, Breakpoints.readableContent);
      expect(content.center.dx, closeTo(640, 0.5));
    });

    testWidgets('keeps a minimum height handed down by the parent', (
      tester,
    ) async {
      await pumpAt(
        tester,
        const Size(390, 844),
        Scaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 844),
              child: const PageBody(child: SizedBox.shrink()),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(PageBody)).height, 844);
    });
  });
}

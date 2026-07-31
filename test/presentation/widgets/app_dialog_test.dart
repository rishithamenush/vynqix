import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/presentation/widgets/app_dialog.dart';

Future<void> pumpMessage(
  WidgetTester tester,
  void Function(BuildContext) show, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => show(context),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
}

void main() {
  group('showMessage', () {
    testWidgets('is a centred box, not a bar at an edge', (tester) async {
      await pumpMessage(
        tester,
        (context) => context.showMessage('Give the task a title first.'),
      );

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AppDialogBox), findsOneWidget);
      expect(find.text('Give the task a title first.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      // Vertically centred rather than pinned to the top or bottom.
      final box = tester.getRect(find.byType(AppDialogBox));
      expect(box.center.dy, closeTo(844 / 2, 40));
    });

    testWidgets('dismisses on the single OK pill', (tester) async {
      await pumpMessage(
        tester,
        (context) => context.showMessage('Review saved.', isSuccess: true),
      );

      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();

      expect(find.text('Review saved.'), findsNothing);
    });

    testWidgets('an action runs only when its pill is tapped', (tester) async {
      var undone = false;
      await pumpMessage(
        tester,
        (context) => context.showMessage(
          'Deleted “Tg”',
          icon: Icons.delete_outline_rounded,
          actionLabel: 'Undo',
          onAction: () => undone = true,
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Dismiss'));
      await tester.pumpAndSettle();
      expect(undone, isFalse, reason: 'dismiss must not undo');

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Undo'));
      await tester.pumpAndSettle();

      expect(undone, isTrue);
      expect(find.text('Deleted “Tg”'), findsNothing);
    });

    testWidgets('errors carry the error glyph', (tester) async {
      await pumpMessage(
        tester,
        (context) => context.showMessage('Something broke', isError: true),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('a long message does not overflow a small phone', (
      tester,
    ) async {
      await pumpMessage(
        tester,
        (context) => context.showMessage(
          'Copied 12 tasks from today into tomorrow, including every '
          'subtask and reminder attached to them.',
          actionLabel: 'Undo',
        ),
        size: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

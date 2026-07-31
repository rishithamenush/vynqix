import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/presentation/widgets/app_sheet.dart';
import 'package:vynqix/presentation/widgets/common.dart';

/// Hosts a button that opens a popup and records what it returned.
class _Host<T> extends StatefulWidget {
  const _Host({super.key, required this.open});

  final Future<T?> Function(BuildContext) open;

  @override
  State<_Host<T>> createState() => _HostState<T>();
}

class _HostState<T> extends State<_Host<T>> {
  T? result;
  bool closed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final value = await widget.open(context);
            setState(() {
              result = value;
              closed = true;
            });
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

// ignore: library_private_types_in_public_api
Future<_HostState<T>> pumpHost<T>(
  WidgetTester tester,
  Future<T?> Function(BuildContext) open, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey<_HostState<T>>();
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: _Host<T>(key: key, open: open)),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return key.currentState!;
}

void main() {
  group('showOptionsSheet', () {
    testWidgets('returns the tapped option', (tester) async {
      final host = await pumpHost<String>(
        tester,
        (context) => showOptionsSheet<String>(
          context,
          title: 'Repeat',
          options: const [
            SheetOption(value: 'none', label: 'Never'),
            SheetOption(value: 'daily', label: 'Every day'),
          ],
        ),
      );

      expect(find.text('Repeat'), findsOneWidget);
      await tester.tap(find.text('Every day'));
      await tester.pumpAndSettle();

      expect(host.result, 'daily');
    });

    testWidgets('marks the current value with a check', (tester) async {
      await pumpHost<String>(
        tester,
        (context) => showOptionsSheet<String>(
          context,
          title: 'Repeat',
          selected: 'daily',
          options: const [
            SheetOption(value: 'none', label: 'Never'),
            SheetOption(value: 'daily', label: 'Every day'),
          ],
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('returns null when dismissed', (tester) async {
      final host = await pumpHost<String>(
        tester,
        (context) => showOptionsSheet<String>(
          context,
          title: 'Repeat',
          options: const [SheetOption(value: 'none', label: 'Never')],
        ),
      );

      // Tap the barrier above the sheet.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(host.closed, isTrue);
      expect(host.result, isNull);
    });

    testWidgets('a twelve-option picker scrolls instead of overflowing', (
      tester,
    ) async {
      await pumpHost<int>(
        tester,
        (context) => showOptionsSheet<int>(
          context,
          title: 'Daily target',
          subtitle: 'How many tasks count as a full day.',
          selected: 3,
          options: [
            for (var i = 1; i <= 12; i++)
              SheetOption(value: i, label: '$i tasks a day'),
          ],
        ),
        size: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
      // Capped at 80% of the window so the sheet never covers the screen.
      expect(
        tester.getSize(find.byType(AppSheet)).height,
        lessThanOrEqualTo(568 * 0.8),
      );
    });
  });

  group('confirmDialog', () {
    testWidgets('returns true from the confirm pill', (tester) async {
      final host = await pumpHost<bool>(
        tester,
        (context) => confirmDialog(
          context,
          title: 'Delete task?',
          message: 'This cannot be undone.',
          confirmLabel: 'Delete',
        ),
      );

      expect(find.text('Delete task?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(host.result, isTrue);
    });

    testWidgets('returns false from cancel', (tester) async {
      final host = await pumpHost<bool>(
        tester,
        (context) => confirmDialog(
          context,
          title: 'Delete task?',
          message: 'This cannot be undone.',
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(host.result, isFalse);
    });
  });
}

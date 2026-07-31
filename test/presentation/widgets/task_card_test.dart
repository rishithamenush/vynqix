import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/domain/entities/task.dart';
import 'package:vynqix/domain/enums/task_enums.dart';
import 'package:vynqix/presentation/widgets/task_card.dart';

import '../../helpers/fixtures.dart';

Future<void> pumpCard(
  WidgetTester tester,
  Task task, {
  Size size = const Size(390, 844),
  double textScale = 1.0,
  bool isCurrent = false,
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
        child: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TaskCard(task: task, isCurrent: isCurrent, onToggle: () {}),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TaskCard', () {
    testWidgets('shows the start time as a trailing pill, not in the meta '
        'line', (tester) async {
      await pumpCard(
        tester,
        task(title: 'Write the report', startMinutes: 9 * 60 + 30),
      );

      expect(find.text('9:30 AM'), findsOneWidget);
      expect(find.text('Write the report'), findsOneWidget);
      // The time must appear exactly once — it used to also be in the meta
      // line, and showing it twice is the obvious way to get this wrong.
      expect(find.textContaining('9:30'), findsOneWidget);
    });

    testWidgets('drops the time pill and meta line once done', (tester) async {
      await pumpCard(
        tester,
        task(
          title: 'Write the report',
          startMinutes: 9 * 60 + 30,
          status: TaskStatus.completed,
        ),
      );

      expect(find.text('9:30 AM'), findsNothing);
      expect(find.textContaining('30m'), findsNothing);
    });

    testWidgets('survives a long title on a small phone at a large text size', (
      tester,
    ) async {
      await pumpCard(
        tester,
        task(
          title: 'Finish the quarterly planning document and send it around',
          startMinutes: 14 * 60,
          priority: TaskPriority.high,
        ),
        size: const Size(320, 568),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('stays a single row of comfortable height', (tester) async {
      await pumpCard(tester, task(title: 'Short one', startMinutes: 8 * 60));

      final height = tester.getSize(find.byType(TaskCard)).height;
      expect(height, greaterThan(56));
      expect(height, lessThan(100));
    });
  });
}

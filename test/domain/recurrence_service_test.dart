import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/domain/enums/task_enums.dart';
import 'package:vynqix/domain/services/recurrence_service.dart';

import '../helpers/fixtures.dart';

void main() {
  test('a non-repeating task expands to nothing', () {
    expect(RecurrenceService.expand(task()), isEmpty);
  });

  test('daily repeats produce one occurrence per day, excluding the template', () {
    final occurrences = RecurrenceService.expand(
      task(dayKey: '2026-07-31', repeat: RepeatRule.daily),
      horizon: 3,
    );

    expect(
      occurrences.map((t) => t.dayKey),
      ['2026-08-01', '2026-08-02', '2026-08-03'],
    );
  });

  test('weekdays repeats skip Saturday and Sunday', () {
    // 2026-07-31 is a Friday, so a 5-day horizon reaches Wednesday 5 Aug
    // and the weekend (1–2 Aug) must be absent.
    final occurrences = RecurrenceService.expand(
      task(dayKey: '2026-07-31', repeat: RepeatRule.weekdays),
      horizon: 5,
    );

    expect(
      occurrences.map((t) => t.dayKey),
      ['2026-08-03', '2026-08-04', '2026-08-05'],
    );
  });

  test('weekly repeats land on the same weekday', () {
    final occurrences = RecurrenceService.expand(
      task(dayKey: '2026-07-31', repeat: RepeatRule.weekly),
      horizon: 21,
    );

    expect(
      occurrences.map((t) => t.dayKey),
      ['2026-08-07', '2026-08-14', '2026-08-21'],
    );
  });

  test('monthly repeats clamp to the last day of a shorter month', () {
    final occurrences = RecurrenceService.expand(
      task(dayKey: '2026-01-31', repeat: RepeatRule.monthly),
      horizon: 60,
    );

    // February 2026 has 28 days.
    expect(occurrences.first.dayKey, '2026-02-28');
  });

  test('occurrences share a series id and carry the template settings', () {
    final template = task(
      id: 'root',
      dayKey: '2026-07-31',
      repeat: RepeatRule.daily,
      category: TaskCategory.health,
      priority: TaskPriority.high,
      startMinutes: 7 * 60,
      durationMinutes: 45,
      seriesId: 'root',
    );

    final occurrences = RecurrenceService.expand(template, horizon: 2);

    expect(occurrences.every((t) => t.seriesId == 'root'), isTrue);
    expect(occurrences.every((t) => t.category == TaskCategory.health), isTrue);
    expect(occurrences.every((t) => t.priority == TaskPriority.high), isTrue);
    expect(occurrences.every((t) => t.startMinutes == 7 * 60), isTrue);
    expect(occurrences.every((t) => t.durationMinutes == 45), isTrue);
    expect(occurrences.map((t) => t.id).toSet(), hasLength(2));
  });

  test('occurrences start unchecked even if the template has done subtasks', () {
    final template = task(
      dayKey: '2026-07-31',
      repeat: RepeatRule.daily,
      subtasks: [subtaskDone('a'), subtaskDone('b')],
    );

    final occurrences = RecurrenceService.expand(template, horizon: 1);

    expect(
      occurrences.single.subtasks.every((s) => !s.isDone),
      isTrue,
    );
  });
}

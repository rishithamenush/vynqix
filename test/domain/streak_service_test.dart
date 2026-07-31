import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/date_x.dart';
import 'package:vynqix/domain/entities/stats.dart';
import 'package:vynqix/domain/services/streak_service.dart';

DayStats day(DateTime date, {int completed = 1, int total = 1}) => DayStats(
  dayKey: date.dayKey,
  total: total,
  completed: completed,
  missed: 0,
  plannedMinutes: 0,
  focusMinutes: 0,
);

void main() {
  final now = DateTime(2026, 7, 31, 14);
  final today = now.dateOnly;
  DateTime ago(int days) => today.subtract(Duration(days: days));

  test('no history means no streak', () {
    expect(StreakService.compute(const [], now: now), StreakInfo.zero);
  });

  test('days with no completions do not count', () {
    final streak = StreakService.compute([
      day(ago(1), completed: 0, total: 3),
      day(today, completed: 0, total: 2),
    ], now: now);

    expect(streak.current, 0);
    expect(streak.longest, 0);
  });

  test('counts consecutive productive days ending today', () {
    final streak = StreakService.compute([
      day(ago(2)),
      day(ago(1)),
      day(today),
    ], now: now);

    expect(streak.current, 3);
    expect(streak.longest, 3);
  });

  test('an empty today does not break a streak alive yesterday', () {
    final streak = StreakService.compute([
      day(ago(2)),
      day(ago(1)),
      day(today, completed: 0, total: 2),
    ], now: now);

    expect(streak.current, 2);
  });

  test('a gap resets the current streak but keeps the longest', () {
    final streak = StreakService.compute([
      day(ago(9)),
      day(ago(8)),
      day(ago(7)),
      day(ago(6)),
      // gap at ago(5) and ago(4)
      day(ago(1)),
      day(today),
    ], now: now);

    expect(streak.current, 2);
    expect(streak.longest, 4);
  });

  test('longest is never reported below current', () {
    final streak = StreakService.compute([
      day(ago(1)),
      day(today),
    ], now: now);

    expect(streak.longest, greaterThanOrEqualTo(streak.current));
  });
}

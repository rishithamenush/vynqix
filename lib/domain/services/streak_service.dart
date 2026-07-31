import '../../core/utils/date_x.dart';
import '../entities/stats.dart';

/// Derives streak counts from a day-by-day history.
///
/// A day counts toward a streak when at least one task was completed on it.
/// Today is treated leniently: an empty *today* does not break a streak that
/// was alive yesterday, because the day is not over yet.
abstract final class StreakService {
  static StreakInfo compute(List<DayStats> days, {DateTime? now}) {
    if (days.isEmpty) return StreakInfo.zero;

    final today = (now ?? DateTime.now()).dateOnly;
    final productive = <String>{
      for (final d in days)
        if (d.isProductive) d.dayKey,
    };
    if (productive.isEmpty) return StreakInfo.zero;

    // Current streak: walk backwards from today (or yesterday if today is
    // still empty) until a gap appears.
    var cursor = today;
    if (!productive.contains(cursor.dayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var current = 0;
    while (productive.contains(cursor.dayKey)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Longest streak: scan the sorted set of productive days.
    final sorted = productive.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final key in sorted) {
      final date = DateX.parseKey(key);
      if (previous != null && date.difference(previous).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      previous = date;
    }

    return StreakInfo(
      current: current,
      longest: longest < current ? current : longest,
    );
  }
}

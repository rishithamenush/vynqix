import 'package:intl/intl.dart';

/// Date helpers shared across the app.
///
/// A "day key" is the canonical `yyyy-MM-dd` string used to group tasks and
/// day logs. Storing the key rather than a timestamp keeps day-bucketing
/// immune to timezone drift and makes SQL queries trivial.
extension DateKeyX on DateTime {
  String get dayKey => DateFormat('yyyy-MM-dd').format(this);

  /// Midnight of this date, with the time component discarded.
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday => isSameDay(DateTime.now());

  bool get isTomorrow =>
      isSameDay(DateTime.now().add(const Duration(days: 1)));

  bool get isYesterday =>
      isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  /// Monday of the week containing this date.
  DateTime get startOfWeek => dateOnly.subtract(Duration(days: weekday - 1));

  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));

  DateTime get startOfMonth => DateTime(year, month);

  DateTime get endOfMonth => DateTime(year, month + 1, 0);
}

abstract final class DateX {
  static final _dayKey = DateFormat('yyyy-MM-dd');

  static DateTime get today => DateTime.now().dateOnly;

  static DateTime get tomorrow => today.add(const Duration(days: 1));

  static DateTime get yesterday => today.subtract(const Duration(days: 1));

  static String get todayKey => today.dayKey;

  static String get tomorrowKey => tomorrow.dayKey;

  /// Parses a `yyyy-MM-dd` key back into a local midnight [DateTime].
  static DateTime parseKey(String key) => _dayKey.parse(key);

  /// A human label such as "Today", "Tomorrow" or "Mon, 4 Aug".
  static String relativeLabel(DateTime date) {
    if (date.isToday) return 'Today';
    if (date.isTomorrow) return 'Tomorrow';
    if (date.isYesterday) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(date);
  }

  static String fullLabel(DateTime date) =>
      DateFormat('EEEE, d MMMM y').format(date);

  static String shortLabel(DateTime date) => DateFormat('d MMM').format(date);

  static String monthLabel(DateTime date) => DateFormat('MMMM y').format(date);

  static String weekdayInitial(DateTime date) =>
      DateFormat('EEEEE').format(date);

  /// Every day from [from] to [to] inclusive.
  static List<DateTime> daysBetween(DateTime from, DateTime to) {
    final start = from.dateOnly;
    final end = to.dateOnly;
    final count = end.difference(start).inDays;
    if (count < 0) return const [];
    return List.generate(count + 1, (i) => start.add(Duration(days: i)));
  }

  /// The 7 days of the week containing [date], starting Monday.
  static List<DateTime> weekOf(DateTime date) {
    final start = date.startOfWeek;
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Every cell of a month grid, padded to whole weeks starting Monday.
  static List<DateTime> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final start = first.startOfWeek;
    final end = last.endOfWeek;
    return daysBetween(start, end);
  }

  /// A greeting appropriate to the current hour.
  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}

/// Formatting for "minutes since midnight" values, which is how the app
/// stores wall-clock times (start times, wake/sleep times).
abstract final class TimeOfDayX {
  /// Formats 545 as "9:05 AM".
  static String format(int minutesFromMidnight, {bool use24h = false}) {
    final m = minutesFromMidnight % (24 * 60);
    final hour = m ~/ 60;
    final minute = m % 60;
    if (use24h) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }
    final period = hour < 12 ? 'AM' : 'PM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:${minute.toString().padLeft(2, '0')} $period';
  }

  static int fromDateTime(DateTime dt) => dt.hour * 60 + dt.minute;

  static int get now => fromDateTime(DateTime.now());

  /// Resolves minutes-since-midnight against a calendar day.
  static DateTime onDay(DateTime day, int minutesFromMidnight) => DateTime(
    day.year,
    day.month,
    day.day,
  ).add(Duration(minutes: minutesFromMidnight));
}

/// Human-readable durations, e.g. "1h 30m".
abstract final class DurationX {
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Formats a countdown as "25:00" or "1:05:00".
  static String formatClock(Duration d) {
    final total = d.inSeconds.abs();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }
}

import 'package:meta/meta.dart';

import '../enums/task_enums.dart';

/// User-tunable preferences. Persisted as a key/value row per field so
/// adding a setting never requires a schema migration.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeModeOption.system,
    this.use24HourClock = false,
    this.notificationsEnabled = true,
    this.dailyPlanReminderMinutes = 20 * 60,
    this.reviewReminderMinutes = 21 * 60,
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.autoStartBreaks = true,
    this.keepScreenAwakeInFocus = true,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.showCompletedTasks = true,
    this.rolloverUnfinished = true,
  });

  final ThemeModeOption themeMode;
  final bool use24HourClock;

  final bool notificationsEnabled;

  /// When to nudge the user to plan tomorrow (minutes since midnight).
  final int dailyPlanReminderMinutes;

  /// When to nudge the user to write the daily review.
  final int reviewReminderMinutes;

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool autoStartBreaks;
  final bool keepScreenAwakeInFocus;

  final bool hapticsEnabled;
  final bool soundEnabled;

  final bool showCompletedTasks;

  /// Move yesterday's unfinished tasks onto today at launch.
  final bool rolloverUnfinished;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    bool? use24HourClock,
    bool? notificationsEnabled,
    int? dailyPlanReminderMinutes,
    int? reviewReminderMinutes,
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? autoStartBreaks,
    bool? keepScreenAwakeInFocus,
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? showCompletedTasks,
    bool? rolloverUnfinished,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      use24HourClock: use24HourClock ?? this.use24HourClock,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyPlanReminderMinutes:
          dailyPlanReminderMinutes ?? this.dailyPlanReminderMinutes,
      reviewReminderMinutes:
          reviewReminderMinutes ?? this.reviewReminderMinutes,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      keepScreenAwakeInFocus:
          keepScreenAwakeInFocus ?? this.keepScreenAwakeInFocus,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      rolloverUnfinished: rolloverUnfinished ?? this.rolloverUnfinished,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.themeMode == themeMode &&
          other.use24HourClock == use24HourClock &&
          other.notificationsEnabled == notificationsEnabled &&
          other.dailyPlanReminderMinutes == dailyPlanReminderMinutes &&
          other.reviewReminderMinutes == reviewReminderMinutes &&
          other.focusMinutes == focusMinutes &&
          other.shortBreakMinutes == shortBreakMinutes &&
          other.longBreakMinutes == longBreakMinutes &&
          other.autoStartBreaks == autoStartBreaks &&
          other.keepScreenAwakeInFocus == keepScreenAwakeInFocus &&
          other.hapticsEnabled == hapticsEnabled &&
          other.soundEnabled == soundEnabled &&
          other.showCompletedTasks == showCompletedTasks &&
          other.rolloverUnfinished == rolloverUnfinished;

  @override
  int get hashCode => Object.hash(
    themeMode,
    use24HourClock,
    notificationsEnabled,
    dailyPlanReminderMinutes,
    reviewReminderMinutes,
    focusMinutes,
    shortBreakMinutes,
    longBreakMinutes,
    autoStartBreaks,
    keepScreenAwakeInFocus,
    hapticsEnabled,
    soundEnabled,
    showCompletedTasks,
    rolloverUnfinished,
  );
}

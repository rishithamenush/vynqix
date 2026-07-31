/// Domain enumerations for Vynqix.
///
/// These are deliberately pure Dart — no Flutter imports. Visual concerns
/// (colour, icon) live in `core/theme/token_styles.dart` so the domain layer
/// stays testable and framework-free.
library;

/// How urgent a task is. Drives sorting and the priority indicator.
enum TaskPriority {
  high('high', 'High', 0),
  medium('medium', 'Medium', 1),
  low('low', 'Low', 2);

  const TaskPriority(this.id, this.label, this.sortOrder);

  final String id;
  final String label;

  /// Lower sorts first.
  final int sortOrder;

  static TaskPriority fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => medium);
}

/// Lifecycle of a single task.
enum TaskStatus {
  pending('pending', 'Pending'),
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed'),
  skipped('skipped', 'Skipped'),
  missed('missed', 'Missed');

  const TaskStatus(this.id, this.label);

  final String id;
  final String label;

  bool get isDone => this == completed;
  bool get isOpen => this == pending || this == inProgress;

  static TaskStatus fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => pending);
}

/// Life area a task belongs to. Mirrors `TASK_CATEGORIES` from the source spec.
enum TaskCategory {
  work('work', 'Work'),
  study('study', 'Study'),
  health('health', 'Health'),
  personal('personal', 'Personal'),
  social('social', 'Social'),
  finance('finance', 'Finance'),
  creative('creative', 'Creative'),
  other('other', 'Other');

  const TaskCategory(this.id, this.label);

  final String id;
  final String label;

  static TaskCategory fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => other);
}

/// Recurrence rule for a task.
enum RepeatRule {
  none('none', 'Does not repeat'),
  daily('daily', 'Every day'),
  weekdays('weekdays', 'Weekdays'),
  weekly('weekly', 'Every week'),
  monthly('monthly', 'Every month');

  const RepeatRule(this.id, this.label);

  final String id;
  final String label;

  bool get repeats => this != none;

  static RepeatRule fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => none);
}

/// Self-reported mood captured in the daily review.
enum Mood {
  great('great', 'Great', '😄', 5),
  good('good', 'Good', '🙂', 4),
  okay('okay', 'Okay', '😐', 3),
  bad('bad', 'Bad', '😔', 2),
  terrible('terrible', 'Terrible', '😞', 1);

  const Mood(this.id, this.label, this.emoji, this.score);

  final String id;
  final String label;
  final String emoji;

  /// 1–5, used for trend charts.
  final int score;

  static Mood? fromId(String? id) {
    if (id == null) return null;
    for (final v in values) {
      if (v.id == id) return v;
    }
    return null;
  }
}

/// Self-reported energy captured in the daily review.
enum EnergyLevel {
  high('high', 'High energy', '⚡', 3),
  medium('medium', 'Medium', '🔋', 2),
  low('low', 'Low energy', '😴', 1);

  const EnergyLevel(this.id, this.label, this.emoji, this.score);

  final String id;
  final String label;
  final String emoji;
  final int score;

  static EnergyLevel? fromId(String? id) {
    if (id == null) return null;
    for (final v in values) {
      if (v.id == id) return v;
    }
    return null;
  }
}

/// Kind of focus block that was run.
enum FocusSessionType {
  focus('focus', 'Focus'),
  shortBreak('short_break', 'Short break'),
  longBreak('long_break', 'Long break');

  const FocusSessionType(this.id, this.label);

  final String id;
  final String label;

  static FocusSessionType fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => focus);
}

/// Theme preference stored in settings.
enum ThemeModeOption {
  system('system', 'System'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const ThemeModeOption(this.id, this.label);

  final String id;
  final String label;

  static ThemeModeOption fromId(String? id) =>
      values.firstWhere((e) => e.id == id, orElse: () => system);
}

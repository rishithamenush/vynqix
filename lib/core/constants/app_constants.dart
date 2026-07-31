/// App-wide constants. Values carried over from the source project's
/// `constants/app.ts` so the two apps stay conceptually identical.
abstract final class AppConstants {
  static const appName = 'Vynqix';
  static const tagline = 'Plan tomorrow. Master today.';

  static const databaseName = 'vynqix.db';
  static const databaseVersion = 1;

  /// Selectable focus-block lengths, in minutes.
  static const focusDurations = <int>[15, 25, 30, 45, 60, 90];

  /// Selectable break lengths, in minutes.
  static const breakDurations = <int>[5, 10, 15, 20];

  /// Selectable task durations offered in the task editor, in minutes.
  static const taskDurations = <int>[15, 30, 45, 60, 90, 120, 180];

  /// Number of focus blocks before a long break is offered.
  static const pomodorosPerLongBreak = 4;

  static const taskEmojis = <String>[
    '📋', '💼', '📚', '🏋️', '🎯', '💡', '🔥', '⚡',
    '🌟', '🎨', '🏠', '🍎', '💰', '🎵', '📝', '🚀',
  ];

  static const quotes = <String>[
    'The secret of getting ahead is getting started.',
    'Focus on being productive instead of busy.',
    "You don't have to be great to start, but you have to start to be great.",
    'Small daily improvements are the key to staggering long-term results.',
    'The way to get started is to quit talking and begin doing.',
    'Done is better than perfect.',
    'Your future is created by what you do today, not tomorrow.',
    'Productivity is never an accident. It is always the result of a commitment to excellence.',
  ];

  /// XP awarded for each completed task, before priority weighting.
  static const xpPerTask = 10;

  /// XP awarded for finishing a focus session.
  static const xpPerFocusSession = 15;

  /// XP awarded for logging a daily review.
  static const xpPerReview = 20;

  /// XP required to advance one level (level N needs N * this).
  static const xpPerLevel = 200;
}

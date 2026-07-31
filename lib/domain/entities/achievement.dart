import 'package:meta/meta.dart';

/// The quantity an achievement is measured against.
enum AchievementMetric {
  tasksCompleted,
  currentStreak,
  focusMinutes,
  focusSessions,
  reviewsLogged,
  perfectDays,
  level,
}

/// A static, code-defined achievement. The catalog lives in
/// [AchievementCatalog]; only unlock timestamps are persisted.
@immutable
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.metric,
    required this.threshold,
    required this.xpReward,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementMetric metric;
  final int threshold;
  final int xpReward;
}

/// A definition combined with the user's live progress against it.
@immutable
class Achievement {
  const Achievement({
    required this.definition,
    required this.progress,
    this.unlockedAt,
  });

  final AchievementDefinition definition;

  /// Raw progress value for the metric (not clamped to the threshold).
  final int progress;

  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  double get ratio => definition.threshold == 0
      ? 1
      : (progress / definition.threshold).clamp(0, 1).toDouble();

  int get remaining => (definition.threshold - progress).clamp(0, 1 << 30);

  String get id => definition.id;
}

/// Every achievement the app can award, ordered by tier within a family.
abstract final class AchievementCatalog {
  static const all = <AchievementDefinition>[
    AchievementDefinition(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your very first task.',
      emoji: '🌱',
      metric: AchievementMetric.tasksCompleted,
      threshold: 1,
      xpReward: 25,
    ),
    AchievementDefinition(
      id: 'getting_going',
      title: 'Getting Going',
      description: 'Complete 10 tasks.',
      emoji: '🚶',
      metric: AchievementMetric.tasksCompleted,
      threshold: 10,
      xpReward: 50,
    ),
    AchievementDefinition(
      id: 'centurion',
      title: 'Centurion',
      description: 'Complete 100 tasks.',
      emoji: '🏅',
      metric: AchievementMetric.tasksCompleted,
      threshold: 100,
      xpReward: 150,
    ),
    AchievementDefinition(
      id: 'machine',
      title: 'The Machine',
      description: 'Complete 500 tasks.',
      emoji: '🤖',
      metric: AchievementMetric.tasksCompleted,
      threshold: 500,
      xpReward: 400,
    ),
    AchievementDefinition(
      id: 'streak_3',
      title: 'Warming Up',
      description: 'Keep a 3-day streak.',
      emoji: '🔥',
      metric: AchievementMetric.currentStreak,
      threshold: 3,
      xpReward: 40,
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'Week Strong',
      description: 'Keep a 7-day streak.',
      emoji: '📆',
      metric: AchievementMetric.currentStreak,
      threshold: 7,
      xpReward: 80,
    ),
    AchievementDefinition(
      id: 'streak_30',
      title: 'Unbreakable',
      description: 'Keep a 30-day streak.',
      emoji: '💎',
      metric: AchievementMetric.currentStreak,
      threshold: 30,
      xpReward: 250,
    ),
    AchievementDefinition(
      id: 'focus_first',
      title: 'In The Zone',
      description: 'Finish your first focus session.',
      emoji: '🎯',
      metric: AchievementMetric.focusSessions,
      threshold: 1,
      xpReward: 25,
    ),
    AchievementDefinition(
      id: 'focus_25',
      title: 'Deep Diver',
      description: 'Finish 25 focus sessions.',
      emoji: '🌊',
      metric: AchievementMetric.focusSessions,
      threshold: 25,
      xpReward: 120,
    ),
    AchievementDefinition(
      id: 'focus_1000m',
      title: 'Thousand Minutes',
      description: 'Log 1,000 minutes of focus.',
      emoji: '⏳',
      metric: AchievementMetric.focusMinutes,
      threshold: 1000,
      xpReward: 200,
    ),
    AchievementDefinition(
      id: 'reflective',
      title: 'Reflective',
      description: 'Write 7 daily reviews.',
      emoji: '📔',
      metric: AchievementMetric.reviewsLogged,
      threshold: 7,
      xpReward: 90,
    ),
    AchievementDefinition(
      id: 'perfect_day',
      title: 'Perfect Day',
      description: 'Finish every task you planned for a day.',
      emoji: '✨',
      metric: AchievementMetric.perfectDays,
      threshold: 1,
      xpReward: 60,
    ),
    AchievementDefinition(
      id: 'perfect_10',
      title: 'Flawless Ten',
      description: 'Have 10 perfect days.',
      emoji: '👑',
      metric: AchievementMetric.perfectDays,
      threshold: 10,
      xpReward: 220,
    ),
    AchievementDefinition(
      id: 'level_5',
      title: 'Seasoned',
      description: 'Reach level 5.',
      emoji: '⭐',
      metric: AchievementMetric.level,
      threshold: 5,
      xpReward: 100,
    ),
    AchievementDefinition(
      id: 'level_10',
      title: 'Master Planner',
      description: 'Reach level 10.',
      emoji: '🏆',
      metric: AchievementMetric.level,
      threshold: 10,
      xpReward: 300,
    ),
  ];

  static AchievementDefinition? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }
}

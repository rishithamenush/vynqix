import '../entities/achievement.dart';

/// The raw counters every achievement is evaluated against.
class AchievementMetrics {
  const AchievementMetrics({
    this.tasksCompleted = 0,
    this.currentStreak = 0,
    this.focusMinutes = 0,
    this.focusSessions = 0,
    this.reviewsLogged = 0,
    this.perfectDays = 0,
    this.level = 1,
  });

  final int tasksCompleted;
  final int currentStreak;
  final int focusMinutes;
  final int focusSessions;
  final int reviewsLogged;
  final int perfectDays;
  final int level;

  int valueFor(AchievementMetric metric) => switch (metric) {
    AchievementMetric.tasksCompleted => tasksCompleted,
    AchievementMetric.currentStreak => currentStreak,
    AchievementMetric.focusMinutes => focusMinutes,
    AchievementMetric.focusSessions => focusSessions,
    AchievementMetric.reviewsLogged => reviewsLogged,
    AchievementMetric.perfectDays => perfectDays,
    AchievementMetric.level => level,
  };
}

/// Evaluates the achievement catalog against live metrics.
abstract final class AchievementService {
  /// Merges the catalog with progress and any persisted unlock timestamps.
  /// Unlocked achievements sort first, then by how close they are to unlocking.
  static List<Achievement> evaluate({
    required AchievementMetrics metrics,
    required Map<String, DateTime> unlocked,
  }) {
    final result = AchievementCatalog.all.map((def) {
      return Achievement(
        definition: def,
        progress: metrics.valueFor(def.metric),
        unlockedAt: unlocked[def.id],
      );
    }).toList();

    result.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) return a.isUnlocked ? -1 : 1;
      if (a.isUnlocked) return b.unlockedAt!.compareTo(a.unlockedAt!);
      return b.ratio.compareTo(a.ratio);
    });
    return result;
  }

  /// Achievements whose threshold is now met but which have not been
  /// recorded as unlocked yet.
  static List<AchievementDefinition> newlyUnlocked({
    required AchievementMetrics metrics,
    required Map<String, DateTime> unlocked,
  }) {
    return AchievementCatalog.all
        .where(
          (def) =>
              !unlocked.containsKey(def.id) &&
              metrics.valueFor(def.metric) >= def.threshold,
        )
        .toList();
  }
}

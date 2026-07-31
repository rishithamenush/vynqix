import '../../core/utils/date_x.dart';
import '../entities/achievement.dart';
import '../repositories/repositories.dart';
import '../services/achievement_service.dart';
import '../services/stats_service.dart';
import '../services/streak_service.dart';

/// Awards XP and unlocks achievements.
///
/// Every action that can earn something (completing a task, finishing a focus
/// session, writing a review) funnels through here so the rules live in one
/// place instead of being duplicated across controllers.
class RewardsUseCase {
  const RewardsUseCase({
    required TaskRepository tasks,
    required DayLogRepository dayLogs,
    required FocusSessionRepository focusSessions,
    required ProfileRepository profile,
  }) : _tasks = tasks,
       _dayLogs = dayLogs,
       _focus = focusSessions,
       _profile = profile;

  final TaskRepository _tasks;
  final DayLogRepository _dayLogs;
  final FocusSessionRepository _focus;
  final ProfileRepository _profile;

  /// Grants [xp] then re-evaluates the catalog. Returns anything newly
  /// unlocked so the caller can celebrate it.
  Future<List<AchievementDefinition>> grant(int xp) async {
    if (xp > 0) await _profile.addXp(xp);
    return _checkAchievements();
  }

  Future<List<AchievementDefinition>> _checkAchievements() async {
    final metrics = await currentMetrics();
    final unlocked = await _profile.unlockedAchievements();
    final fresh = AchievementService.newlyUnlocked(
      metrics: metrics,
      unlocked: unlocked,
    );
    if (fresh.isEmpty) return const [];

    final now = DateTime.now();
    var bonus = 0;
    for (final def in fresh) {
      await _profile.unlockAchievement(def.id, now);
      bonus += def.xpReward;
    }
    if (bonus > 0) await _profile.addXp(bonus);
    return fresh;
  }

  /// The live counters behind every achievement and the profile header.
  Future<AchievementMetrics> currentMetrics() async {
    final results = await Future.wait([
      _tasks.countCompleted(),
      _focus.totalFocusMinutes(),
      _focus.countCompletedSessions(),
      _dayLogs.countLogged(),
    ]);

    final allTasks = await _tasks.getAll();
    final dayKeys = allTasks.map((t) => t.dayKey).toSet().toList()..sort();
    final sessions = dayKeys.isEmpty
        ? const []
        : await _focus.getRange(dayKeys.first, dayKeys.last);

    final range = StatsService.rangeStats(
      dayKeys: dayKeys,
      tasks: allTasks,
      sessions: sessions.cast(),
      logs: const [],
    );
    final streak = StreakService.compute(range.days);
    final profile = await _profile.get();

    return AchievementMetrics(
      tasksCompleted: results[0],
      currentStreak: streak.current,
      focusMinutes: results[1],
      focusSessions: results[2],
      reviewsLogged: results[3],
      perfectDays: range.perfectDays,
      level: profile.level,
    );
  }

  /// Convenience for callers that only need today's key.
  static String get todayKey => DateX.todayKey;
}

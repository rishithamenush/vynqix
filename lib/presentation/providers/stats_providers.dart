import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_x.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/stats.dart';
import '../../domain/services/achievement_service.dart';
import '../../domain/services/insights_service.dart';
import '../../domain/services/stats_service.dart';
import '../../domain/services/streak_service.dart';
import 'app_providers.dart';
import 'task_providers.dart';

/// Aggregates for a single day.
final dayStatsProvider = FutureProvider.family<DayStats, String>((
  ref,
  dayKey,
) async {
  final tasks = ref.watch(taskRepositoryProvider);
  final focus = ref.watch(focusSessionRepositoryProvider);
  refreshOnChanges(ref, [tasks, focus]);

  return StatsService.dayStats(
    dayKey: dayKey,
    tasks: await tasks.getByDay(dayKey),
    sessions: await focus.getByDay(dayKey),
  );
});

/// How many days back the Analytics screen looks.
final analyticsRangeProvider = StateProvider<int>((ref) => 7);

/// Aggregates over the selected analytics window, ending today.
final rangeStatsProvider = FutureProvider<RangeStats>((ref) async {
  final days = ref.watch(analyticsRangeProvider);
  return ref.watch(statsForLastDaysProvider(days).future);
});

/// Aggregates over an arbitrary number of trailing days.
final statsForLastDaysProvider = FutureProvider.family<RangeStats, int>((
  ref,
  days,
) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final focusRepo = ref.watch(focusSessionRepositoryProvider);
  final logRepo = ref.watch(dayLogRepositoryProvider);
  refreshOnChanges(ref, [taskRepo, focusRepo, logRepo]);

  final end = DateX.today;
  final start = end.subtract(Duration(days: days - 1));
  final keys = DateX.daysBetween(start, end).map((d) => d.dayKey).toList();

  final results = await Future.wait([
    taskRepo.getRange(keys.first, keys.last),
    focusRepo.getRange(keys.first, keys.last),
    logRepo.getRange(keys.first, keys.last),
  ]);

  return StatsService.rangeStats(
    dayKeys: keys,
    tasks: results[0].cast(),
    sessions: results[1].cast(),
    logs: results[2].cast(),
  );
});

/// All-time stats, used by the profile header and streak calculation.
final lifetimeStatsProvider = FutureProvider<RangeStats>((ref) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final focusRepo = ref.watch(focusSessionRepositoryProvider);
  final logRepo = ref.watch(dayLogRepositoryProvider);
  refreshOnChanges(ref, [taskRepo, focusRepo, logRepo]);

  final tasks = await taskRepo.getAll();
  if (tasks.isEmpty) return RangeStats.empty;

  final keys = tasks.map((t) => t.dayKey).toSet().toList()..sort();
  final results = await Future.wait([
    focusRepo.getRange(keys.first, keys.last),
    logRepo.getRange(keys.first, keys.last),
  ]);

  return StatsService.rangeStats(
    dayKeys: keys,
    tasks: tasks,
    sessions: results[0].cast(),
    logs: results[1].cast(),
  );
});

final streakProvider = FutureProvider<StreakInfo>((ref) async {
  final stats = await ref.watch(lifetimeStatsProvider.future);
  return StreakService.compute(stats.days);
});

final achievementMetricsProvider = FutureProvider<AchievementMetrics>((
  ref,
) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final focusRepo = ref.watch(focusSessionRepositoryProvider);
  final logRepo = ref.watch(dayLogRepositoryProvider);
  refreshOnChanges(ref, [taskRepo, profileRepo, focusRepo, logRepo]);

  return ref.watch(rewardsUseCaseProvider).currentMetrics();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final profileRepo = ref.watch(profileRepositoryProvider);
  refreshOnChanges(ref, [profileRepo]);

  final metrics = await ref.watch(achievementMetricsProvider.future);
  final unlocked = await profileRepo.unlockedAchievements();
  return AchievementService.evaluate(metrics: metrics, unlocked: unlocked);
});

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final stats = await ref.watch(statsForLastDaysProvider(30).future);
  final streak = await ref.watch(streakProvider.future);
  final profile = ref.watch(profileValueProvider);
  return InsightsService.generate(
    stats: stats,
    streak: streak,
    profile: profile,
  );
});

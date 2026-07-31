/// Contracts the presentation layer depends on.
///
/// Implementations live in `data/repositories`. Every repository exposes a
/// [Repository.changes] stream that fires after any write, which the Riverpod
/// providers listen to in order to re-query — a lightweight substitute for a
/// fully reactive database, and enough for a local-first single-user app.
library;

import '../entities/app_settings.dart';
import '../entities/day_log.dart';
import '../entities/focus_session.dart';
import '../entities/task.dart';
import '../entities/user_profile.dart';

abstract interface class Repository {
  /// Emits once after every mutation performed through this repository.
  Stream<void> get changes;

  /// Drops any in-memory cache so the next read hits storage.
  ///
  /// Required after a wholesale database wipe: repositories that memoise a
  /// singleton would otherwise keep serving deleted data.
  void invalidateCache();
}

abstract interface class TaskRepository implements Repository {
  Future<List<Task>> getByDay(String dayKey);

  /// Inclusive on both ends.
  Future<List<Task>> getRange(String fromDayKey, String toDayKey);

  Future<List<Task>> getAll();

  Future<Task?> getById(String id);

  /// Case-insensitive match against title, description, notes and tags.
  Future<List<Task>> search(String query);

  Future<void> save(Task task);

  Future<void> saveAll(List<Task> tasks);

  Future<void> delete(String id);

  /// Deletes every future occurrence of a repeating task, including [fromDayKey].
  Future<void> deleteSeriesFrom(String seriesId, String fromDayKey);

  /// Day keys that have at least one task, for calendar dot rendering.
  Future<Set<String>> daysWithTasks();

  Future<int> countCompleted();
}

abstract interface class DayLogRepository implements Repository {
  Future<DayLog?> getByDay(String dayKey);

  Future<List<DayLog>> getRange(String fromDayKey, String toDayKey);

  Future<List<DayLog>> getAll();

  Future<void> save(DayLog log);

  Future<void> delete(String dayKey);

  Future<int> countLogged();
}

abstract interface class FocusSessionRepository implements Repository {
  Future<List<FocusSession>> getByDay(String dayKey);

  Future<List<FocusSession>> getRange(String fromDayKey, String toDayKey);

  Future<List<FocusSession>> getByTask(String taskId);

  Future<void> save(FocusSession session);

  Future<void> delete(String id);

  /// Total completed focus minutes across all time.
  Future<int> totalFocusMinutes();

  /// Number of completed focus sessions across all time.
  Future<int> countCompletedSessions();
}

abstract interface class ProfileRepository implements Repository {
  Future<UserProfile> get();

  Future<void> save(UserProfile profile);

  /// Adds [amount] XP and returns the updated profile.
  Future<UserProfile> addXp(int amount);

  Future<Map<String, DateTime>> unlockedAchievements();

  Future<void> unlockAchievement(String id, DateTime at);
}

abstract interface class SettingsRepository implements Repository {
  Future<AppSettings> get();

  Future<void> save(AppSettings settings);
}

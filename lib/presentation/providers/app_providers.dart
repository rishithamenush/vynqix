import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/demo_data.dart';
import '../../data/repositories/day_log_repository_impl.dart';
import '../../data/repositories/focus_session_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';

/// Root of the dependency graph.
///
/// Overridden in `main.dart` (and in tests) with a real opened database, so
/// nothing in the app has to know how the database is constructed.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'databaseProvider must be overridden with an opened AppDatabase',
  ),
);

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final repo = TaskRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final dayLogRepositoryProvider = Provider<DayLogRepository>((ref) {
  final repo = DayLogRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  final repo = FocusSessionRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final repo = ProfileRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repo = SettingsRepositoryImpl(ref.watch(databaseProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Fills an empty database with a year of believable history.
///
/// Only reachable from Settings — nothing in the normal app flow touches it.
final demoDataSeederProvider = Provider<DemoDataSeeder>((ref) {
  return DemoDataSeeder(
    tasks: ref.watch(taskRepositoryProvider),
    dayLogs: ref.watch(dayLogRepositoryProvider),
    focusSessions: ref.watch(focusSessionRepositoryProvider),
    profile: ref.watch(profileRepositoryProvider),
  );
});

/// Re-runs the current provider whenever any of [repositories] reports a write.
///
/// This is what makes the whole UI reactive on top of a non-reactive SQLite
/// layer: a screen watches a query provider, the query provider subscribes to
/// the repositories it read from, and any mutation anywhere refreshes it.
void refreshOnChanges(Ref ref, List<Repository> repositories) {
  final subs = <StreamSubscription<void>>[];
  for (final repo in repositories) {
    subs.add(repo.changes.listen((_) => ref.invalidateSelf()));
  }
  ref.onDispose(() {
    for (final sub in subs) {
      sub.cancel();
    }
  });
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.watch(settingsRepositoryProvider).get();

  /// Applies [change] to the current settings and persists the result.
  Future<void> edit(AppSettings Function(AppSettings) change) async {
    final current = state.valueOrNull ?? const AppSettings();
    final updated = change(current);
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).save(updated);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Settings with a synchronous default, for widgets that cannot show a spinner
/// (the root `MaterialApp`, time formatters).
final settingsValueProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).valueOrNull ?? const AppSettings(),
);

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    refreshOnChanges(ref, [ref.watch(profileRepositoryProvider)]);
    return ref.watch(profileRepositoryProvider).get();
  }

  Future<void> edit(UserProfile Function(UserProfile) change) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = change(current);
    state = AsyncData(updated);
    await ref.read(profileRepositoryProvider).save(updated);
  }

  Future<void> completeOnboarding() => edit(
    (p) => p.copyWith(
      onboardingCompleted: true,
      createdAt: p.createdAt ?? DateTime.now(),
    ),
  );
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

final profileValueProvider = Provider<UserProfile>(
  (ref) => ref.watch(profileProvider).valueOrNull ?? const UserProfile(),
);

/// Drives the router's onboarding redirect.
final onboardingCompleteProvider = Provider<bool>(
  (ref) => ref.watch(profileValueProvider).onboardingCompleted,
);

/// Ticks once a minute so "now"-dependent UI (current task, overdue badges,
/// the timeline indicator) stays honest without a per-widget timer.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final nowProvider = Provider<DateTime>(
  (ref) => ref.watch(clockProvider).valueOrNull ?? DateTime.now(),
);

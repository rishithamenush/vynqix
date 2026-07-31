import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/day_log.dart';
import 'app_providers.dart';
import 'task_providers.dart';

/// The saved reflection for a day, or `null` when nothing has been written.
final dayLogProvider = FutureProvider.family<DayLog?, String>((
  ref,
  dayKey,
) async {
  final repo = ref.watch(dayLogRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  return repo.getByDay(dayKey);
});

/// Every reflection, newest first — the History screen's source.
final allDayLogsProvider = FutureProvider<List<DayLog>>((ref) async {
  final repo = ref.watch(dayLogRepositoryProvider);
  refreshOnChanges(ref, [repo]);
  return repo.getAll();
});

final reviewControllerProvider = Provider<ReviewController>(
  ReviewController.new,
);

class ReviewController {
  ReviewController(this._ref);

  final Ref _ref;

  /// Saves a reflection. The first save for a day awards XP; edits do not,
  /// so the reward cannot be farmed by re-saving.
  Future<void> save(DayLog log) async {
    final repo = _ref.read(dayLogRepositoryProvider);
    final existing = await repo.getByDay(log.dayKey);
    await repo.save(log);

    final isFirstMeaningfulSave = existing == null || existing.isEmpty;
    if (isFirstMeaningfulSave && !log.isEmpty) {
      await _ref.read(rewardsUseCaseProvider).grant(AppConstants.xpPerReview);
    }
  }

  Future<void> delete(String dayKey) =>
      _ref.read(dayLogRepositoryProvider).delete(dayKey);
}

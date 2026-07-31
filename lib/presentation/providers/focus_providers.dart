import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_x.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/enums/task_enums.dart';
import 'app_providers.dart';
import 'task_providers.dart';

enum TimerStatus { idle, running, paused, finished }

@immutable
class FocusState {
  const FocusState({
    this.phase = FocusSessionType.focus,
    this.status = TimerStatus.idle,
    this.totalSeconds = 25 * 60,
    this.remainingSeconds = 25 * 60,
    this.completedFocusBlocks = 0,
    this.taskId,
    this.sessionId,
    this.startedAt,
  });

  final FocusSessionType phase;
  final TimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;

  /// Focus blocks finished in this sitting, used to decide when a long break
  /// is due.
  final int completedFocusBlocks;

  final String? taskId;
  final String? sessionId;
  final DateTime? startedAt;

  bool get isRunning => status == TimerStatus.running;
  bool get isActive =>
      status == TimerStatus.running || status == TimerStatus.paused;

  int get elapsedSeconds => totalSeconds - remainingSeconds;

  double get progress =>
      totalSeconds == 0 ? 0 : (elapsedSeconds / totalSeconds).clamp(0, 1);

  Duration get remaining => Duration(seconds: remainingSeconds);

  FocusState copyWith({
    FocusSessionType? phase,
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    int? completedFocusBlocks,
    String? taskId,
    bool clearTaskId = false,
    String? sessionId,
    bool clearSessionId = false,
    DateTime? startedAt,
  }) {
    return FocusState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedFocusBlocks: completedFocusBlocks ?? this.completedFocusBlocks,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      sessionId: clearSessionId ? null : (sessionId ?? this.sessionId),
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

/// Drives the Pomodoro timer and writes a [FocusSession] row for every block.
///
/// The timer is a plain periodic [Timer]; the state it produces is what the
/// Focus screen renders, so the screen itself holds no mutable state and
/// survives navigation.
class FocusController extends Notifier<FocusState> {
  Timer? _ticker;

  @override
  FocusState build() {
    // Deliberately `read`, not `watch`: changing a setting mid-session must
    // not rebuild the notifier and kill a running timer.
    final settings = ref.read(settingsValueProvider);
    ref.onDispose(() => _ticker?.cancel());
    final seconds = settings.focusMinutes * 60;
    return FocusState(totalSeconds: seconds, remainingSeconds: seconds);
  }

  /// Prepares a fresh focus block, optionally bound to a task.
  void configure({int? minutes, String? taskId}) {
    _ticker?.cancel();
    final settings = ref.read(settingsValueProvider);
    final seconds = (minutes ?? settings.focusMinutes) * 60;
    state = FocusState(
      phase: FocusSessionType.focus,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      completedFocusBlocks: state.completedFocusBlocks,
      taskId: taskId,
    );
  }

  Future<void> start() async {
    if (state.status == TimerStatus.running) return;

    var next = state;
    if (state.sessionId == null) {
      final id = newId();
      final now = DateTime.now();
      next = state.copyWith(
        sessionId: id,
        startedAt: now,
        status: TimerStatus.running,
      );
      await ref
          .read(focusSessionRepositoryProvider)
          .save(
            FocusSession(
              id: id,
              dayKey: now.dayKey,
              taskId: state.taskId,
              type: state.phase,
              plannedMinutes: state.totalSeconds ~/ 60,
              startedAt: now,
            ),
          );
    } else {
      next = state.copyWith(status: TimerStatus.running);
    }

    state = next;
    _startTicker();

    // Mark the linked task as in-progress so the home screen reflects it.
    final taskId = state.taskId;
    if (taskId != null && state.phase == FocusSessionType.focus) {
      final task = await ref.read(taskRepositoryProvider).getById(taskId);
      if (task != null && task.status == TaskStatus.pending) {
        await ref.read(taskControllerProvider).start(task);
      }
    }
  }

  void pause() {
    if (state.status != TimerStatus.running) return;
    _ticker?.cancel();
    state = state.copyWith(status: TimerStatus.paused);
  }

  void resume() {
    if (state.status != TimerStatus.paused) return;
    state = state.copyWith(status: TimerStatus.running);
    _startTicker();
  }

  /// Abandons the block, persisting whatever time was accumulated.
  Future<void> stop() async {
    _ticker?.cancel();
    await _persist(completed: false);
    final settings = ref.read(settingsValueProvider);
    final seconds = settings.focusMinutes * 60;
    state = FocusState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      completedFocusBlocks: state.completedFocusBlocks,
      taskId: state.taskId,
    );
  }

  void addMinutes(int minutes) {
    state = state.copyWith(
      totalSeconds: state.totalSeconds + minutes * 60,
      remainingSeconds: state.remainingSeconds + minutes * 60,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        state = state.copyWith(
          remainingSeconds: 0,
          status: TimerStatus.finished,
        );
        _ticker?.cancel();
        unawaited(_onFinished());
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
  }

  Future<void> _onFinished() async {
    final wasFocus = state.phase == FocusSessionType.focus;
    await _persist(completed: true);

    if (wasFocus) {
      final blocks = state.completedFocusBlocks + 1;
      state = state.copyWith(completedFocusBlocks: blocks);

      final taskId = state.taskId;
      if (taskId != null) {
        await ref
            .read(taskControllerProvider)
            .addFocusMinutes(taskId, state.totalSeconds ~/ 60);
      }
      await ref
          .read(rewardsUseCaseProvider)
          .grant(AppConstants.xpPerFocusSession);

      final settings = ref.read(settingsValueProvider);
      if (settings.autoStartBreaks) {
        _beginBreak(blocks);
      }
    }
  }

  void _beginBreak(int completedBlocks) {
    final settings = ref.read(settingsValueProvider);
    final isLong = completedBlocks % AppConstants.pomodorosPerLongBreak == 0;
    final minutes = isLong
        ? settings.longBreakMinutes
        : settings.shortBreakMinutes;
    state = state.copyWith(
      phase: isLong ? FocusSessionType.longBreak : FocusSessionType.shortBreak,
      status: TimerStatus.idle,
      totalSeconds: minutes * 60,
      remainingSeconds: minutes * 60,
      clearSessionId: true,
    );
  }

  /// Moves from a finished break back to a focus block.
  void nextFocusBlock() {
    final settings = ref.read(settingsValueProvider);
    final seconds = settings.focusMinutes * 60;
    state = state.copyWith(
      phase: FocusSessionType.focus,
      status: TimerStatus.idle,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      clearSessionId: true,
    );
  }

  Future<void> _persist({required bool completed}) async {
    final id = state.sessionId;
    final startedAt = state.startedAt;
    if (id == null || startedAt == null) return;
    if (state.elapsedSeconds <= 0) return;

    await ref
        .read(focusSessionRepositoryProvider)
        .save(
          FocusSession(
            id: id,
            dayKey: startedAt.dayKey,
            taskId: state.taskId,
            type: state.phase,
            plannedMinutes: state.totalSeconds ~/ 60,
            startedAt: startedAt,
            endedAt: DateTime.now(),
            elapsedSeconds: state.elapsedSeconds,
            wasCompleted: completed,
          ),
        );
  }
}

final focusControllerProvider = NotifierProvider<FocusController, FocusState>(
  FocusController.new,
);

/// Focus sessions logged on a given day.
final focusSessionsForDayProvider =
    FutureProvider.family<List<FocusSession>, String>((ref, dayKey) async {
      final repo = ref.watch(focusSessionRepositoryProvider);
      refreshOnChanges(ref, [repo]);
      return repo.getByDay(dayKey);
    });

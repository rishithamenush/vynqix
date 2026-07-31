import 'package:meta/meta.dart';

import '../enums/task_enums.dart';

/// One Pomodoro-style block, logged whether or not it ran to completion.
@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.dayKey,
    required this.type,
    required this.plannedMinutes,
    required this.startedAt,
    this.taskId,
    this.endedAt,
    this.elapsedSeconds = 0,
    this.wasCompleted = false,
  });

  final String id;
  final String dayKey;
  final String? taskId;
  final FocusSessionType type;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Seconds actually spent, which may be less than planned if abandoned.
  final int elapsedSeconds;

  /// True when the timer reached zero rather than being stopped early.
  final bool wasCompleted;

  int get elapsedMinutes => elapsedSeconds ~/ 60;

  bool get isFocus => type == FocusSessionType.focus;

  FocusSession copyWith({
    String? taskId,
    DateTime? endedAt,
    int? elapsedSeconds,
    bool? wasCompleted,
  }) {
    return FocusSession(
      id: id,
      dayKey: dayKey,
      taskId: taskId ?? this.taskId,
      type: type,
      plannedMinutes: plannedMinutes,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      wasCompleted: wasCompleted ?? this.wasCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FocusSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

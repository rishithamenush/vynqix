import 'package:meta/meta.dart';

import '../enums/task_enums.dart';

/// The end-of-day reflection for a single day.
@immutable
class DayLog {
  const DayLog({
    required this.dayKey,
    this.mood,
    this.energy,
    this.rating = 0,
    this.highlight = '',
    this.gratitude = '',
    this.blocker = '',
    this.improvement = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// `yyyy-MM-dd` — also the primary key.
  final String dayKey;

  final Mood? mood;
  final EnergyLevel? energy;

  /// 0 = not rated, otherwise 1–5.
  final int rating;

  final String highlight;
  final String gratitude;
  final String blocker;
  final String improvement;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty =>
      mood == null &&
      energy == null &&
      rating == 0 &&
      highlight.isEmpty &&
      gratitude.isEmpty &&
      blocker.isEmpty &&
      improvement.isEmpty;

  bool get isComplete => mood != null && rating > 0;

  DayLog copyWith({
    Mood? mood,
    EnergyLevel? energy,
    int? rating,
    String? highlight,
    String? gratitude,
    String? blocker,
    String? improvement,
    DateTime? updatedAt,
  }) {
    return DayLog(
      dayKey: dayKey,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      rating: rating ?? this.rating,
      highlight: highlight ?? this.highlight,
      gratitude: gratitude ?? this.gratitude,
      blocker: blocker ?? this.blocker,
      improvement: improvement ?? this.improvement,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory DayLog.empty(String dayKey) {
    final now = DateTime.now();
    return DayLog(dayKey: dayKey, createdAt: now, updatedAt: now);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayLog && other.dayKey == dayKey && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(dayKey, updatedAt);
}

import 'package:meta/meta.dart';

import '../../core/constants/app_constants.dart';

/// The single local user: identity, lifestyle rhythm and gamification state.
@immutable
class UserProfile {
  const UserProfile({
    this.name = '',
    this.occupation = '',
    this.goal = '',
    this.avatarEmoji = '🙂',
    this.wakeMinutes = 7 * 60,
    this.sleepMinutes = 23 * 60,
    this.workStartMinutes = 9 * 60,
    this.workEndMinutes = 17 * 60,
    this.dailyTaskTarget = 5,
    this.xp = 0,
    this.isPremium = false,
    this.onboardingCompleted = false,
    this.createdAt,
  });

  final String name;
  final String occupation;
  final String goal;
  final String avatarEmoji;

  /// Lifestyle rhythm, all in minutes since midnight.
  final int wakeMinutes;
  final int sleepMinutes;
  final int workStartMinutes;
  final int workEndMinutes;

  /// How many tasks a day counts as a "win".
  final int dailyTaskTarget;

  final int xp;
  final bool isPremium;
  final bool onboardingCompleted;
  final DateTime? createdAt;

  /// Levels start at 1 and each costs `xpPerLevel`.
  int get level => (xp ~/ AppConstants.xpPerLevel) + 1;

  int get xpIntoLevel => xp % AppConstants.xpPerLevel;

  int get xpForNextLevel => AppConstants.xpPerLevel;

  double get levelProgress => xpIntoLevel / AppConstants.xpPerLevel;

  String get displayName => name.trim().isEmpty ? 'there' : name.trim();

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  /// Minutes of waking time available in a day, used by the planner's
  /// capacity meter. Handles sleep times past midnight.
  int get wakingMinutes {
    final span = sleepMinutes - wakeMinutes;
    return span > 0 ? span : span + 24 * 60;
  }

  UserProfile copyWith({
    String? name,
    String? occupation,
    String? goal,
    String? avatarEmoji,
    int? wakeMinutes,
    int? sleepMinutes,
    int? workStartMinutes,
    int? workEndMinutes,
    int? dailyTaskTarget,
    int? xp,
    bool? isPremium,
    bool? onboardingCompleted,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      occupation: occupation ?? this.occupation,
      goal: goal ?? this.goal,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      dailyTaskTarget: dailyTaskTarget ?? this.dailyTaskTarget,
      xp: xp ?? this.xp,
      isPremium: isPremium ?? this.isPremium,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.name == name &&
          other.occupation == occupation &&
          other.goal == goal &&
          other.avatarEmoji == avatarEmoji &&
          other.wakeMinutes == wakeMinutes &&
          other.sleepMinutes == sleepMinutes &&
          other.workStartMinutes == workStartMinutes &&
          other.workEndMinutes == workEndMinutes &&
          other.dailyTaskTarget == dailyTaskTarget &&
          other.xp == xp &&
          other.isPremium == isPremium &&
          other.onboardingCompleted == onboardingCompleted;

  @override
  int get hashCode => Object.hash(
    name,
    occupation,
    goal,
    avatarEmoji,
    wakeMinutes,
    sleepMinutes,
    workStartMinutes,
    workEndMinutes,
    dailyTaskTarget,
    xp,
    isPremium,
    onboardingCompleted,
  );
}

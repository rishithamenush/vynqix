import 'package:sqflite/sqflite.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/key_value_dao.dart';
import 'change_notifier_repository.dart';

class ProfileRepositoryImpl
    with ChangeNotifierRepository
    implements ProfileRepository {
  ProfileRepositoryImpl(this._db) : _kv = KeyValueDao(_db);

  final AppDatabase _db;
  final KeyValueDao _kv;

  static const _key = 'profile';

  /// Cached so the many widgets reading the profile do not each hit SQLite.
  UserProfile? _cache;

  @override
  Future<UserProfile> get() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _kv.readJson(_key);
    final profile = json == null ? const UserProfile() : _fromJson(json);
    _cache = profile;
    return profile;
  }

  @override
  void invalidateCache() => _cache = null;

  @override
  Future<void> save(UserProfile profile) async {
    _cache = profile;
    await _kv.writeJson(_key, _toJson(profile));
    notifyChanged();
  }

  @override
  Future<UserProfile> addXp(int amount) async {
    final current = await get();
    final updated = current.copyWith(xp: current.xp + amount);
    await save(updated);
    return updated;
  }

  @override
  Future<Map<String, DateTime>> unlockedAchievements() async {
    final rows = await _db.db.query(AppDatabase.tableAchievements);
    return {
      for (final row in rows)
        row['id'] as String: DateTime.fromMillisecondsSinceEpoch(
          row['unlockedAt'] as int,
        ),
    };
  }

  @override
  Future<void> unlockAchievement(String id, DateTime at) async {
    await _db.db.insert(AppDatabase.tableAchievements, {
      'id': id,
      'unlockedAt': at.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    notifyChanged();
  }

  static Map<String, dynamic> _toJson(UserProfile p) => {
    'name': p.name,
    'occupation': p.occupation,
    'goal': p.goal,
    'avatarIconKey': p.avatarIconKey,
    'wakeMinutes': p.wakeMinutes,
    'sleepMinutes': p.sleepMinutes,
    'workStartMinutes': p.workStartMinutes,
    'workEndMinutes': p.workEndMinutes,
    'dailyTaskTarget': p.dailyTaskTarget,
    'xp': p.xp,
    'isPremium': p.isPremium,
    'onboardingCompleted': p.onboardingCompleted,
    'createdAt': p.createdAt?.millisecondsSinceEpoch,
  };

  static UserProfile _fromJson(Map<String, dynamic> j) {
    const fallback = UserProfile();
    return UserProfile(
      name: j['name'] as String? ?? '',
      occupation: j['occupation'] as String? ?? '',
      goal: j['goal'] as String? ?? '',
      avatarIconKey:
          j['avatarIconKey'] as String? ?? fallback.avatarIconKey,
      wakeMinutes: j['wakeMinutes'] as int? ?? fallback.wakeMinutes,
      sleepMinutes: j['sleepMinutes'] as int? ?? fallback.sleepMinutes,
      workStartMinutes:
          j['workStartMinutes'] as int? ?? fallback.workStartMinutes,
      workEndMinutes: j['workEndMinutes'] as int? ?? fallback.workEndMinutes,
      dailyTaskTarget: j['dailyTaskTarget'] as int? ?? fallback.dailyTaskTarget,
      xp: j['xp'] as int? ?? 0,
      isPremium: j['isPremium'] as bool? ?? false,
      onboardingCompleted: j['onboardingCompleted'] as bool? ?? false,
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    );
  }
}

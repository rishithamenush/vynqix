import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/repositories.dart';
import '../local/app_database.dart';
import '../local/key_value_dao.dart';
import 'change_notifier_repository.dart';

class SettingsRepositoryImpl
    with ChangeNotifierRepository
    implements SettingsRepository {
  SettingsRepositoryImpl(AppDatabase db) : _kv = KeyValueDao(db);

  final KeyValueDao _kv;

  static const _key = 'settings';

  AppSettings? _cache;

  @override
  Future<AppSettings> get() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _kv.readJson(_key);
    final settings = json == null ? const AppSettings() : _fromJson(json);
    _cache = settings;
    return settings;
  }

  @override
  void invalidateCache() => _cache = null;

  @override
  Future<void> save(AppSettings settings) async {
    _cache = settings;
    await _kv.writeJson(_key, _toJson(settings));
    notifyChanged();
  }

  static Map<String, dynamic> _toJson(AppSettings s) => {
    'use24HourClock': s.use24HourClock,
    'notificationsEnabled': s.notificationsEnabled,
    'dailyPlanReminderMinutes': s.dailyPlanReminderMinutes,
    'reviewReminderMinutes': s.reviewReminderMinutes,
    'focusMinutes': s.focusMinutes,
    'shortBreakMinutes': s.shortBreakMinutes,
    'longBreakMinutes': s.longBreakMinutes,
    'autoStartBreaks': s.autoStartBreaks,
    'keepScreenAwakeInFocus': s.keepScreenAwakeInFocus,
    'hapticsEnabled': s.hapticsEnabled,
    'soundEnabled': s.soundEnabled,
    'showCompletedTasks': s.showCompletedTasks,
    'rolloverUnfinished': s.rolloverUnfinished,
  };

  static AppSettings _fromJson(Map<String, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      use24HourClock: j['use24HourClock'] as bool? ?? d.use24HourClock,
      notificationsEnabled:
          j['notificationsEnabled'] as bool? ?? d.notificationsEnabled,
      dailyPlanReminderMinutes:
          j['dailyPlanReminderMinutes'] as int? ?? d.dailyPlanReminderMinutes,
      reviewReminderMinutes:
          j['reviewReminderMinutes'] as int? ?? d.reviewReminderMinutes,
      focusMinutes: j['focusMinutes'] as int? ?? d.focusMinutes,
      shortBreakMinutes: j['shortBreakMinutes'] as int? ?? d.shortBreakMinutes,
      longBreakMinutes: j['longBreakMinutes'] as int? ?? d.longBreakMinutes,
      autoStartBreaks: j['autoStartBreaks'] as bool? ?? d.autoStartBreaks,
      keepScreenAwakeInFocus:
          j['keepScreenAwakeInFocus'] as bool? ?? d.keepScreenAwakeInFocus,
      hapticsEnabled: j['hapticsEnabled'] as bool? ?? d.hapticsEnabled,
      soundEnabled: j['soundEnabled'] as bool? ?? d.soundEnabled,
      showCompletedTasks:
          j['showCompletedTasks'] as bool? ?? d.showCompletedTasks,
      rolloverUnfinished:
          j['rolloverUnfinished'] as bool? ?? d.rolloverUnfinished,
    );
  }
}

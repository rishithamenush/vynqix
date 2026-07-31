import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../domain/enums/task_enums.dart';

/// The app's icon vocabulary.
///
/// Nothing in the app renders an emoji. Emoji are inconsistent across
/// platforms and OS versions, cannot inherit colour or weight, and read as
/// decoration rather than interface — so every glyph the user sees comes from
/// Phosphor, which ships as a bundled font and therefore stays offline.
///
/// Anything persisted stores a **stable string key**, never an [IconData].
/// That keeps the domain layer framework-free and means the icon set can be
/// swapped later without a database migration.
abstract final class AppIcons {
  /// Fallback used whenever a stored key is unknown — for example after an
  /// icon is retired from [taskIcons].
  static const fallback = PhosphorIconsRegular.circle;

  // ---------------------------------------------------------------------
  // Task icons — the picker in the task editor
  // ---------------------------------------------------------------------

  /// Ordered catalogue offered by the task editor. Keys are persisted in
  /// `tasks.iconKey`, so **never rename one**; retire it instead.
  static const taskIcons = <TaskIconOption>[
    TaskIconOption('task', 'Task', PhosphorIconsRegular.checkCircle),
    TaskIconOption('work', 'Work', PhosphorIconsRegular.briefcase),
    TaskIconOption('study', 'Study', PhosphorIconsRegular.graduationCap),
    TaskIconOption('read', 'Read', PhosphorIconsRegular.book),
    TaskIconOption('write', 'Write', PhosphorIconsRegular.pencilRuler),
    TaskIconOption('code', 'Code', PhosphorIconsRegular.code),
    TaskIconOption('design', 'Design', PhosphorIconsRegular.palette),
    TaskIconOption('meeting', 'Meeting', PhosphorIconsRegular.users),
    TaskIconOption('call', 'Call', PhosphorIconsRegular.phoneCall),
    TaskIconOption('email', 'Email', PhosphorIconsRegular.envelopeSimple),
    TaskIconOption('workout', 'Workout', PhosphorIconsRegular.barbell),
    TaskIconOption('health', 'Health', PhosphorIconsRegular.heartbeat),
    TaskIconOption('meditate', 'Meditate', PhosphorIconsRegular.flowerLotus),
    TaskIconOption('meal', 'Meal', PhosphorIconsRegular.forkKnife),
    TaskIconOption('coffee', 'Break', PhosphorIconsRegular.coffee),
    TaskIconOption('home', 'Home', PhosphorIconsRegular.house),
    TaskIconOption('shopping', 'Shopping', PhosphorIconsRegular.shoppingBag),
    TaskIconOption('money', 'Finance', PhosphorIconsRegular.currencyDollar),
    TaskIconOption('travel', 'Travel', PhosphorIconsRegular.airplaneTilt),
    TaskIconOption('music', 'Music', PhosphorIconsRegular.musicNotes),
    TaskIconOption('idea', 'Idea', PhosphorIconsRegular.lightbulb),
    TaskIconOption('goal', 'Goal', PhosphorIconsRegular.target),
    TaskIconOption('urgent', 'Urgent', PhosphorIconsRegular.fire),
    TaskIconOption('note', 'Note', PhosphorIconsRegular.note),
  ];

  /// Resolves a persisted task icon key. Returns `null` when [key] is null so
  /// callers can fall back to the category icon.
  static IconData? taskIcon(String? key) {
    if (key == null) return null;
    for (final option in taskIcons) {
      if (option.key == key) return option.icon;
    }
    return fallback;
  }

  // ---------------------------------------------------------------------
  // Profile avatars
  // ---------------------------------------------------------------------

  /// Avatar choices offered during onboarding. Keys persist in the profile.
  static const avatarIcons = <TaskIconOption>[
    TaskIconOption('person', 'Person', PhosphorIconsFill.person),
    TaskIconOption('rocket', 'Rocket', PhosphorIconsFill.rocket),
    TaskIconOption('brain', 'Brain', PhosphorIconsFill.brain),
    TaskIconOption('plant', 'Plant', PhosphorIconsFill.plant),
    TaskIconOption('fire', 'Fire', PhosphorIconsFill.fire),
    TaskIconOption('star', 'Star', PhosphorIconsFill.star),
    TaskIconOption('mountain', 'Mountain', PhosphorIconsFill.mountains),
    TaskIconOption('lightning', 'Lightning', PhosphorIconsFill.lightning),
  ];

  static IconData avatarIcon(String? key) {
    for (final option in avatarIcons) {
      if (option.key == key) return option.icon;
    }
    return PhosphorIconsFill.person;
  }

  // ---------------------------------------------------------------------
  // Domain enums
  // ---------------------------------------------------------------------

  static IconData mood(Mood mood) => switch (mood) {
    Mood.great => PhosphorIconsFill.smileyWink,
    Mood.good => PhosphorIconsFill.smiley,
    Mood.okay => PhosphorIconsFill.smileyMeh,
    Mood.bad => PhosphorIconsFill.smileySad,
    Mood.terrible => PhosphorIconsFill.smileyXEyes,
  };

  static IconData energy(EnergyLevel level) => switch (level) {
    EnergyLevel.high => PhosphorIconsRegular.lightning,
    EnergyLevel.medium => PhosphorIconsRegular.batteryHigh,
    EnergyLevel.low => PhosphorIconsRegular.batteryLow,
  };

  // ---------------------------------------------------------------------
  // Achievements and insights — keyed so the domain layer stays pure Dart
  // ---------------------------------------------------------------------

  static const _badges = <String, IconData>{
    'seedling': PhosphorIconsFill.plant,
    'steps': PhosphorIconsFill.footprints,
    'medal': PhosphorIconsFill.medal,
    'robot': PhosphorIconsFill.robot,
    'fire': PhosphorIconsFill.fire,
    'calendar': PhosphorIconsFill.calendarCheck,
    'diamond': PhosphorIconsFill.diamond,
    'target': PhosphorIconsFill.target,
    'wave': PhosphorIconsFill.waves,
    'hourglass': PhosphorIconsFill.hourglass,
    'notebook': PhosphorIconsFill.notebook,
    'sparkle': PhosphorIconsFill.sparkle,
    'crown': PhosphorIconsFill.crown,
    'star': PhosphorIconsFill.star,
    'trophy': PhosphorIconsFill.trophy,
  };

  static IconData badge(String key) => _badges[key] ?? PhosphorIconsFill.seal;

  static const _insights = <String, IconData>{
    'seedling': PhosphorIconsRegular.plant,
    'target': PhosphorIconsRegular.target,
    'balance': PhosphorIconsRegular.scales,
    'trendUp': PhosphorIconsRegular.trendUp,
    'clock': PhosphorIconsRegular.clockUser,
    'compass': PhosphorIconsRegular.compass,
    'focus': PhosphorIconsRegular.flowerLotus,
    'timer': PhosphorIconsRegular.timer,
    'fire': PhosphorIconsRegular.fire,
    'wave': PhosphorIconsRegular.waveSine,
    'sun': PhosphorIconsRegular.sun,
    'rain': PhosphorIconsRegular.cloudRain,
    'sparkle': PhosphorIconsRegular.sparkle,
    'capacity': PhosphorIconsRegular.gauge,
  };

  static IconData insight(String key) =>
      _insights[key] ?? PhosphorIconsRegular.lightbulb;
}

/// One selectable icon: a stable [key] for storage, a [label] for
/// accessibility, and the [icon] itself.
@immutable
class TaskIconOption {
  const TaskIconOption(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

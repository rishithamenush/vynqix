import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local/app_database.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/providers/task_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // The database is opened before the first frame so no screen has to handle
  // a "not ready yet" state.
  final database = await AppDatabase.open();

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(database)],
  );

  await _runStartupTasks(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VynqixApp(),
    ),
  );
}

/// Work that must happen once per launch, before the first frame.
Future<void> _runStartupTasks(ProviderContainer container) async {
  // Warm the singletons the router and theme read synchronously.
  await container.read(settingsProvider.future);
  final profile = await container.read(profileProvider.future);

  if (!profile.onboardingCompleted) return;

  // Yesterday's leftovers are either carried forward or marked missed, so the
  // user never opens the app to a stale plan.
  final settings = container.read(settingsValueProvider);
  await container
      .read(taskControllerProvider)
      .rolloverUnfinished(moveToToday: settings.rolloverUnfinished);
}

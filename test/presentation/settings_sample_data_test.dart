import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/theme/app_theme.dart';
import 'package:vynqix/core/utils/date_x.dart';
import 'package:vynqix/data/local/app_database.dart';
import 'package:vynqix/presentation/features/settings/settings_screen.dart';
import 'package:vynqix/presentation/providers/app_providers.dart';

/// Drives the real Settings row end to end, so "Load sample data" is proven to
/// reach the database rather than just being wired up on paper.
void main() {
  testWidgets('Load sample data fills an empty database', (tester) async {
    final db = await AppDatabase.open(inMemory: true);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await container.read(settingsProvider.future);
    await container.read(profileProvider.future);

    final tasks = container.read(taskRepositoryProvider);
    expect(await tasks.getAll(), isEmpty);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    final row = find.text('Load sample data');
    await tester.scrollUntilVisible(row, 300);
    await tester.tap(row);
    await tester.pump();

    // The confirmation, then the seed run behind its spinner.
    expect(find.text('Load sample data?'), findsOneWidget);
    await tester.tap(find.text('Replace with sample data'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    final seeded = await tasks.getAll();
    expect(seeded.length, greaterThan(1000));
    expect(await tasks.getByDay(DateX.todayKey), isNotEmpty);

    final profile = await container.read(profileRepositoryProvider).get();
    expect(profile.occupation, 'Software Engineer');
    expect(profile.onboardingCompleted, isTrue);
  });
}

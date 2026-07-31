import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/app/app.dart';
import 'package:vynqix/core/utils/date_x.dart';
import 'package:vynqix/data/local/app_database.dart';
import 'package:vynqix/presentation/providers/app_providers.dart';
import 'package:vynqix/presentation/providers/task_providers.dart';

/// End-to-end smoke tests over the real widget tree and a real (in-memory)
/// database — the same wiring `main.dart` uses.
///
/// Note: these deliberately avoid `pumpAndSettle`. The app runs two
/// intentionally endless animations — the skeleton shimmer and the 30-second
/// clock stream — so the tree never reaches a settled state. Explicit pumps
/// are the correct tool here.
void main() {
  /// Builds a container wired to a fresh in-memory database, and registers
  /// teardown with the tester so timers are cancelled before flutter_test
  /// checks for leaks.
  Future<ProviderContainer> makeContainer(WidgetTester tester) async {
    final db = await AppDatabase.open(inMemory: true);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    // Warm the singletons the router and theme read synchronously.
    await container.read(settingsProvider.future);
    await container.read(profileProvider.future);
    return container;
  }

  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
    // flutter_test defaults to an 800x600 surface, which is wide enough to
    // trigger the tablet rail. Pin a phone size so these cover the compact
    // layout; the rail has its own test below.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VynqixApp(),
      ),
    );
    // Three frames is enough for the router to resolve and the first round of
    // FutureProviders to deliver.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a first launch lands on the welcome screen', (tester) async {
    final container = await makeContainer(tester);
    await pumpApp(tester, container);

    expect(find.text('Vynqix'), findsOneWidget);
    expect(find.text('Plan tomorrow. Master today.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('completing onboarding reaches the home dashboard', (
    tester,
  ) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();
    await pumpApp(tester, container);

    // The bottom tab bar is present, so we are inside the shell.
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Empty state for a day with no tasks.
    expect(find.text('No tasks today'), findsOneWidget);
  });

  testWidgets('a saved task appears on the home list', (tester) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();

    final controller = container.read(taskControllerProvider);
    await controller.create(
      controller
          .draft(dayKey: DateX.todayKey)
          .copyWith(title: 'Ship the build'),
    );

    await pumpApp(tester, container);

    expect(find.text('Ship the build'), findsWidgets);
    expect(find.text('No tasks today'), findsNothing);
  });

  testWidgets('completing a task updates the day stats', (tester) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();

    final controller = container.read(taskControllerProvider);
    final task = controller
        .draft(dayKey: DateX.todayKey)
        .copyWith(title: 'One thing');
    await controller.create(task);
    await controller.toggleComplete(task);

    final saved = await container
        .read(taskRepositoryProvider)
        .getById(task.id);

    expect(saved!.isDone, isTrue);
    expect(saved.completedAt, isNotNull);

    // Completing a task awards XP through RewardsUseCase.
    final profile = await container.read(profileRepositoryProvider).get();
    expect(profile.xp, greaterThan(0));
  });

  testWidgets('a tablet width swaps the bottom bar for a side rail', (
    tester,
  ) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VynqixApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('a phone width keeps the bottom navigation bar', (tester) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();
    await pumpApp(tester, container);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('the app is pinned to the light theme', (tester) async {
    final container = await makeContainer(tester);
    await container.read(profileProvider.notifier).completeOnboarding();
    await pumpApp(tester, container);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme, isNotNull);
    // No dark theme is supplied, so the OS setting cannot flip the palette.
    expect(app.darkTheme, isNull);
    expect(app.theme!.brightness, Brightness.light);
  });
}

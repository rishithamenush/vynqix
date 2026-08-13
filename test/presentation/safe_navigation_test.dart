import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vynqix/app/router.dart';
import 'package:vynqix/core/utils/async_guard.dart';

/// Handlers pop after an `await`. If two copies of the same handler run — the
/// user tapped twice while the first write was still in flight — the second
/// `pop()` takes the screen underneath with it and the user lands somewhere
/// they never asked for. `popIfCurrent` makes that second pop a no-op.
void main() {
  setUp(NavThrottle.reset);

  /// A three-level stack: first -> second -> detail.
  ({GoRouter router, Widget app}) harness() {
    final router = GoRouter(
      initialLocation: '/first',
      routes: [
        GoRoute(path: '/first', builder: (_, _) => const _Screen('first')),
        GoRoute(
          path: '/second',
          builder: (_, _) => const _Screen('second'),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (context, _) {
                _detailContexts.add(context);
                return const _Screen('detail');
              },
            ),
          ],
        ),
      ],
    );
    return (router: router, app: MaterialApp.router(routerConfig: router));
  }

  testWidgets('a second popIfCurrent leaves the screen underneath alone', (
    tester,
  ) async {
    _detailContexts.clear();
    final h = harness();
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();

    h.router.push('/second');
    await tester.pumpAndSettle();
    h.router.push('/second/detail');
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);

    // Two pops from the same screen, as a double tap would produce.
    final detail = _detailContexts.last;
    detail.popIfCurrent();
    detail.popIfCurrent();
    await tester.pumpAndSettle();

    expect(
      find.text('second'),
      findsOneWidget,
      reason: 'the second pop must not unwind an extra route',
    );
    expect(find.text('first'), findsNothing);
  });

  testWidgets('an unguarded double pop does unwind two routes', (tester) async {
    // The behaviour `popIfCurrent` exists to prevent — if this ever stops
    // failing, the guard above is no longer proving anything.
    _detailContexts.clear();
    final h = harness();
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();

    h.router.push('/second');
    await tester.pumpAndSettle();
    h.router.push('/second/detail');
    await tester.pumpAndSettle();

    h.router.pop();
    h.router.pop();
    await tester.pumpAndSettle();

    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('pushOnce stacks one screen for a double tap', (tester) async {
    _detailContexts.clear();
    final h = harness();
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();

    final context = tester.element(find.text('first'));
    context.pushOnce('/second');
    context.pushOnce('/second');
    await tester.pumpAndSettle();

    expect(find.text('second'), findsOneWidget);

    // One pop must reach the first screen again: had two copies been pushed,
    // the user would still be looking at '/second'.
    h.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
  });
}

/// Contexts handed out by the detail route's builder, newest last.
final List<BuildContext> _detailContexts = [];

class _Screen extends StatelessWidget {
  const _Screen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

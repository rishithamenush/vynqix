import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vynqix/core/utils/async_guard.dart';

void main() {
  setUp(() {
    OneShot.reset();
    NavThrottle.reset();
  });

  group('OneShot', () {
    test('a second call while the first is in flight is dropped', () async {
      final gate = Completer<void>();
      var runs = 0;

      final first = OneShot.run('tag', () async {
        runs++;
        await gate.future;
      });
      final second = OneShot.run('tag', () async => runs++);

      expect(await second, isFalse, reason: 'second call should not run');
      expect(runs, 1);

      gate.complete();
      expect(await first, isTrue);
    });

    test('the tag is free again once the first call finishes', () async {
      var runs = 0;
      await OneShot.run('tag', () async => runs++);
      await OneShot.run('tag', () async => runs++);
      expect(runs, 2);
    });

    test('different tags do not block each other', () async {
      final gate = Completer<void>();
      var runs = 0;

      unawaited(OneShot.run('a', () async {
        runs++;
        await gate.future;
      }));
      expect(await OneShot.run('b', () async => runs++), isTrue);
      expect(runs, 2);
      gate.complete();
    });

    test('a throwing action releases its tag instead of wedging it', () async {
      await expectLater(
        OneShot.run('tag', () async => throw StateError('boom')),
        throwsStateError,
      );
      expect(OneShot.isRunning('tag'), isFalse);
      expect(await OneShot.run('tag', () async {}), isTrue);
    });
  });

  group('NavThrottle', () {
    final t0 = DateTime(2026, 1, 1, 9);

    test('swallows a repeat tap on the same target inside the window', () {
      expect(NavThrottle.allow('/task/new', now: t0), isTrue);
      expect(
        NavThrottle.allow('/task/new', now: t0.add(const Duration(milliseconds: 80))),
        isFalse,
      );
    });

    test('lets the same target through once the window has passed', () {
      expect(NavThrottle.allow('/task/new', now: t0), isTrue);
      expect(
        NavThrottle.allow('/task/new', now: t0.add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('never blocks a different destination', () {
      expect(NavThrottle.allow('/task/new', now: t0), isTrue);
      expect(
        NavThrottle.allow('/settings', now: t0.add(const Duration(milliseconds: 10))),
        isTrue,
      );
    });
  });
}

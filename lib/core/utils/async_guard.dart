import 'package:meta/meta.dart';

/// Drops taps that arrive while an earlier one is still running.
///
/// Every async handler in the app has the same shape: read something, `await`
/// a dialog or a write, then act on the result. Between the `await` and the
/// act the widget is still mounted and still tappable, so a second tap starts
/// a second copy of the same flow. What that costs depends on the flow — a
/// duplicated row, two `pop()`s where one eats the screen underneath, or a
/// modal barrier pushed twice and dismissed once, which locks the entire app.
///
/// Guarding at the widget (a `bool _busy` in a [State]) only works for
/// stateful screens, and most of these handlers hang off `ConsumerWidget`s.
/// Keying on a tag instead works everywhere and needs no rebuild.
abstract final class OneShot {
  static final Set<String> _inFlight = <String>{};

  /// Runs [action] unless another call with the same [tag] is still running.
  ///
  /// Returns whether [action] ran. The tag is released even when [action]
  /// throws — a flow that fails must not wedge its button forever.
  static Future<bool> run(String tag, Future<void> Function() action) async {
    if (!_inFlight.add(tag)) return false;
    try {
      await action();
      return true;
    } finally {
      _inFlight.remove(tag);
    }
  }

  /// Whether [tag] is mid-flight. Useful for showing a spinner on the control.
  static bool isRunning(String tag) => _inFlight.contains(tag);

  @visibleForTesting
  static void reset() => _inFlight.clear();
}

/// Swallows repeat navigations to the same place in quick succession.
///
/// Navigation is not guarded by [OneShot]: `push` completes only when the
/// pushed screen pops, so an in-flight guard would keep the source button
/// dead for as long as the destination is open — and would wedge it for good
/// if that route were ever removed without completing. A short window is the
/// right tool, because the failure being prevented is a double tap, not a
/// long-running action.
abstract final class NavThrottle {
  /// Long enough to cover a double tap, short enough that a deliberate
  /// re-entry after closing a screen still goes through.
  static const window = Duration(milliseconds: 600);

  static String? _lastTarget;
  static DateTime? _lastAt;

  /// Whether a navigation to [target] should proceed.
  static bool allow(String target, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final last = _lastAt;
    if (_lastTarget == target && last != null && at.difference(last) < window) {
      return false;
    }
    _lastTarget = target;
    _lastAt = at;
    return true;
  }

  @visibleForTesting
  static void reset() {
    _lastTarget = null;
    _lastAt = null;
  }
}

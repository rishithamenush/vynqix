import 'dart:async';

import '../../domain/repositories/repositories.dart';

/// Shared plumbing for the [Repository.changes] contract.
///
/// Implementations call [notifyChanged] after any successful write; providers
/// listen and re-query. One broadcast controller per repository keeps the
/// invalidation granular enough to avoid rebuilding unrelated screens.
mixin ChangeNotifierRepository implements Repository {
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  void notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// No-op by default: repositories that hold no cache have nothing to drop.
  /// Caching implementations override this.
  @override
  void invalidateCache() {}

  Future<void> dispose() => _changes.close();
}

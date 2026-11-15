import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/models/event.dart';
import '../../events/providers/events_provider.dart';
import '../../feed/models/feed_filter.dart';
import '../../feed/models/money.dart';
import '../data/shopping_sessions_storage.dart';
import '../models/shopping_session.dart';

final shoppingSessionsStorageProvider = Provider<ShoppingSessionsStorage>(
  (ref) => ShoppingSessionsStorage(),
);

/// The Shopper's Shopping Sessions: many kept, one active at a time. Every
/// change is stored on the device; a write that fails is retried with the
/// next change, and the change still shows until the app closes.
class ShoppingSessionsNotifier extends AsyncNotifier<ShoppingSessions> {
  Future<void> _lastWrite = Future.value();

  @override
  Future<ShoppingSessions> build() async {
    try {
      return await ref.read(shoppingSessionsStorageProvider).load();
    } on Object {
      // Unreadable storage must not stop the app: start with none.
      return const ShoppingSessions();
    }
  }

  /// Creates a session and makes it the active one.
  Future<ShoppingSession> create({
    required String goal,
    String? name,
    String? category,
    String? brand,
    Money? maxPrice,
  }) async {
    final current = await _current();
    final trimmedName = name?.trim() ?? '';
    final session = ShoppingSession(
      id: _newId(),
      name: trimmedName.isNotEmpty ? trimmedName : _defaultName(goal),
      goal: goal.trim(),
      category: category,
      brand: brand,
      maxPrice: maxPrice,
    );
    _endActive(current);
    await _save(
      ShoppingSessions(
        sessions: [session, ...current.sessions],
        activeId: session.id,
      ),
    );
    _recordStart(session);
    return session;
  }

  /// Makes [id] the active session, so the feed shows it.
  Future<void> start(String id) async {
    final current = await _current();
    if (current.activeId == id) return;
    final session = _find(current, id);
    if (session == null) return;

    _endActive(current);
    await _save(ShoppingSessions(sessions: current.sessions, activeId: id));
    _recordStart(session);
  }

  /// Back to For You. The session is kept.
  Future<void> end() async {
    final current = await _current();
    if (current.activeId == null) return;

    _endActive(current);
    await _save(ShoppingSessions(sessions: current.sessions));
  }

  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _update(id, (session) => session.copyWith(name: trimmed));
  }

  /// New filters for [id]. Its feed starts again from the top.
  Future<void> changeFilters(
    String id, {
    required String goal,
    String? category,
    String? brand,
    Money? maxPrice,
  }) => _update(
    id,
    (session) => session.copyWith(
      goal: goal.trim(),
      category: () => category,
      brand: () => brand,
      maxPrice: () => maxPrice,
    ),
  );

  /// Forgets what the Shopper did in [id]: same name and filters, a fresh
  /// start for its taste and its feed.
  Future<void> reset(String id) async {
    final current = await _current();
    final session = _find(current, id);
    if (session == null) return;

    final fresh = session.copyWith(id: _newId());
    final wasActive = current.activeId == id;
    if (wasActive) _recordEnd(session);
    await _save(
      ShoppingSessions(
        sessions: [for (final s in current.sessions) s.id == id ? fresh : s],
        activeId: wasActive ? fresh.id : current.activeId,
      ),
    );
    if (wasActive) _recordStart(fresh);
  }

  /// Deletes [id]. Deleting the active session goes back to For You.
  Future<void> delete(String id) async {
    final current = await _current();
    final session = _find(current, id);
    if (session == null) return;

    if (current.activeId == id) _recordEnd(session);
    await _save(
      ShoppingSessions(
        sessions: [
          for (final s in current.sessions)
            if (s.id != id) s,
        ],
        activeId: current.activeId == id ? null : current.activeId,
      ),
    );
  }

  Future<void> _update(
    String id,
    ShoppingSession Function(ShoppingSession session) change,
  ) async {
    final current = await _current();
    if (_find(current, id) == null) return;

    await _save(
      ShoppingSessions(
        sessions: [
          for (final s in current.sessions) s.id == id ? change(s) : s,
        ],
        activeId: current.activeId,
      ),
    );
  }

  Future<ShoppingSessions> _current() async {
    if (!state.hasValue) {
      try {
        await future;
      } on Object {
        // build() never fails.
      }
    }
    return state.value ?? const ShoppingSessions();
  }

  Future<void> _save(ShoppingSessions updated) async {
    if (!ref.mounted) return;
    state = AsyncData(updated);

    final storage = ref.read(shoppingSessionsStorageProvider);
    final write = _lastWrite.then((_) => storage.save(updated));
    _lastWrite = write.catchError((Object _) {});
    await _lastWrite;
  }

  static ShoppingSession? _find(ShoppingSessions sessions, String id) {
    for (final session in sessions.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  String _newId() => 'session-${ref.read(eventIdsProvider)()}';

  static String _defaultName(String goal) {
    final trimmed = goal.trim();
    return trimmed.isEmpty ? 'Shopping session' : trimmed;
  }

  void _endActive(ShoppingSessions current) {
    if (current.active case final active?) _recordEnd(active);
  }

  void _recordStart(ShoppingSession session) =>
      _record(NewEvent(EventType.sessionStart, sessionId: session.id));

  void _recordEnd(ShoppingSession session) =>
      _record(NewEvent(EventType.sessionEnd, sessionId: session.id));

  void _record(NewEvent event) =>
      ref.read(eventsLogProvider.notifier).record(event);
}

final shoppingSessionsProvider =
    AsyncNotifierProvider<ShoppingSessionsNotifier, ShoppingSessions>(
      ShoppingSessionsNotifier.new,
    );

/// The active Shopping Session, or null while For You shows.
final activeShoppingSessionProvider = Provider<ShoppingSession?>(
  (ref) => ref.watch(shoppingSessionsProvider).value?.active,
);

/// The active session's feed filter, or null for For You. Only changes when
/// the filters do, so renaming a session doesn't reload its feed.
final activeSessionFilterProvider = Provider<FeedFilter?>(
  (ref) => ref.watch(activeShoppingSessionProvider)?.filter,
);

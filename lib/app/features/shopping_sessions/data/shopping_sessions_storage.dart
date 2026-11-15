import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopping_session.dart';

/// Keeps the Shopper's Shopping Sessions, and which one is active, on the
/// device.
class ShoppingSessionsStorage {
  static const String _key = 'shopping_sessions';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// What is stored. Anything unreadable is left out.
  Future<ShoppingSessions> load() async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return const ShoppingSessions();

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return const ShoppingSessions();
    }
    if (decoded is! Map) return const ShoppingSessions();

    final list = decoded['sessions'];
    final sessions = [
      if (list is List)
        for (final item in list) ?ShoppingSession.fromJson(item),
    ];
    final activeId = decoded['activeId'];
    return ShoppingSessions(
      sessions: sessions,
      activeId: sessions.any((session) => session.id == activeId)
          ? activeId as String
          : null,
    );
  }

  /// Replaces everything stored with [sessions].
  Future<void> save(ShoppingSessions sessions) => _prefs.setString(
    _key,
    jsonEncode({
      'sessions': [for (final session in sessions.sessions) session.toJson()],
      'activeId': ?sessions.activeId,
    }),
  );
}

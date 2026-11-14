import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';

/// Keeps the buffer of recorded Events on the device, oldest first, until
/// they are sent to the backend.
class EventsStorage {
  static const String _key = 'events_buffer';

  /// Made on each use, so a device without a store (some tests) fails the
  /// read or write, which the Events log tolerates, instead of failing
  /// whoever first asks for the storage.
  SharedPreferencesAsync get _prefs => SharedPreferencesAsync();

  /// Oldest first, as last stored. An entry that can't be read is left out
  /// rather than losing every other Event with it.
  Future<List<Event>> load() async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return const [];

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    final events = <Event>[];
    for (final entry in decoded) {
      try {
        events.add(Event.fromJson(entry));
      } on FormatException {
        continue;
      }
    }
    return events;
  }

  /// Replaces everything stored with [events].
  Future<void> save(List<Event> events) => _prefs.setString(
    _key,
    jsonEncode([for (final event in events) event.toJson()]),
  );
}

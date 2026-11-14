import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the IDs of the Products the Shopper marked Not interested on the
/// device, so they stay hidden after a restart.
class NotInterestedStorage {
  static const String _key = 'not_interested_products';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Every Product ID stored. Anything unreadable is left out.
  Future<Set<String>> load() async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return const {};

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return const {};
    }
    if (decoded is! List) return const {};
    return {
      for (final id in decoded)
        if (id is String) id,
    };
  }

  /// Replaces everything stored with [productIds].
  Future<void> save(Set<String> productIds) =>
      _prefs.setString(_key, jsonEncode(productIds.toList()));
}

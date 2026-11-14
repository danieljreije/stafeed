import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_product.dart';

/// Keeps the Shopper's Saved Products, with their snapshots, on the device.
class SavedProductsStorage {
  static const String _key = 'saved_products';

  /// Where the app kept bare Product IDs before Saved Products had
  /// snapshots. Those can't be shown without the feed, so they are dropped.
  static const String _legacyIdsKey = 'saved_product_ids';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Newest first, as last stored. An entry that can't be read is left out
  /// rather than losing every other Saved Product with it.
  Future<List<SavedProduct>> load() async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return const [];

    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];

    final saved = <SavedProduct>[];
    for (final entry in decoded) {
      try {
        saved.add(SavedProduct.fromJson(entry));
      } on FormatException {
        continue;
      }
    }
    return saved;
  }

  /// Replaces everything stored with [savedProducts].
  Future<void> save(List<SavedProduct> savedProducts) async {
    await _prefs.setString(
      _key,
      jsonEncode([for (final saved in savedProducts) saved.toJson()]),
    );
    await _prefs.remove(_legacyIdsKey);
  }
}

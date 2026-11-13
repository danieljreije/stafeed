import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/shopper_config.dart';

/// Keeps the Shopper's onboarding choices on the device.
class ShopperConfigStorage {
  static const String _key = 'shopper_config';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  /// Null when the Shopper hasn't finished onboarding, or when what is
  /// stored can't be read.
  Future<ShopperConfig?> load() async {
    final stored = await _prefs.getString(_key);
    if (stored == null) return null;

    try {
      return ShopperConfig.fromJson(jsonDecode(stored));
    } on FormatException {
      return null;
    }
  }

  Future<void> save(ShopperConfig config) async {
    await _prefs.setString(_key, jsonEncode(config.toJson()));
  }
}

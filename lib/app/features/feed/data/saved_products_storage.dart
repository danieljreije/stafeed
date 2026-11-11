import 'package:shared_preferences/shared_preferences.dart';

class SavedProductsStorage {
  static const String _savedProductsKey = 'saved_product_ids';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<Set<String>> loadSavedProductIds() async {
    final ids = await _prefs.getStringList(_savedProductsKey);

    return ids?.toSet() ?? {};
  }

  Future<void> saveProductIds(Set<String> ids) async {
    await _prefs.setStringList(_savedProductsKey, ids.toList());
  }

  Future<void> clearSavedProducts() async {
    await _prefs.remove(_savedProductsKey);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_products_storage.dart';

final savedProductsStorageProvider = Provider<SavedProductsStorage>((ref) {
  return SavedProductsStorage();
});

class SavedProductsNotifier extends AsyncNotifier<Set<String>> {
  late final SavedProductsStorage _storage;

  @override
  Future<Set<String>> build() async {
    _storage = ref.read(savedProductsStorageProvider);

    return _storage.loadSavedProductIds();
  }

  Future<void> toggleProduct(String productId) async {
    final currentIds = state.requireValue;

    final updatedIds = Set<String>.from(currentIds);

    if (updatedIds.contains(productId)) {
      updatedIds.remove(productId);
    } else {
      updatedIds.add(productId);
    }

    state = AsyncData(updatedIds);

    await _storage.saveProductIds(updatedIds);
  }

  Future<void> clear() async {
    state = const AsyncData(<String>{});

    await _storage.clearSavedProducts();
  }
}

final savedProductsProvider =
    AsyncNotifierProvider<SavedProductsNotifier, Set<String>>(
      SavedProductsNotifier.new,
    );

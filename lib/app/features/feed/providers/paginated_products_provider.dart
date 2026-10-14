import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paginated_products.dart';
import 'products_provider.dart';
import 'feed_filter_provider.dart';

class PaginatedProductsNotifier extends AsyncNotifier<PaginatedProducts> {
  static const int pageSize = 10;

  @override
  @override
  Future<PaginatedProducts> build() async {
    final repository = ref.read(productRepositoryProvider);
    final filter = ref.watch(feedFilterProvider);

    final products = await repository.getProducts(
      limit: pageSize,
      skip: 0,
      category: filter.category,
      query: filter.query,
    );

    return PaginatedProducts(
      products: products,
      nextSkip: products.length,
      hasMore: products.length == pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;

    // Avoid requesting when not ready,
    // already loading, or at the end.
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    final filter = ref.read(feedFilterProvider);

    try {
      final repository = ref.read(productRepositoryProvider);

      final newProducts = await repository.getProducts(
        limit: pageSize,
        skip: current.nextSkip,
        category: filter.category,
        query: filter.query,
      );
      if (!ref.mounted || !identical(ref.read(feedFilterProvider), filter)) {
        return;
      }

      // Prevent duplicate product IDs in the feed.
      final existingIds = current.products.map((p) => p.id).toSet();

      final uniqueProducts = newProducts
          .where((product) => existingIds.add(product.id))
          .toList();

      state = AsyncData(
        current.copyWith(
          products: [...current.products, ...uniqueProducts],
          nextSkip: current.nextSkip + newProducts.length,
          hasMore: newProducts.length == pageSize,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      if (!ref.mounted || !identical(ref.read(feedFilterProvider), filter)) {
        return;
      }
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error.toString()),
      );
    }
  }
}

final paginatedProductsProvider =
    AsyncNotifierProvider<PaginatedProductsNotifier, PaginatedProducts>(
      PaginatedProductsNotifier.new,
    );

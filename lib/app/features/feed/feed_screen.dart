import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/product_card.dart';
import 'providers/saved_products_provider.dart';
import 'providers/paginated_products_provider.dart';
import 'providers/feed_filter_provider.dart';
import 'models/feed_filter.dart';
import 'widgets/feed_search_field.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    final productsAsync = ref.watch(paginatedProductsProvider);
    final filter = ref.watch(feedFilterProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load products: $error')),
              data: (feedState) {
                final products = feedState.products;

                if (products.isEmpty) {
                  return const Scaffold(
                    body: Center(child: Text('No products available.')),
                  );
                }
                return savedProducts.when(
                  loading: () {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  },

                  error: (error, stackTrace) {
                    return Scaffold(
                      body: Center(
                        child: Text('Could not load saved products: $error'),
                      ),
                    );
                  },

                  data: (savedProductIds) {
                    return Scaffold(
                      body: Stack(
                        children: [
                          PageView.builder(
                            key: ValueKey(
                              '${filter.category ?? 'all'}:${filter.query}',
                            ),
                            scrollDirection: Axis.vertical,
                            onPageChanged: (index) {
                              if (index >= products.length - 3 &&
                                  feedState.hasMore) {
                                ref
                                    .read(paginatedProductsProvider.notifier)
                                    .loadMore();
                              }
                            },
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];

                              return ProductCard(
                                product: product,
                                isSaved: savedProductIds.contains(product.id),
                                onSaveToggle: () {
                                  ref
                                      .read(savedProductsProvider.notifier)
                                      .toggleProduct(product.id);
                                },
                              );
                            },
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FeedSearchField(),

                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 50,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _categoryChip(ref, filter, 'All', null),
                                        _categoryChip(
                                          ref,
                                          filter,
                                          'Shoes',
                                          'mens-shoes',
                                        ),
                                        _categoryChip(
                                          ref,
                                          filter,
                                          'Phones',
                                          'smartphones',
                                        ),
                                        _categoryChip(
                                          ref,
                                          filter,
                                          'Beauty',
                                          'beauty',
                                        ),
                                        _categoryChip(
                                          ref,
                                          filter,
                                          'Furniture',
                                          'furniture',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Layer 2: Loading indicator
                          if (feedState.isLoadingMore)
                            const Positioned(
                              bottom: 40,
                              right: 20,
                              child: CircularProgressIndicator(),
                            ),

                          // Layer 3: Retry button when loading fails
                          if (feedState.loadMoreError != null)
                            Positioned(
                              bottom: 40,
                              left: 20,
                              child: FilledButton(
                                onPressed: () {
                                  ref
                                      .read(paginatedProductsProvider.notifier)
                                      .loadMore();
                                },
                                child: const Text('Retry loading'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    WidgetRef ref,
    FeedFilter filter,
    String label,
    String? category,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: filter.category == category && filter.query.isEmpty,
        onSelected: (_) {
          ref.read(feedFilterProvider.notifier).setCategory(category);
        },
      ),
    );
  }
}

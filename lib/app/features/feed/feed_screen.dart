import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/product_card.dart';
import 'providers/saved_products_provider.dart';
import 'providers/paginated_products_provider.dart';
import 'providers/feed_filter_provider.dart';
import 'models/feed_filter.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    final productsAsync = ref.watch(paginatedProductsProvider);
    final filter = ref.watch(feedFilterProvider);
    return productsAsync.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },

      error: (error, stackTrace) {
        return Scaffold(
          body: Center(child: Text('Failed to load products: $error')),
        );
      },

      data: (feedstate) {
        final products = feedstate.products;

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
                      if (index == products.length - 3 && feedstate.hasMore) {
                        ref.read(paginatedProductsProvider.notifier).loadMore();
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          key: ValueKey('${filter.category}:${filter.query}'),
                          initialValue: filter.query,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onFieldSubmitted: (value) {
                            ref
                                .read(feedFilterProvider.notifier)
                                .setSearch(value);
                          },
                        ),

                        const SizedBox(height: 8),
                        Positioned(
                          top: 50,
                          left: 12,
                          right: 12,
                          child: SizedBox(
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
                                _categoryChip(ref, filter, 'Beauty', 'beauty'),
                                _categoryChip(
                                  ref,
                                  filter,
                                  'Furniture',
                                  'furniture',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Layer 2: Loading indicator
                  if (feedstate.isLoadingMore)
                    const Positioned(
                      bottom: 40,
                      right: 20,
                      child: CircularProgressIndicator(),
                    ),

                  // Layer 3: Retry button when loading fails
                  if (feedstate.loadMoreError != null)
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

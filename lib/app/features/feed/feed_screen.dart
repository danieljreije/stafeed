import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/feed_filter.dart';
import 'models/supported_filters.dart';
import 'providers/data_gateway_provider.dart';
import 'providers/feed_filter_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/saved_products_provider.dart';
import 'widgets/feed_search_field.dart';
import 'widgets/product_card.dart';
import 'widgets/sample_data_marker.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    final feedAsync = ref.watch(feedProvider);
    final filter = ref.watch(feedFilterProvider);
    final categories =
        ref.watch(supportedFiltersProvider).asData?.value.categories ??
        const <ProductCategory>[];
    final servesSampleData = ref.watch(dataGatewayProvider).servesSampleData;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load products: $error')),
              data: (feedState) {
                final items = feedState.items;

                if (items.isEmpty) {
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
                              if (index >= items.length - 3 &&
                                  feedState.hasMore) {
                                ref.read(feedProvider.notifier).loadMore();
                              }
                            },
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];

                              return ProductCard(
                                item: item,
                                isSaved: savedProductIds.contains(
                                  item.product.id,
                                ),
                                onSaveToggle: () {
                                  ref
                                      .read(savedProductsProvider.notifier)
                                      .toggleProduct(item.product.id);
                                },
                              );
                            },
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
                                  ref.read(feedProvider.notifier).loadMore();
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

          // Search, chips and the sample-data marker stay visible in every
          // feed state, so an empty search can always be cleared. Pinned to
          // the top so they float over the feed instead of sizing it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
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
                          for (final category in categories)
                            _categoryChip(
                              ref,
                              filter,
                              category.label,
                              category.id,
                            ),
                        ],
                      ),
                    ),
                    if (servesSampleData)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SampleDataMarker(),
                      ),
                  ],
                ),
              ),
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

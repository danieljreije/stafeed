import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/product_card.dart';
import 'providers/saved_products_provider.dart';
import 'providers/paginated_products_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    final productsAsync = ref.watch(paginatedProductsProvider);

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
                    onPageChanged: (index) {
                      if (index == products.length - 3 && feedstate.hasMore) {
                        ref.read(paginatedProductsProvider.notifier).loadMore();
                      }
                    },
                    scrollDirection: Axis.vertical,
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
}

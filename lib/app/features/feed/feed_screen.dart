import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/product_card.dart';
import 'providers/saved_products_provider.dart';
import 'providers/products_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },

      error: (error, stackTrace) {
        return Scaffold(
          body: Center(child: Text('Failed to load products: $error')),
        );
      },

      data: (products) {
        
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
              body: PageView.builder(
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
            );
          },
        );
      },
    );
  }
}

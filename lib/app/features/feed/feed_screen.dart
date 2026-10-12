import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/sample_products.dart';
import 'widgets/product_card.dart';
import 'data/saved_products_storage.dart';
import 'providers/saved_products_provider.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);
    return savedProducts.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },

      error: (error, stackTrace) {
        return Scaffold(
          body: Center(child: Text('Could not load saved products: $error')),
        );
      },

      data: (savedProductIds) {
        return Scaffold(
          body: PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: sampleProducts.length,
            itemBuilder: (context, index) {
              final product = sampleProducts[index];

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
  }
}

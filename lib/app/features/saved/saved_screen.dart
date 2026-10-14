
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/providers/products_provider.dart';
import '../feed/providers/saved_products_provider.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers
    final productsAsync = ref.watch(productsProvider);
    final savedProductsAsync = ref.watch(savedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
      ),

      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, stackTrace) => Center(
          child: Text('Failed to load products: $error'),
        ),

        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text('No products available.'),
            );
          }

          // Products loaded. Now check saved IDs.
          return savedProductsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),

            error: (error, stackTrace) => Center(
              child: Text('Could not load saved products: $error'),
            ),

            data: (savedIds) {
              // Only keep products whose IDs are saved
              final savedProductsList = products
                  .where((product) => savedIds.contains(product.id))
                  .toList();

              if (savedProductsList.isEmpty) {
                return const Center(
                  child: Text('No saved products available.'),
                );
              }

              return ListView.builder(
                itemCount: savedProductsList.length,
                itemBuilder: (context, index) {
                  final product = savedProductsList[index];

                  return ListTile(
                    leading: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(product.name),
                    subtitle: Text(product.brand),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite),
                      onPressed: () {
                        ref
                            .read(savedProductsProvider.notifier)
                            .toggleProduct(product.id);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

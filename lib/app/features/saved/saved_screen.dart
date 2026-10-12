import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/data/sample_products.dart';
import '../feed/providers/saved_products_provider.dart';
import '../saved/saved_screen.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedProducts = ref.watch(savedProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
      ),
      body: savedProducts.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Could not load saved products: $error',
            ),
          );
        },

        data: (savedIds) {
          final products = sampleProducts
              .where(
                (product) => savedIds.contains(product.id),
              )
              .toList();

          if (products.isEmpty) {
            return const Center(
              child: Text('No saved products yet.'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

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
      ),
    );
  }
}
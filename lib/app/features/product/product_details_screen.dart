import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/models/product.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../feed/providers/feed_provider.dart';
import '../feed/widgets/sample_data_marker.dart';

/// Where the product-detail route lands. Only the bare facts of a Product
/// already in the feed for now; the real details screen, with Merchant
/// Handoff, Share and Report, is built in #7.
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final servesSampleData = ref.watch(dataGatewayProvider).servesSampleData;

    Product? product;
    for (final item in ref.watch(feedProvider).items) {
      for (final candidate in item.products) {
        if (candidate.id == productId) product = candidate;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(product?.brand ?? 'Product')),
      body: product == null
          ? const Center(child: Text("This Product isn't in your feed."))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(product.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(product.brand, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(product.description),
                if (servesSampleData) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: SampleDataMarker(),
                  ),
                ],
              ],
            ),
    );
  }
}

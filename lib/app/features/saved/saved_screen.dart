import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import 'models/saved_product.dart';
import 'providers/saved_products_provider.dart';
import 'save_action.dart';

/// Every Saved Product, newest first, from the snapshots kept on the
/// device: shown without the feed, offline and after a restart. Products
/// that can't be bought any more are marked.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: switch (saved) {
        AsyncData(value: final savedProducts) when savedProducts.isEmpty =>
          const _Message(
            message:
                'Nothing saved yet. Tap the heart on anything you like '
                'and it waits for you here.',
          ),
        AsyncData(value: final savedProducts) => ListView.builder(
          itemCount: savedProducts.length,
          itemBuilder: (context, index) =>
              _SavedProductTile(saved: savedProducts[index]),
        ),
        AsyncError() => _Message(
          message: "Couldn't load your Saved Products.",
          action: FilledButton(
            onPressed: () => ref.invalidate(savedProductsProvider),
            child: const Text('Retry'),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SavedProductTile extends ConsumerWidget {
  const _SavedProductTile({required this.saved});

  final SavedProduct saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = saved.imageUrl;
    final mark = switch (ref
        .watch(savedProductAvailabilityProvider(saved.productId))
        .value) {
      SavedProductAvailability.gone => 'Not available any more',
      SavedProductAvailability.outOfStock => 'Out of stock',
      _ => null,
    };

    return ListTile(
      leading: SizedBox(
        // A fixed box, so a picture that fails to load (offline, say)
        // can't take over the whole row.
        width: 60,
        height: 60,
        child: imageUrl == null
            ? const Icon(Icons.image_not_supported_outlined)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
      title: Text(saved.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${saved.price.format()} · ${saved.merchant}'),
          if (mark != null)
            Text(mark, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
      onTap: () => context.push(
        AppRoutes.productDetails(saved.productId, offerId: saved.offerId),
      ),
      trailing: IconButton(
        tooltip: 'Remove from Saved',
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () => removeSaved(context, ref, saved.productId),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

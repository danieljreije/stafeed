import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/models/event.dart';
import '../events/providers/events_provider.dart';
import '../feed/models/media.dart';
import '../feed/models/offer.dart';
import '../feed/models/product.dart';
import '../feed/models/product_actions.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../feed/widgets/feed_item_labels.dart';
import '../feed/widgets/media_carousel.dart';
import '../feed/widgets/sample_data_marker.dart';
import '../saved/providers/saved_products_provider.dart';
import '../saved/save_action.dart';
import 'fixture_merchant_screen.dart';
import 'platform/product_platform.dart';
import 'product_details.dart';
import 'report_screen.dart';

/// Everything about one Product: its media, description, attributes and
/// the Offer the Shopper saw, with today's price and availability fetched
/// fresh on open. From here the Shopper goes to the Merchant, shares the
/// Product or reports it.
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.offerId,
  });

  final String productId;

  /// The Offer the Shopper saw in the feed, shown again if it is still
  /// there.
  final String? offerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(productDetailsProvider(productId));
    final product = details.asData?.value;
    final offer = product == null
        ? null
        : chooseOffer(product, preferredOfferId: offerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(product?.brand ?? 'Product'),
        actions: [
          if (product != null) ...[
            if (offer != null)
              _SaveButton(
                isSaved: ref
                    .watch(savedProductIdsProvider)
                    .contains(product.id),
                onPressed: () => toggleSaved(context, ref, product, offer),
              ),
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _share(ref, product, offer),
            ),
            IconButton(
              tooltip: 'Report',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => _report(context, ref, product, offer),
            ),
          ],
        ],
      ),
      body: switch (details) {
        AsyncData(value: final product?) => _Details(
          product: product,
          offer: offer,
          onViewAtMerchant: offer == null
              ? null
              : () => _handOff(context, ref, product, offer),
        ),
        AsyncData() => const _Message(
          message: "This Product isn't available any more.",
        ),
        AsyncError() => _Message(
          message: "Couldn't load this Product.",
          action: FilledButton(
            onPressed: () => ref.invalidate(productDetailsProvider(productId)),
            child: const Text('Retry'),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Merchant Handoff: recorded as an Outbound Click, then the Merchant's
  /// page. Fixtures have no real Merchant, so an in-app page says what
  /// would happen instead.
  Future<void> _handOff(
    BuildContext context,
    WidgetRef ref,
    Product product,
    Offer offer,
  ) async {
    final gateway = ref.read(dataGatewayProvider);
    final links = ref.read(externalLinksProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    _recordEvent(
      ref,
      NewEvent(
        EventType.outboundClick,
        productId: product.id,
        offerId: offer.id,
        details: {'merchant': offer.merchant},
      ),
    );

    // Recorded on the way out: the Shopper never waits for it, and a
    // failure to record never keeps them from the Merchant.
    unawaited(
      gateway
          .recordOutboundClick(
            OutboundClick(
              productId: product.id,
              offerId: offer.id,
              merchant: offer.merchant,
              url: offer.url,
            ),
          )
          .catchError((Object error) {}),
    );

    if (gateway.servesSampleData) {
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (context) =>
              FixtureMerchantScreen(product: product, offer: offer),
        ),
      );
      return;
    }

    final opened = await links.open(offer.url);
    if (!opened) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text("Couldn't open ${offer.merchant}.")),
        );
    }
  }

  Future<void> _share(WidgetRef ref, Product product, Offer? offer) {
    final isSampleData = ref.read(dataGatewayProvider).servesSampleData;
    _recordEvent(
      ref,
      NewEvent(EventType.share, productId: product.id, offerId: offer?.id),
    );

    return ref
        .read(shareSheetProvider)
        .share(
          text: shareText(product, offer, isSampleData: isSampleData),
          subject: product.title,
        );
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    Product product,
    Offer? offer,
  ) async {
    final gateway = ref.read(dataGatewayProvider);
    final events = ref.read(eventsLogProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    final picked = await Navigator.of(context).push<ReportChoice>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ReportScreen(productTitle: product.title),
      ),
    );
    if (picked == null) return;

    try {
      await gateway.submitReport(
        ProductReport(
          productId: product.id,
          offerId: offer?.id,
          reason: picked.reason,
          note: picked.note,
        ),
      );
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't send the report. Try again.")),
        );
      return;
    }

    unawaited(
      events.record(
        NewEvent(
          EventType.report,
          productId: product.id,
          offerId: offer?.id,
          details: {'reason': picked.reason.name},
        ),
      ),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Thanks. We'll take a look.")),
      );
  }

  /// Records [event] without making the Shopper wait for it.
  static void _recordEvent(WidgetRef ref, NewEvent event) =>
      unawaited(ref.read(eventsLogProvider.notifier).record(event));
}

class _Details extends ConsumerWidget {
  const _Details({
    required this.product,
    required this.offer,
    required this.onViewAtMerchant,
  });

  final Product product;
  final Offer? offer;
  final VoidCallback? onViewAtMerchant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final servesSampleData = ref.watch(dataGatewayProvider).servesSampleData;
    final offer = this.offer;

    // Not lazy: the page is short, and everything on it is always there.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 320,
            child: MediaCarousel(
              media: [for (final url in product.imageUrls) ImageMedia(url)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (servesSampleData) ...[
                  const SampleDataMarker(),
                  const SizedBox(height: 12),
                ],
                Text(product.brand, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(product.title, style: theme.textTheme.headlineSmall),
                if (offer != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    offer.price.format(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.isAvailable ? 'In stock' : 'Out of stock',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: offer.isAvailable
                          ? Colors.green.shade800
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Sold by ${offer.merchant}'),
                  const SizedBox(height: 4),
                  Text(
                    offer.isAffiliate
                        ? FeedItemNote.affiliate
                        : FeedItemNote.notAnAd,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onViewAtMerchant,
                      icon: const Icon(Icons.open_in_new),
                      label: Text('View at ${offer.merchant}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(product.description),
                if (product.attributes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final MapEntry(:key, :value)
                      in product.attributes.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(child: Text(value)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Saves the Product as shown here, or removes it from Saved.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onPressed});

  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isSaved ? 'Remove from Saved' : 'Save',
      onPressed: onPressed,
      icon: Icon(
        isSaved ? Icons.favorite : Icons.favorite_border,
        color: isSaved ? Colors.red : null,
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

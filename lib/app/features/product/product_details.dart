import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_name.dart';
import '../feed/models/offer.dart';
import '../feed/models/product.dart';
import '../feed/providers/data_gateway_provider.dart';

/// A fresh copy of one Product, fetched through the data gateway each time
/// its details screen opens, so the price and availability are today's.
/// Null when the Product isn't available to this Shopper any more.
///
/// Never retried by itself: the screen offers a Retry button instead.
final productDetailsProvider = FutureProvider.autoDispose
    .family<Product?, String>(
      (ref, productId) => ref.watch(dataGatewayProvider).getProduct(productId),
      retry: (retryCount, error) => null,
    );

/// The Offer the details screen shows: [preferredOfferId] (the one the
/// Shopper saw in the feed) when the Product still has it, otherwise the
/// first available Offer that earns, then the first available one, then
/// the first one. Null when the Product has no Offers.
Offer? chooseOffer(Product product, {String? preferredOfferId}) {
  final offers = product.offers;
  if (offers.isEmpty) return null;

  for (final offer in offers) {
    if (offer.id == preferredOfferId) return offer;
  }
  for (final offer in offers) {
    if (offer.isAffiliate && offer.isAvailable) return offer;
  }
  for (final offer in offers) {
    if (offer.isAvailable) return offer;
  }
  return offers.first;
}

/// What the share sheet is given for [product].
///
/// A real Offer shares the Product's name, Brand, price and the Merchant
/// link. Fixtures aren't real inventory and their links go nowhere, so they
/// share only the name, the Brand and where it was found.
String shareText(Product product, Offer? offer, {required bool isSampleData}) {
  final name = '${product.title} by ${product.brand}';

  if (isSampleData || offer == null) return '$name, found on $appName';

  return '$name, ${offer.price.format()} at ${offer.merchant}\n${offer.url}';
}

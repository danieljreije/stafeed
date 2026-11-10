import 'offer.dart';
import 'product.dart';

/// One full-screen card in the feed: a Product with exactly one chosen Offer.
class FeedItem {
  const FeedItem({required this.product, required this.offer});

  final Product product;
  final Offer offer;

  /// Whether this Feed Item earns money for Stafeed and must be labelled AD.
  bool get isAd => offer.isAffiliate;
}

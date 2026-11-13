import 'media.dart';
import 'offer.dart';
import 'product.dart';

/// One full-screen card in the feed. It is exactly one of three kinds:
/// an [AffiliateAd], a [BrandAd] or a [NotAnAd].
sealed class FeedItem {
  const FeedItem();

  /// Tells Feed Items apart within one feed.
  String get id;

  /// Whether this Feed Item earns money for Stafeed and must be labelled AD.
  bool get isAd;

  /// Whether a Brand or Merchant pays Stafeed directly for this Ad.
  bool get isSponsored;

  /// The pictures and clips to show, in order.
  List<Media> get media;

  /// The Products this Feed Item is about: the one it shows, or the ones a
  /// Brand Ad links to.
  List<Product> get products;
}

/// A Feed Item that shows one Product with exactly one chosen Offer:
/// an [AffiliateAd] or a [NotAnAd].
sealed class ProductFeedItem extends FeedItem {
  const ProductFeedItem({required this.product, required this.offer});

  final Product product;
  final Offer offer;

  @override
  String get id => product.id;

  @override
  bool get isSponsored => false;

  @override
  List<Media> get media => [
    for (final url in product.imageUrls) ImageMedia(url),
  ];

  @override
  List<Product> get products => [product];
}

/// An Ad for a Product from an affiliate or pay-per-click source: Stafeed
/// earns when the Shopper clicks through or buys.
final class AffiliateAd extends ProductFeedItem {
  AffiliateAd({required super.product, required super.offer})
    : assert(offer.isAffiliate, 'An Affiliate Ad needs an Offer that earns');

  @override
  bool get isAd => true;
}

/// A Product that earns Stafeed nothing. Only shown inside a Shopping
/// Session, to fill gaps when Ads run thin, and labelled as what it is.
final class NotAnAd extends ProductFeedItem {
  NotAnAd({required super.product, required super.offer})
    : assert(!offer.isAffiliate, 'Not an Ad needs an Offer that earns nothing');

  @override
  bool get isAd => false;
}

/// An ad creative supplied by a Brand or Merchant with permission, shown as
/// supplied. Every Brand Ad is Sponsored.
final class BrandAd extends FeedItem {
  const BrandAd({
    required this.id,
    required this.brand,
    required this.headline,
    required this.media,
    required this.products,
  });

  @override
  final String id;

  /// Who supplied the ad and pays for it.
  final String brand;

  /// The ad's own words, shown unedited.
  final String headline;

  @override
  final List<Media> media;

  /// The Products this ad links to, shown as tappable chips.
  @override
  final List<Product> products;

  @override
  bool get isAd => true;

  @override
  bool get isSponsored => true;
}

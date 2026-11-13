import 'dart:convert';
import 'dart:math';

import '../models/feed_filter.dart';
import '../models/feed_item.dart';
import '../models/feed_page.dart';
import '../models/offer.dart';
import '../models/product.dart';
import '../models/product_actions.dart';
import '../models/supported_filters.dart';
import 'data_gateway.dart';
import 'fixtures/fixture_brand_ads.dart';
import 'fixtures/fixture_products.dart';

/// Serves the Fixtures offline and deterministically.
///
/// For You only takes Ads, so Products without an available affiliate Offer
/// (Not an Ad) are left out of the feed. Each Brand Ad comes right after the
/// last of its linked Products in the feed.
///
/// Given a Destination Country, it never serves an Offer that doesn't ship
/// there: each Affiliate Ad shows the Product's first Offer that does, a
/// Product with none is left out, and a Brand Ad only links the Products
/// still in the feed there (and is left out when there are none).
class FixtureDataGateway implements DataGateway {
  FixtureDataGateway({
    List<Product>? products,
    List<BrandAd>? brandAds,
    List<ProductCategory>? categories,
    this.pageSize = defaultPageSize,
    String? destinationCountry,
  }) : destinationCountry = destinationCountry?.toUpperCase(),
       _products = products ?? fixtureProducts,
       _brandAds = brandAds ?? fixtureBrandAds,
       _categories = categories ?? fixtureCategories;

  static const int defaultPageSize = 10;
  static const String _cursorPrefix = 'fx1.';

  final List<Product> _products;
  final List<BrandAd> _brandAds;
  final List<ProductCategory> _categories;
  final int pageSize;

  /// ISO 3166-1 alpha-2 code of the Shopper's Destination Country. Null
  /// (no Shopper yet) serves every Fixture.
  final String? destinationCountry;

  @override
  bool get servesSampleData => true;

  @override
  Future<SupportedFilters> getSupportedFilters() async {
    final used = {
      for (final item in _forYou())
        for (final product in item.products) product.category,
    };

    return SupportedFilters(
      categories: [
        for (final category in _categories)
          if (used.contains(category.id)) category,
      ],
    );
  }

  @override
  Future<FeedPage> getFeedPage({
    FeedFilter filter = const FeedFilter(),
    FeedCursor? cursor,
  }) async {
    final fingerprint = _fingerprint(filter);
    final offset = cursor == null ? 0 : _readCursor(cursor, fingerprint);

    final matches = _forYou().where((item) => _matches(item, filter)).toList();
    final start = min(offset, matches.length);
    final end = min(start + pageSize, matches.length);
    final items = matches.sublist(start, end);

    return FeedPage(
      items: items,
      nextCursor: end < matches.length ? _writeCursor(end, fingerprint) : null,
    );
  }

  /// Every Outbound Click recorded on this gateway, oldest first. Kept in
  /// memory only: Fixtures have no backend to send them to.
  List<OutboundClick> get outboundClicks => List.unmodifiable(_outboundClicks);
  final List<OutboundClick> _outboundClicks = [];

  /// Every Report stored on this gateway, oldest first. Kept in memory only.
  List<ProductReport> get reports => List.unmodifiable(_reports);
  final List<ProductReport> _reports = [];

  @override
  Future<Product?> getProduct(String productId) async {
    for (final product in _products) {
      if (product.id != productId) continue;

      final offers = product.offers.where(_shipsHere).toList();
      if (offers.isEmpty) return null;

      return Product(
        id: product.id,
        title: product.title,
        description: product.description,
        brand: product.brand,
        category: product.category,
        imageUrls: product.imageUrls,
        attributes: product.attributes,
        offers: offers,
      );
    }
    return null;
  }

  @override
  Future<void> recordOutboundClick(OutboundClick click) async {
    _outboundClicks.add(click);
  }

  @override
  Future<void> submitReport(ProductReport report) async {
    _reports.add(report);
  }

  /// Every Feed Item in For You, in order: each Product that has an
  /// available affiliate Offer, as an Affiliate Ad with that Offer, and the
  /// Brand Ads.
  List<FeedItem> _forYou() {
    final items = <FeedItem>[];

    for (final product in _products) {
      for (final offer in product.offers) {
        if (offer.isAffiliate && offer.isAvailable && _shipsHere(offer)) {
          items.add(AffiliateAd(product: product, offer: offer));
          break;
        }
      }
    }

    for (final supplied in _brandAds) {
      final brandAd = _linkedHere(supplied);
      if (brandAd == null) continue;

      final linked = {for (final product in brandAd.products) product.id};
      final lastLinked = items.lastIndexWhere(
        (item) => item is AffiliateAd && linked.contains(item.product.id),
      );

      // After the last of its linked Products; at the end when none of them
      // is in the feed.
      items.insert(lastLinked < 0 ? items.length : lastLinked + 1, brandAd);
    }

    return items;
  }

  bool _shipsHere(Offer offer) =>
      destinationCountry == null || offer.shipsTo.contains(destinationCountry);

  /// [brandAd] linking only the Products that have an Ad Offer shipping to
  /// the Destination Country (the same rule that puts a Product in For You),
  /// or null when none of them has.
  BrandAd? _linkedHere(BrandAd brandAd) {
    if (destinationCountry == null) return brandAd;

    final products = [
      for (final product in brandAd.products)
        if (product.offers.any(
          (offer) =>
              offer.isAffiliate && offer.isAvailable && _shipsHere(offer),
        ))
          product,
    ];
    if (products.isEmpty) return null;
    if (products.length == brandAd.products.length) return brandAd;

    return BrandAd(
      id: brandAd.id,
      brand: brandAd.brand,
      headline: brandAd.headline,
      media: brandAd.media,
      products: products,
    );
  }

  /// A Brand Ad matches through its own Brand and headline, and through any
  /// Product it links to.
  bool _matches(FeedItem item, FeedFilter filter) {
    final products = item.products;

    if (filter.category != null &&
        !products.any((product) => product.category == filter.category)) {
      return false;
    }

    final words = _words(filter.query);
    if (words.isEmpty) return true;

    final haystack = [
      if (item case BrandAd(:final brand, :final headline)) ...[
        brand,
        headline,
      ],
      for (final product in products) ...[
        product.title,
        product.brand,
        _categoryLabel(product.category),
        ...product.attributes.values,
      ],
    ].join(' ').toLowerCase();

    return words.every(haystack.contains);
  }

  String _categoryLabel(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category.label;
    }
    return categoryId;
  }

  static List<String> _words(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  /// A cursor only continues the feed it came from: same Destination
  /// Country, category and search.
  String _fingerprint(FeedFilter filter) =>
      '${destinationCountry ?? ''}|${filter.category ?? ''}|'
      '${_words(filter.query).join(' ')}';

  static FeedCursor _writeCursor(int offset, String fingerprint) {
    final payload = jsonEncode({'o': offset, 'f': fingerprint});
    return FeedCursor(
      '$_cursorPrefix${base64Url.encode(utf8.encode(payload))}',
    );
  }

  static int _readCursor(FeedCursor cursor, String fingerprint) {
    final token = cursor.token;

    try {
      if (!token.startsWith(_cursorPrefix)) throw const FormatException();
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(token.substring(_cursorPrefix.length))),
      ) as Map<String, dynamic>;

      final offset = payload['o'] as int;
      if (payload['f'] != fingerprint || offset < 0) {
        throw const FormatException();
      }
      return offset;
    } on Object {
      throw ArgumentError.value(
        cursor,
        'cursor',
        'was not issued for this feed filter',
      );
    }
  }
}

import 'dart:convert';
import 'dart:math';

import '../models/feed_filter.dart';
import '../models/feed_item.dart';
import '../models/feed_page.dart';
import '../models/product.dart';
import '../models/supported_filters.dart';
import 'data_gateway.dart';
import 'fixtures/fixture_brand_ads.dart';
import 'fixtures/fixture_products.dart';

/// Serves the Fixtures offline and deterministically.
///
/// For You only takes Ads, so Products without an available affiliate Offer
/// (Not an Ad) are left out of the feed. Each Brand Ad comes right after the
/// last of its linked Products in the feed.
class FixtureDataGateway implements DataGateway {
  FixtureDataGateway({
    List<Product>? products,
    List<BrandAd>? brandAds,
    List<ProductCategory>? categories,
    this.pageSize = defaultPageSize,
  }) : _products = products ?? fixtureProducts,
       _brandAds = brandAds ?? fixtureBrandAds,
       _categories = categories ?? fixtureCategories;

  static const int defaultPageSize = 10;
  static const String _cursorPrefix = 'fx1.';

  final List<Product> _products;
  final List<BrandAd> _brandAds;
  final List<ProductCategory> _categories;
  final int pageSize;

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

  /// Every Feed Item in For You, in order: each Product that has an
  /// available affiliate Offer, as an Affiliate Ad with that Offer, and the
  /// Brand Ads.
  List<FeedItem> _forYou() {
    final items = <FeedItem>[];

    for (final product in _products) {
      for (final offer in product.offers) {
        if (offer.isAffiliate && offer.isAvailable) {
          items.add(AffiliateAd(product: product, offer: offer));
          break;
        }
      }
    }

    for (final brandAd in _brandAds) {
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

  static String _fingerprint(FeedFilter filter) =>
      '${filter.category ?? ''}|${_words(filter.query).join(' ')}';

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

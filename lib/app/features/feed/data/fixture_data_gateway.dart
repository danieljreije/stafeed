import 'dart:convert';
import 'dart:math';

import '../models/feed_filter.dart';
import '../models/feed_item.dart';
import '../models/feed_page.dart';
import '../models/product.dart';
import '../models/supported_filters.dart';
import 'data_gateway.dart';
import 'fixtures/fixture_products.dart';

/// Serves the Fixtures offline and deterministically.
///
/// For You only takes Ads, so Products without an available affiliate Offer
/// (Not an Ad) are left out of the feed.
class FixtureDataGateway implements DataGateway {
  FixtureDataGateway({
    List<Product>? products,
    List<ProductCategory>? categories,
    this.pageSize = defaultPageSize,
  }) : _products = products ?? fixtureProducts,
       _categories = categories ?? fixtureCategories;

  static const int defaultPageSize = 10;
  static const String _cursorPrefix = 'fx1.';

  final List<Product> _products;
  final List<ProductCategory> _categories;
  final int pageSize;

  @override
  bool get servesSampleData => true;

  @override
  Future<SupportedFilters> getSupportedFilters() async {
    final used = _forYou().map((item) => item.product.category).toSet();

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

  /// Every Product that can appear in For You, with its chosen Offer.
  Iterable<FeedItem> _forYou() sync* {
    for (final product in _products) {
      for (final offer in product.offers) {
        if (offer.isAffiliate && offer.isAvailable) {
          yield FeedItem(product: product, offer: offer);
          break;
        }
      }
    }
  }

  bool _matches(FeedItem item, FeedFilter filter) {
    final product = item.product;

    if (filter.category != null && product.category != filter.category) {
      return false;
    }

    final words = _words(filter.query);
    if (words.isEmpty) return true;

    final haystack = [
      product.title,
      product.brand,
      _categoryLabel(product.category),
      ...product.attributes.values,
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

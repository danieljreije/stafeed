import 'dart:convert';

import '../../ranking/ranking.dart';
import '../../ranking/ranking_config.dart';
import '../../ranking/shopper_taste.dart';
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
/// (Not an Ad) are left out of the feed. The ranking orders For You from the
/// Shopper's taste. Fixtures have no relevance of their own, so they are all
/// equally relevant and their order breaks ties: each Brand Ad sits right
/// after the last of its linked Products, and a Feed Item that would follow
/// its own Brand moves down.
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
    this.taste,
    this.rankingConfig = defaultRankingConfig,
  }) : destinationCountry = destinationCountry?.toUpperCase(),
       _products = products ?? fixtureProducts,
       _brandAds = brandAds ?? fixtureBrandAds,
       _categories = categories ?? fixtureCategories;

  static const int defaultPageSize = 10;
  static const String _cursorPrefix = 'fx2.';

  final List<Product> _products;
  final List<BrandAd> _brandAds;
  final List<ProductCategory> _categories;
  final int pageSize;

  /// Where For You's ranking learns the Shopper's taste, asked once per
  /// page. Without it, For You is ranked as for a brand-new Shopper.
  final Future<ShopperTaste> Function()? taste;

  /// The weights For You is ranked with.
  final RankingConfig rankingConfig;

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

  /// Each page is ranked afresh (see [rank]) from what the Shopper's taste
  /// is at that moment, leaving out what earlier pages of the same feed
  /// showed. So a Not interested or a save changes the pages still to come,
  /// and nothing shows twice.
  @override
  Future<FeedPage> getFeedPage({
    FeedFilter filter = const FeedFilter(),
    FeedCursor? cursor,
  }) async {
    final fingerprint = _fingerprint(filter);
    final position = cursor == null
        ? const _Position()
        : _readCursor(cursor, fingerprint);
    final shopper = await (taste?.call() ?? Future.value(const ShopperTaste()));

    final matches = _forYou().where((item) => _matches(item, filter)).toList();
    final byId = {for (final item in matches) item.id: item};

    final ranked = rank(
      RankingInput(
        feed: RankedFeed.forYou,
        candidates: [for (final item in matches) _candidate(item)],
        interests: shopper.interests,
        longTermSignals: _signals(shopper.signals),
        recentlyShown: position.shown.toSet(),
        notInterested: {...shopper.notInterested, ..._notInterested},
        previousBrand: position.lastBrand,
      ),
      rankingConfig,
    );

    final items = [
      for (final candidate in ranked.take(pageSize))
        _feedItem(byId[candidate.id]!, candidate),
    ];
    final hasMore = ranked.length > items.length;

    return FeedPage(
      items: items,
      nextCursor: hasMore
          ? _writeCursor(
              _Position(
                shown: [...position.shown, for (final item in items) item.id],
                lastBrand: ranked[items.length - 1].brand,
              ),
              fingerprint,
            )
          : null,
    );
  }

  /// Product IDs marked Not interested on this gateway. Kept in memory only;
  /// the app keeps its own copy on the device and passes it in through the
  /// Shopper's taste.
  Set<String> get notInterestedProductIds => Set.unmodifiable(_notInterested);
  final Set<String> _notInterested = {};

  @override
  Future<void> markNotInterested(String productId) async {
    _notInterested.add(productId);
  }

  RankingCandidate _candidate(FeedItem item) => RankingCandidate(
    id: item.id,
    kind: switch (item) {
      AffiliateAd() => CandidateKind.affiliateAd,
      NotAnAd() => CandidateKind.notAnAd,
      BrandAd() => CandidateKind.brandAd,
    },
    brand: switch (item) {
      BrandAd(:final brand) => brand,
      ProductFeedItem(:final product) => product.brand,
    },
    products: [
      for (final product in item.products)
        _rankedProduct(
          product,
          item is ProductFeedItem ? item.offer : _adOffer(product),
        ),
    ],
    relevance: 1,
  );

  /// [item] as ranked: a Brand Ad keeps only the linked Products the ranking
  /// kept.
  static FeedItem _feedItem(FeedItem item, RankingCandidate ranked) {
    if (item is! BrandAd || ranked.products.length == item.products.length) {
      return item;
    }
    final kept = {for (final product in ranked.products) product.id};
    return BrandAd(
      id: item.id,
      brand: item.brand,
      headline: item.headline,
      media: item.media,
      products: [
        for (final product in item.products)
          if (kept.contains(product.id)) product,
      ],
    );
  }

  late final Map<String, Product> _productsById = {
    for (final product in _products) product.id: product,
  };

  /// [signals] about Products this gateway knows. Others are left out.
  List<TasteSignal> _signals(List<ProductSignal> signals) {
    return [
      for (final signal in signals)
        if (_productsById[signal.productId] case final product?)
          TasteSignal(signal.type, _rankedProduct(product, _adOffer(product))),
    ];
  }

  static RankedProduct _rankedProduct(Product product, Offer? offer) =>
      RankedProduct(
        id: product.id,
        title: product.title,
        brand: product.brand,
        category: product.category,
        priceMinor: offer?.price.minorUnits,
      );

  /// The Offer a Product would show as an Ad here, or its first Offer.
  Offer? _adOffer(Product product) {
    for (final offer in product.offers) {
      if (offer.isAffiliate && offer.isAvailable && _shipsHere(offer)) {
        return offer;
      }
    }
    return product.offers.firstOrNull;
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

  static FeedCursor _writeCursor(_Position position, String fingerprint) {
    final payload = jsonEncode({
      's': position.shown,
      'b': position.lastBrand,
      'f': fingerprint,
    });
    return FeedCursor(
      '$_cursorPrefix${base64Url.encode(utf8.encode(payload))}',
    );
  }

  static _Position _readCursor(FeedCursor cursor, String fingerprint) {
    final token = cursor.token;

    try {
      if (!token.startsWith(_cursorPrefix)) throw const FormatException();
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(token.substring(_cursorPrefix.length))),
      ) as Map<String, dynamic>;

      if (payload['f'] != fingerprint) throw const FormatException();
      return _Position(
        shown: (payload['s'] as List).cast<String>().toList(),
        lastBrand: payload['b'] as String?,
      );
    } on Object {
      throw ArgumentError.value(
        cursor,
        'cursor',
        'was not issued for this feed filter',
      );
    }
  }
}

/// How far a feed has got: the Feed Items its pages showed, in order, and
/// the Brand of the last one. Carried inside the cursor.
class _Position {
  const _Position({this.shown = const [], this.lastBrand});

  final List<String> shown;
  final String? lastBrand;
}

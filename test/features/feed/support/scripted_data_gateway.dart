import 'dart:async';

import 'package:stafeed/app/features/feed/data/data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/models/media.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/models/offer.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/feed/models/supported_filters.dart';

/// A data gateway whose feed pages arrive only when the test says so, in
/// whatever order the test chooses. Every request is recorded in [requests].
class ScriptedDataGateway implements DataGateway {
  ScriptedDataGateway({this.categories = const []});

  final List<ProductCategory> categories;

  /// Every feed page asked for so far, oldest first.
  final List<FeedPageRequest> requests = [];

  @override
  bool get servesSampleData => true;

  @override
  Future<FeedPage> getFeedPage({
    FeedFilter filter = const FeedFilter(),
    FeedCursor? cursor,
  }) {
    final request = FeedPageRequest(filter: filter, cursor: cursor);
    requests.add(request);
    return request._completer.future;
  }

  @override
  Future<SupportedFilters> getSupportedFilters() async =>
      SupportedFilters(categories: categories);
}

/// One feed page the app asked for and is still waiting on until the test
/// calls [succeed] or [fail].
class FeedPageRequest {
  FeedPageRequest({required this.filter, required this.cursor});

  final FeedFilter filter;
  final FeedCursor? cursor;
  final _completer = Completer<FeedPage>();

  bool get isFirstPage => cursor == null;

  /// Answers with [items]; [next] is the cursor for the page after, or null
  /// when this is the last page.
  void succeed(List<FeedItem> items, {String? next}) {
    _completer.complete(
      FeedPage(
        items: items,
        nextCursor: next == null ? null : FeedCursor(next),
      ),
    );
  }

  void fail([Object? error]) {
    _completer.completeError(error ?? Exception('Scripted outage'));
  }
}

/// A sample Product whose title is "Product [id]", with one Offer. The Offer
/// earns Stafeed money unless [isAffiliate] is false.
Product sampleProduct(
  String id, {
  bool isAffiliate = true,
  List<String> imageUrls = const [],
}) {
  return Product(
    id: id,
    title: 'Product $id',
    description: 'Sample product $id',
    brand: 'Sample Brand',
    category: 'samples',
    imageUrls: imageUrls,
    offers: [
      Offer(
        id: 'offer-$id',
        merchant: 'Sample Merchant',
        price: const Money(1000, 'USD'),
        shipsTo: const {'US'},
        url: Uri.parse('https://example.com/$id'),
        isAffiliate: isAffiliate,
      ),
    ],
  );
}

/// A sample Affiliate Ad whose title is "Product [id]".
AffiliateAd feedItem(String id, {List<String> imageUrls = const []}) {
  final product = sampleProduct(id, imageUrls: imageUrls);

  return AffiliateAd(product: product, offer: product.offers.single);
}

List<FeedItem> feedItems(Iterable<String> ids) => [
  for (final id in ids) feedItem(id),
];

/// A sample Not an Ad Feed Item whose title is "Product [id]".
NotAnAd notAnAd(String id, {List<String> imageUrls = const []}) {
  final product = sampleProduct(id, isAffiliate: false, imageUrls: imageUrls);

  return NotAnAd(product: product, offer: product.offers.single);
}

/// A sample Brand Ad by "Brand [id]", linked to [products].
BrandAd brandAd(
  String id, {
  List<Product> products = const [],
  List<Media> media = const [],
}) {
  return BrandAd(
    id: id,
    brand: 'Brand $id',
    headline: 'Headline $id',
    media: media,
    products: products,
  );
}

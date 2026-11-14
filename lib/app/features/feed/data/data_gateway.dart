import '../models/feed_filter.dart';
import '../models/feed_page.dart';
import '../models/product.dart';
import '../models/product_actions.dart';
import '../models/supported_filters.dart';

/// The only way the app reaches data. Screens and controllers talk to this
/// interface and never to a source directly.
abstract interface class DataGateway {
  /// True when this gateway serves Fixtures rather than real inventory, so
  /// the app can say so.
  bool get servesSampleData;

  /// One page of the feed for [filter]. Pass back the previous page's
  /// [FeedPage.nextCursor] to continue; omit it for the first page.
  ///
  /// Throws [ArgumentError] when [cursor] was not issued by this gateway for
  /// the same [filter].
  Future<FeedPage> getFeedPage({
    FeedFilter filter = const FeedFilter(),
    FeedCursor? cursor,
  });

  /// The filters this source actually supports.
  Future<SupportedFilters> getSupportedFilters();

  /// A fresh copy of one Product, with today's prices and availability, for
  /// its details screen. Its Offers are only those that ship to the
  /// Shopper's Destination Country.
  ///
  /// Null when the source doesn't know the Product any more, or none of its
  /// Offers ships there.
  Future<Product?> getProduct(String productId);

  /// Records a Merchant Handoff.
  Future<void> recordOutboundClick(OutboundClick click);

  /// Stores a Shopper's report about a Product.
  Future<void> submitReport(ProductReport report);

  /// Records that the Shopper is Not interested in a Product: no feed
  /// serves it again.
  Future<void> markNotInterested(String productId);
}

import '../models/feed_filter.dart';
import '../models/feed_page.dart';
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
}

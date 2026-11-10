import 'feed_item.dart';
import 'feed_page.dart';

/// What the feed has loaded so far.
class FeedState {
  const FeedState({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<FeedItem> items;

  /// Opaque; handed back to the data gateway to get the next page.
  final FeedCursor? nextCursor;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get hasMore => nextCursor != null;
}

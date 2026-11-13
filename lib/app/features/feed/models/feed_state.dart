import 'feed_item.dart';
import 'feed_page.dart';

/// Where the feed's first page stands.
enum FeedPhase {
  /// The first page hasn't arrived yet.
  loading,

  /// The first page couldn't be loaded.
  failed,

  /// The first page arrived (it may be empty).
  loaded,
}

/// What the feed has loaded so far, and what it is busy doing.
class FeedState {
  /// Waiting for the first page.
  const FeedState.loading()
    : phase = FeedPhase.loading,
      items = const [],
      nextCursor = null,
      isLoadingMore = false,
      loadMoreError = null,
      isRefreshing = false,
      error = null;

  /// The first page couldn't be loaded.
  const FeedState.failed(Object this.error)
    : phase = FeedPhase.failed,
      items = const [],
      nextCursor = null,
      isLoadingMore = false,
      loadMoreError = null,
      isRefreshing = false;

  /// The first page arrived.
  const FeedState.loaded({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isRefreshing = false,
  }) : phase = FeedPhase.loaded,
       error = null;

  final FeedPhase phase;

  final List<FeedItem> items;

  /// Opaque; handed back to the data gateway to get the next page.
  final FeedCursor? nextCursor;

  /// True while the next page is on its way.
  final bool isLoadingMore;

  /// Why the last load-more failed. The items and the cursor are kept, so it
  /// can be tried again.
  final Object? loadMoreError;

  /// True while a refresh is on its way. The old list stays until it arrives.
  final bool isRefreshing;

  /// Why the first page failed, when [phase] is [FeedPhase.failed].
  final Object? error;

  bool get isLoaded => phase == FeedPhase.loaded;

  bool get hasMore => nextCursor != null;

  /// Loaded, and nothing matched.
  bool get isEmpty => isLoaded && items.isEmpty;

  /// The Shopper can see every Feed Item there is; nothing more will load.
  bool get reachedEnd => isLoaded && items.isNotEmpty && !hasMore;
}

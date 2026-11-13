import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_gateway.dart';
import '../models/feed_filter.dart';
import '../models/feed_item.dart';
import '../models/feed_state.dart';
import 'data_gateway_provider.dart';
import 'feed_filter_provider.dart';

/// How a pull-to-refresh ended.
enum RefreshOutcome {
  /// The feed now shows the fresh first page.
  refreshed,

  /// The fresh first page couldn't be loaded; the old list is still there.
  failed,

  /// Nothing to refresh, or the Shopper moved to another feed meanwhile.
  skipped,
}

/// Loads the feed page by page for the current filter.
///
/// Every list the Shopper sees belongs to one generation. A new filter, a
/// retry of the first page, or a refresh that succeeds starts a new
/// generation; an answer that was asked for by an older one is dropped, so a
/// slow request can never overwrite, extend or switch off the spinner of a
/// newer feed.
class FeedNotifier extends Notifier<FeedState> {
  int _generation = 0;

  // What the current generation loads from. Kept from build() so a page is
  // always asked for with the filter its cursor belongs to.
  late DataGateway _gateway;
  late FeedFilter _filter;

  @override
  FeedState build() {
    _gateway = ref.watch(dataGatewayProvider);
    _filter = ref.watch(feedFilterProvider);

    _loadFirstPage(++_generation);

    return const FeedState.loading();
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<void> _loadFirstPage(int generation) async {
    try {
      final page = await _gateway.getFeedPage(filter: _filter);
      if (!_isCurrent(generation)) return;

      state = FeedState.loaded(items: page.items, nextCursor: page.nextCursor);
    } catch (error) {
      if (!_isCurrent(generation)) return;

      state = FeedState.failed(error);
    }
  }

  /// Tries the first page again after it failed.
  void retry() {
    if (state.phase != FeedPhase.failed) return;

    state = const FeedState.loading();
    _loadFirstPage(++_generation);
  }

  /// Loads the next page. Also the way to retry after a load-more failed:
  /// the items and the cursor are still there.
  Future<void> loadMore() async {
    final current = state;

    // Not ready, already loading, or at the end.
    if (!current.isLoaded || current.isLoadingMore || !current.hasMore) {
      return;
    }

    final generation = _generation;
    final cursor = current.nextCursor;

    state = FeedState.loaded(
      items: current.items,
      nextCursor: cursor,
      isLoadingMore: true,
      isRefreshing: current.isRefreshing,
    );

    try {
      final page = await _gateway.getFeedPage(filter: _filter, cursor: cursor);
      if (!_isCurrent(generation)) return;

      state = FeedState.loaded(
        items: _append(state.items, page.items),
        nextCursor: page.nextCursor,
        isRefreshing: state.isRefreshing,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;

      state = FeedState.loaded(
        items: state.items,
        nextCursor: cursor,
        loadMoreError: error,
        isRefreshing: state.isRefreshing,
      );
    }
  }

  /// Fetches the first page again. The old list stays until the new one
  /// arrives, and stays for good when the refresh fails.
  Future<RefreshOutcome> refresh() async {
    final current = state;
    if (!current.isLoaded || current.isRefreshing) {
      return RefreshOutcome.skipped;
    }

    final generation = _generation;

    state = FeedState.loaded(
      items: current.items,
      nextCursor: current.nextCursor,
      isLoadingMore: current.isLoadingMore,
      loadMoreError: current.loadMoreError,
      isRefreshing: true,
    );

    try {
      final page = await _gateway.getFeedPage(filter: _filter);
      if (!_isCurrent(generation)) return RefreshOutcome.skipped;

      // A new list: whatever the old one was still waiting for is stale.
      _generation++;
      state = FeedState.loaded(items: page.items, nextCursor: page.nextCursor);
      return RefreshOutcome.refreshed;
    } catch (_) {
      if (!_isCurrent(generation)) return RefreshOutcome.skipped;

      final latest = state;
      state = FeedState.loaded(
        items: latest.items,
        nextCursor: latest.nextCursor,
        isLoadingMore: latest.isLoadingMore,
        loadMoreError: latest.loadMoreError,
      );
      return RefreshOutcome.failed;
    }
  }

  /// [existing] followed by the Products in [incoming] not already shown.
  static List<FeedItem> _append(
    List<FeedItem> existing,
    List<FeedItem> incoming,
  ) {
    final seen = {for (final item in existing) item.product.id};

    return [
      ...existing,
      for (final item in incoming)
        if (seen.add(item.product.id)) item,
    ];
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/models/feed_state.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/providers/feed_filter_provider.dart';
import 'package:stafeed/app/features/feed/providers/feed_provider.dart';

import '../support/scripted_data_gateway.dart';

void main() {
  late ScriptedDataGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = ScriptedDataGateway();
    container = ProviderContainer(
      overrides: [dataGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    // Someone has to be looking at the feed for it to load.
    container.listen(feedProvider, (_, _) {});
  });

  FeedState feed() => container.read(feedProvider);
  FeedNotifier controller() => container.read(feedProvider.notifier);
  List<String> ids() => [for (final item in feed().items) item.id];

  /// Lets everything already answered reach the feed.
  Future<void> settle() => pumpEventQueue();

  void setCategory(String? category) {
    container.read(feedFilterProvider.notifier).setCategory(category);
    // The feed notices the new filter the next time it is looked at.
    feed();
  }

  /// Loads a first page of [itemIds] with more to come after it.
  Future<void> loadFirstPage(
    List<String> itemIds, {
    String? next = 'page-2',
  }) async {
    feed();
    gateway.requests.last.succeed(feedItems(itemIds), next: next);
    await settle();
  }

  group('first page', () {
    test('the feed is loading until the first page arrives', () async {
      expect(feed().phase, FeedPhase.loading);
      expect(gateway.requests, hasLength(1));
      expect(gateway.requests.single.isFirstPage, isTrue);

      gateway.requests.single.succeed(feedItems(['a', 'b']), next: 'page-2');
      await settle();

      expect(feed().phase, FeedPhase.loaded);
      expect(ids(), ['a', 'b']);
      expect(feed().hasMore, isTrue);
    });

    test('a first page with nothing in it is the empty state', () async {
      await loadFirstPage([], next: null);

      expect(feed().phase, FeedPhase.loaded);
      expect(feed().isEmpty, isTrue);
      expect(feed().reachedEnd, isFalse);
    });

    test('a failed first page is the error state', () async {
      feed();
      gateway.requests.single.fail();
      await settle();

      expect(feed().phase, FeedPhase.failed);
      expect(feed().items, isEmpty);
    });

    test('retry after a failed first page asks once and recovers', () async {
      feed();
      gateway.requests.single.fail();
      await settle();

      controller().retry();
      controller().retry();

      expect(feed().phase, FeedPhase.loading);
      expect(gateway.requests, hasLength(2));

      gateway.requests.last.succeed(feedItems(['a']));
      await settle();

      expect(feed().phase, FeedPhase.loaded);
      expect(ids(), ['a']);
    });

    test('retry does nothing unless the first page failed', () async {
      await loadFirstPage(['a']);

      controller().retry();

      expect(gateway.requests, hasLength(1));
      expect(ids(), ['a']);
    });
  });

  group('load more', () {
    test('adds the next page after the items already there', () async {
      await loadFirstPage(['a', 'b']);

      controller().loadMore();

      expect(feed().isLoadingMore, isTrue);
      expect(gateway.requests.last.cursor, const FeedCursor('page-2'));

      gateway.requests.last.succeed(feedItems(['c', 'd']), next: 'page-3');
      await settle();

      expect(ids(), ['a', 'b', 'c', 'd']);
      expect(feed().isLoadingMore, isFalse);
      expect(feed().nextCursor, const FeedCursor('page-3'));
    });

    test('only one load-more runs at a time', () async {
      await loadFirstPage(['a', 'b']);

      controller().loadMore();
      controller().loadMore();
      controller().loadMore();

      expect(gateway.requests, hasLength(2));

      gateway.requests.last.succeed(feedItems(['c']), next: 'page-3');
      await settle();
      controller().loadMore();

      expect(gateway.requests, hasLength(3));
      expect(gateway.requests.last.cursor, const FeedCursor('page-3'));
    });

    test('a Product already in the feed is not added twice', () async {
      await loadFirstPage(['a', 'b']);

      controller().loadMore();
      gateway.requests.last.succeed(feedItems(['b', 'c', 'c']));
      await settle();

      expect(ids(), ['a', 'b', 'c']);
    });

    test('does nothing while the first page is still loading', () async {
      feed();

      controller().loadMore();

      expect(gateway.requests, hasLength(1));
    });

    test('the end of the feed is quiet: nothing more is asked for', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      gateway.requests.last.succeed(feedItems(['c']));
      await settle();

      expect(feed().reachedEnd, isTrue);
      expect(feed().isLoadingMore, isFalse);
      expect(feed().loadMoreError, isNull);

      controller().loadMore();

      expect(gateway.requests, hasLength(2));
    });

    test('a failure keeps the items and the cursor, and says so', () async {
      await loadFirstPage(['a', 'b']);

      controller().loadMore();
      gateway.requests.last.fail();
      await settle();

      expect(ids(), ['a', 'b']);
      expect(feed().nextCursor, const FeedCursor('page-2'));
      expect(feed().isLoadingMore, isFalse);
      expect(feed().loadMoreError, isNotNull);
    });

    test('retry after a failure asks once for the same page', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      gateway.requests.last.fail();
      await settle();

      controller().loadMore();
      controller().loadMore();

      expect(gateway.requests, hasLength(3));
      expect(gateway.requests.last.cursor, const FeedCursor('page-2'));
      expect(feed().loadMoreError, isNull);
      expect(feed().isLoadingMore, isTrue);

      gateway.requests.last.succeed(feedItems(['c']), next: 'page-3');
      await settle();

      expect(ids(), ['a', 'b', 'c']);
      expect(feed().loadMoreError, isNull);
    });
  });

  group('filter changes', () {
    test('a new filter starts over from its own first page', () async {
      await loadFirstPage(['a', 'b']);

      setCategory('shoes');

      expect(feed().phase, FeedPhase.loading);
      expect(gateway.requests.last.filter.category, 'shoes');
      expect(gateway.requests.last.isFirstPage, isTrue);

      gateway.requests.last.succeed(feedItems(['s1']), next: null);
      await settle();

      expect(ids(), ['s1']);
    });

    test('a load-more that answers after a filter change is dropped', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      setCategory('shoes');
      final shoes = gateway.requests.last;

      staleLoadMore.succeed(feedItems(['c']), next: 'page-3');
      await settle();

      expect(feed().phase, FeedPhase.loading);
      expect(feed().items, isEmpty);

      shoes.succeed(feedItems(['s1']), next: 'shoes-2');
      await settle();

      expect(ids(), ['s1']);
      expect(feed().nextCursor, const FeedCursor('shoes-2'));
      expect(feed().isLoadingMore, isFalse);
    });

    test('a load-more that fails after a filter change is dropped', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      setCategory('shoes');
      gateway.requests.last.succeed(feedItems(['s1']), next: 'shoes-2');
      await settle();

      staleLoadMore.fail();
      await settle();

      expect(ids(), ['s1']);
      expect(feed().loadMoreError, isNull);
      expect(feed().isLoadingMore, isFalse);
    });

    test('a stale load-more does not block or end the new one', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      setCategory('shoes');
      gateway.requests.last.succeed(feedItems(['s1']), next: 'shoes-2');
      await settle();

      // The new filter can load more straight away...
      controller().loadMore();
      final shoesLoadMore = gateway.requests.last;
      expect(shoesLoadMore.cursor, const FeedCursor('shoes-2'));
      expect(feed().isLoadingMore, isTrue);

      // ...and the old answer arriving doesn't switch its spinner off.
      staleLoadMore.succeed(feedItems(['c']));
      await settle();
      expect(feed().isLoadingMore, isTrue);
      expect(ids(), ['s1']);

      shoesLoadMore.succeed(feedItems(['s2']));
      await settle();
      expect(ids(), ['s1', 's2']);
    });

    test('a first page that answers after a filter change is dropped, even '
        'when the Shopper goes A to B and back to A', () async {
      feed();
      final firstA = gateway.requests.last;

      setCategory('shoes');
      final b = gateway.requests.last;

      setCategory(null);
      final secondA = gateway.requests.last;
      expect(gateway.requests, hasLength(3));

      // The oldest A answer and the B answer both arrive late.
      firstA.succeed(feedItems(['old-a']), next: 'old-a-2');
      b.fail();
      await settle();

      expect(feed().phase, FeedPhase.loading);
      expect(feed().items, isEmpty);

      secondA.succeed(feedItems(['new-a']), next: 'new-a-2');
      await settle();

      expect(ids(), ['new-a']);
      expect(feed().nextCursor, const FeedCursor('new-a-2'));
    });

    test('going A to B and back to A drops the first A load-more', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      setCategory('shoes');
      setCategory(null);
      gateway.requests.last.succeed(feedItems(['a', 'b']), next: 'page-2');
      await settle();

      // Same filter, same cursor as the feed now on screen, but it was asked
      // for by the earlier visit.
      staleLoadMore.succeed(feedItems(['c']), next: 'page-3');
      await settle();

      expect(ids(), ['a', 'b']);
      expect(feed().nextCursor, const FeedCursor('page-2'));
      expect(feed().isLoadingMore, isFalse);
    });

    test('a late failure never replaces a newer first page', () async {
      feed();
      final first = gateway.requests.last;

      setCategory('shoes');
      gateway.requests.last.succeed(feedItems(['s1']));
      await settle();

      first.fail();
      await settle();

      expect(feed().phase, FeedPhase.loaded);
      expect(ids(), ['s1']);
    });
  });

  group('refresh', () {
    test('keeps the old list until the new first page arrives', () async {
      await loadFirstPage(['a', 'b']);

      final refreshed = controller().refresh();

      expect(feed().phase, FeedPhase.loaded);
      expect(feed().isRefreshing, isTrue);
      expect(ids(), ['a', 'b']);
      expect(gateway.requests.last.isFirstPage, isTrue);

      gateway.requests.last.succeed(feedItems(['x', 'y']), next: 'fresh-2');

      expect(await refreshed, RefreshOutcome.refreshed);
      expect(ids(), ['x', 'y']);
      expect(feed().nextCursor, const FeedCursor('fresh-2'));
      expect(feed().isRefreshing, isFalse);
    });

    test('a failed refresh keeps the old list and its cursor', () async {
      await loadFirstPage(['a', 'b']);

      final refreshed = controller().refresh();
      gateway.requests.last.fail();

      expect(await refreshed, RefreshOutcome.failed);
      expect(feed().phase, FeedPhase.loaded);
      expect(ids(), ['a', 'b']);
      expect(feed().nextCursor, const FeedCursor('page-2'));
      expect(feed().isRefreshing, isFalse);
    });

    test('only one refresh runs at a time', () async {
      await loadFirstPage(['a', 'b']);

      controller().refresh();
      controller().refresh();

      expect(gateway.requests, hasLength(2));
    });

    test('a load-more that answers after a refresh is dropped', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      final refreshed = controller().refresh();
      gateway.requests.last.succeed(feedItems(['x', 'y']), next: 'fresh-2');
      await refreshed;

      expect(feed().isLoadingMore, isFalse);

      staleLoadMore.succeed(feedItems(['c']), next: 'page-3');
      await settle();

      expect(ids(), ['x', 'y']);
      expect(feed().nextCursor, const FeedCursor('fresh-2'));
    });

    test('a load-more that fails after a refresh is dropped', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final staleLoadMore = gateway.requests.last;

      final refreshed = controller().refresh();
      gateway.requests.last.succeed(feedItems(['x', 'y']), next: 'fresh-2');
      await refreshed;

      staleLoadMore.fail();
      await settle();

      expect(ids(), ['x', 'y']);
      expect(feed().loadMoreError, isNull);
    });

    test('a load-more still counts when the refresh fails', () async {
      await loadFirstPage(['a', 'b']);
      controller().loadMore();
      final loadMore = gateway.requests.last;

      final refreshed = controller().refresh();
      gateway.requests.last.fail();
      await refreshed;

      loadMore.succeed(feedItems(['c']), next: 'page-3');
      await settle();

      expect(ids(), ['a', 'b', 'c']);
      expect(feed().nextCursor, const FeedCursor('page-3'));
    });

    test('a refresh that answers after a filter change is dropped', () async {
      await loadFirstPage(['a', 'b']);
      final refreshed = controller().refresh();
      final staleRefresh = gateway.requests.last;

      setCategory('shoes');
      gateway.requests.last.succeed(feedItems(['s1']), next: 'shoes-2');
      await settle();

      staleRefresh.succeed(feedItems(['x', 'y']), next: 'fresh-2');

      expect(await refreshed, RefreshOutcome.skipped);
      expect(ids(), ['s1']);
      expect(feed().nextCursor, const FeedCursor('shoes-2'));
      expect(feed().isRefreshing, isFalse);
    });

    test('does nothing before the first page has loaded', () async {
      feed();

      expect(await controller().refresh(), RefreshOutcome.skipped);
      expect(gateway.requests, hasLength(1));
    });
  });
}

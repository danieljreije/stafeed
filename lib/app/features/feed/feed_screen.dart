import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/feed_watch.dart';
import '../events/models/event.dart';
import '../events/providers/events_provider.dart';
import '../not_interested/not_interested_action.dart';
import '../product/open_product_details.dart';
import 'models/feed_filter.dart';
import 'models/feed_item.dart';
import 'models/feed_state.dart';
import 'models/supported_filters.dart';
import 'providers/data_gateway_provider.dart';
import 'providers/feed_filter_provider.dart';
import 'providers/feed_provider.dart';
import '../saved/providers/saved_products_provider.dart';
import '../saved/save_action.dart';
import 'widgets/brand_ad_card.dart';
import 'widgets/feed_search_field.dart';
import 'widgets/product_card.dart';
import 'widgets/sample_data_marker.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final filter = ref.watch(feedFilterProvider);
    final categories =
        ref.watch(supportedFiltersProvider).asData?.value.categories ??
        const <ProductCategory>[];
    final servesSampleData = ref.watch(dataGatewayProvider).servesSampleData;
    return Scaffold(
      body: Stack(
        children: [
          // The feed and its loading, empty and error states sit under the
          // controls and never replace them.
          Positioned.fill(
            child: switch (feedState.phase) {
              FeedPhase.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              FeedPhase.failed => _FeedMessage(
                message: "Couldn't load the feed.",
                action: FilledButton(
                  onPressed: () => ref.read(feedProvider.notifier).retry(),
                  child: const Text('Retry'),
                ),
              ),
              FeedPhase.loaded when feedState.isEmpty => _FeedMessage(
                message: 'No matches',
                action: TextButton(
                  onPressed: () =>
                      ref.read(feedFilterProvider.notifier).clear(),
                  child: const Text('Clear filters'),
                ),
              ),
              FeedPhase.loaded => _FeedPages(
                // A new filter is a new feed, watched from its first Feed
                // Item.
                key: ValueKey('${filter.category ?? 'all'}:${filter.query}'),
                feedState: feedState,
                filter: filter,
              ),
            },
          ),

          // Search, chips and the sample-data marker stay visible in every
          // feed state, so an empty search can always be cleared. Pinned to
          // the top so they float over the feed instead of deciding its
          // height.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FeedSearchField(),

                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _categoryChip(ref, filter, 'All', null),
                          for (final category in categories)
                            _categoryChip(
                              ref,
                              filter,
                              category.label,
                              category.id,
                            ),
                        ],
                      ),
                    ),
                    if (servesSampleData)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SampleDataMarker(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    WidgetRef ref,
    FeedFilter filter,
    String label,
    String? category,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: filter.category == category && filter.query.isEmpty,
        onSelected: (_) {
          ref.read(feedFilterProvider.notifier).setCategory(category);
        },
      ),
    );
  }
}

/// A short message in the middle of the feed area, with one thing to do
/// about it.
class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.message, required this.action});

  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}

/// The swipeable Feed Items, with pull-to-refresh, load-more and the
/// end-of-feed page. Records what the Shopper sees: impressions, 2s and 5s
/// views and Skips (see [FeedWatch]).
class _FeedPages extends ConsumerStatefulWidget {
  const _FeedPages({super.key, required this.feedState, required this.filter});

  final FeedState feedState;
  final FeedFilter filter;

  @override
  ConsumerState<_FeedPages> createState() => _FeedPagesState();
}

class _FeedPagesState extends ConsumerState<_FeedPages> {
  /// Roughly the height of the search box, chips and sample-data marker, so
  /// the refresh spinner shows below them instead of behind them.
  static const double _controlsHeight = 150;

  // Kept from the start, so leaving the feed can still record its last
  // Events after this widget is gone.
  late final EventsLog _events = ref.read(eventsLogProvider.notifier);
  late final DateTime Function() _now = ref.read(eventsClockProvider);
  late final FeedWatch _watch = FeedWatch(
    actedOn: (item, since) => actedOnFeedItem(_events.recorded, item, since),
  );

  int _index = 0;
  Timer? _viewTimer;

  /// False while the Feed tab is hidden behind another tab.
  bool? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (visible) {
      // Coming back to the Feed tab shows its Feed Item again.
      _watchCurrent(swiped: false);
    } else {
      _viewTimer?.cancel();
      _record(_watch.leave(_now(), swiped: false));
    }
  }

  @override
  void didUpdateWidget(_FeedPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refresh can put a different Feed Item where the Shopper is.
    if (_visible ?? false) _watchCurrent(swiped: false);
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _record(_watch.leave(_now(), swiped: false));
    super.dispose();
  }

  /// Tells the watch what is on screen now. [swiped] says whether the
  /// Shopper got here by swiping.
  void _watchCurrent({required bool swiped}) {
    final items = widget.feedState.items;
    final now = _now();
    if (_index < items.length) {
      final item = items[_index];
      if (_watch.current?.id == item.id) return;
      if (!swiped) _record(_watch.leave(now, swiped: false));
      _record(_watch.show(item, now));
    } else {
      _record(_watch.leave(now, swiped: swiped));
    }
    _scheduleViewCheck();
  }

  void _scheduleViewCheck() {
    _viewTimer?.cancel();
    final wait = _watch.untilNextCheck(_now());
    if (wait == null) return;
    _viewTimer = Timer(wait, () {
      _record(_watch.check(_now()));
      _scheduleViewCheck();
    });
  }

  /// Records [events] just after the current frame, since they can come
  /// up while the feed is being built.
  void _record(List<NewEvent> events) {
    if (events.isEmpty) return;
    scheduleMicrotask(() {
      for (final event in events) {
        _events.record(event);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedState = widget.feedState;
    final filter = widget.filter;
    final items = feedState.items;

    // The feed never waits for the Saved Products: until they are read, every
    // Save button shows as not saved.
    final savedProductIds = ref.watch(savedProductIdsProvider);

    return Stack(
      children: [
        RefreshIndicator(
          edgeOffset: MediaQuery.paddingOf(context).top + _controlsHeight,
          onRefresh: () => _refresh(context, ref),
          child: PageView.builder(
            key: ValueKey('${filter.category ?? 'all'}:${filter.query}'),
            scrollDirection: Axis.vertical,
            // A feed of one Feed Item can still be pulled to refresh.
            physics: AlwaysScrollableScrollPhysics(
              parent: ScrollConfiguration.of(context).getScrollPhysics(context),
            ),
            onPageChanged: (index) {
              _index = index;
              _watchCurrent(swiped: true);

              // Fetch ahead, a few Feed Items before the last one.
              if (index >= items.length - 3) {
                ref.read(feedProvider.notifier).loadMore();
              }
            },
            // One quiet page after the last Feed Item.
            itemCount: items.length + (feedState.reachedEnd ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) return const _EndOfFeed();

              return switch (items[index]) {
                final ProductFeedItem item => ProductCard(
                  item: item,
                  isSaved: savedProductIds.contains(item.product.id),
                  onSaveToggle: () =>
                      toggleSaved(context, ref, item.product, item.offer),
                  onNotInterested: () => markNotInterested(
                    context,
                    ref,
                    item.product.id,
                    offerId: item.offer.id,
                    feedItemId: item.id,
                    isAd: item.isAd,
                  ),
                  onOpen: () => openProductDetails(
                    context,
                    ref,
                    item.product.id,
                    offerId: item.offer.id,
                    feedItemId: item.id,
                  ),
                ),
                final BrandAd ad => BrandAdCard(
                  ad: ad,
                  onProductTap: (product) => openProductDetails(
                    context,
                    ref,
                    product.id,
                    feedItemId: ad.id,
                  ),
                ),
              };
            },
          ),
        ),

        if (feedState.isLoadingMore)
          const Positioned(
            bottom: 40,
            right: 20,
            child: CircularProgressIndicator(),
          ),

        // The Feed Items already loaded stay; only the next page is
        // tried again.
        if (feedState.loadMoreError != null)
          Positioned(
            bottom: 40,
            left: 20,
            child: FilledButton(
              onPressed: () {
                ref.read(feedProvider.notifier).loadMore();
              },
              child: const Text('Retry loading'),
            ),
          ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref.read(feedProvider.notifier).refresh();

    if (outcome == RefreshOutcome.failed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Couldn't refresh the feed.")),
        );
    }
  }
}

/// The page after the last Feed Item: nothing more to load, said quietly.
class _EndOfFeed extends StatelessWidget {
  const _EndOfFeed();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        "You've seen everything for now",
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

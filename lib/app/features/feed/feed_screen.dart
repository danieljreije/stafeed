import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

import 'models/feed_filter.dart';
import 'models/feed_item.dart';
import 'models/feed_state.dart';
import 'models/supported_filters.dart';
import 'providers/data_gateway_provider.dart';
import 'providers/feed_filter_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/saved_products_provider.dart';
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
/// end-of-feed page.
class _FeedPages extends ConsumerWidget {
  const _FeedPages({required this.feedState, required this.filter});

  /// Roughly the height of the search box, chips and sample-data marker, so
  /// the refresh spinner shows below them instead of behind them.
  static const double _controlsHeight = 150;

  final FeedState feedState;
  final FeedFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = feedState.items;

    return ref
        .watch(savedProductsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load saved products: $error')),
          data: (savedProductIds) {
            return Stack(
              children: [
                RefreshIndicator(
                  edgeOffset:
                      MediaQuery.paddingOf(context).top + _controlsHeight,
                  onRefresh: () => _refresh(context, ref),
                  child: PageView.builder(
                    key: ValueKey(
                      '${filter.category ?? 'all'}:${filter.query}',
                    ),
                    scrollDirection: Axis.vertical,
                    // A feed of one Feed Item can still be pulled to refresh.
                    physics: AlwaysScrollableScrollPhysics(
                      parent: ScrollConfiguration.of(context)
                          .getScrollPhysics(context),
                    ),
                    onPageChanged: (index) {
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
                          onSaveToggle: () {
                            ref
                                .read(savedProductsProvider.notifier)
                                .toggleProduct(item.product.id);
                          },
                          onOpen: () => context.push(
                            AppRoutes.productDetails(
                              item.product.id,
                              offerId: item.offer.id,
                            ),
                          ),
                        ),
                        final BrandAd ad => BrandAdCard(
                          ad: ad,
                          onProductTap: (product) => context.push(
                            AppRoutes.productDetails(product.id),
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
          },
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

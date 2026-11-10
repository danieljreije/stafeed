import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_state.dart';
import 'data_gateway_provider.dart';
import 'feed_filter_provider.dart';

class FeedNotifier extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    final gateway = ref.watch(dataGatewayProvider);
    final filter = ref.watch(feedFilterProvider);

    final page = await gateway.getFeedPage(filter: filter);

    return FeedState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;

    // Avoid requesting when not ready, already loading, or at the end.
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(
      FeedState(
        items: current.items,
        nextCursor: current.nextCursor,
        isLoadingMore: true,
      ),
    );
    final filter = ref.read(feedFilterProvider);

    try {
      final page = await ref
          .read(dataGatewayProvider)
          .getFeedPage(filter: filter, cursor: current.nextCursor);
      if (!ref.mounted || !identical(ref.read(feedFilterProvider), filter)) {
        return;
      }

      // Prevent duplicate Products in the feed.
      final existingIds = current.items.map((item) => item.product.id).toSet();
      final newItems = page.items
          .where((item) => existingIds.add(item.product.id))
          .toList();

      state = AsyncData(
        FeedState(
          items: [...current.items, ...newItems],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (error) {
      if (!ref.mounted || !identical(ref.read(feedFilterProvider), filter)) {
        return;
      }
      state = AsyncData(
        FeedState(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreError: error.toString(),
        ),
      );
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);

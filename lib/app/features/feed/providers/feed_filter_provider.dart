import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/models/event.dart';
import '../../events/providers/events_provider.dart';
import '../models/feed_filter.dart';

class FeedFilterNotifier extends Notifier<FeedFilter> {
  @override
  FeedFilter build() {
    return const FeedFilter();
  }

  void setCategory(String? category) => _set(FeedFilter(category: category));

  void setSearch(String query) => _set(FeedFilter(query: query.trim()));

  void clear() => _set(const FeedFilter());

  /// Changes the filter and records the change; the same filter again is
  /// no change.
  void _set(FeedFilter filter) {
    if (filter.category == state.category && filter.query == state.query) {
      return;
    }
    state = filter;
    ref
        .read(eventsLogProvider.notifier)
        .record(
          NewEvent(
            EventType.filterChange,
            details: {
              if (filter.category != null) 'category': filter.category!,
              if (filter.query.isNotEmpty) 'query': filter.query,
            },
          ),
        );
  }
}

final feedFilterProvider = NotifierProvider<FeedFilterNotifier, FeedFilter>(
  FeedFilterNotifier.new,
);

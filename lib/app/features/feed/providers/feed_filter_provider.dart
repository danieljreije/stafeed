import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_filter.dart';

class FeedFilterNotifier extends Notifier<FeedFilter> {
  @override
  FeedFilter build() {
    return const FeedFilter();
  }

  void setCategory(String? category) {
    state = FeedFilter(category: category);
  }

  void setSearch(String query) {
    state = FeedFilter(query: query.trim());
  }

  void clear() {
    state = const FeedFilter();
  }
}

final feedFilterProvider =
    NotifierProvider<FeedFilterNotifier, FeedFilter>(
  FeedFilterNotifier.new,
);
import 'package:flutter/foundation.dart';

import 'feed_item.dart';

/// Points at the next page of a feed. Only the data gateway that issued it
/// can read it; everyone else just hands it back.
@immutable
class FeedCursor {
  const FeedCursor(this.token);

  final String token;

  @override
  bool operator ==(Object other) => other is FeedCursor && other.token == token;

  @override
  int get hashCode => token.hashCode;

  @override
  String toString() => 'FeedCursor($token)';
}

/// One page of Feed Items.
class FeedPage {
  const FeedPage({required this.items, this.nextCursor});

  final List<FeedItem> items;

  /// Null when this is the last page.
  final FeedCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

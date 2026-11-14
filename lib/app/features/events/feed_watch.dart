import '../feed/models/feed_item.dart';
import 'models/event.dart';

/// Decides which Events the feed's swiping produces: an impression each
/// time a Feed Item comes on screen, a 2s and a 5s view while it stays, and
/// a Skip (or fast Skip) when the Shopper swipes past it quickly without
/// acting on it.
///
/// Pure: it is told what is on screen and when, and answers with the
/// Events to record. The feed screen supplies the times and the timers.
class FeedWatch {
  FeedWatch({required this.actedOn});

  /// On screen this long: a 2s view, and swiping away is no longer a Skip.
  static const Duration view2s = Duration(seconds: 2);

  /// On screen this long: a 5s view.
  static const Duration view5s = Duration(seconds: 5);

  /// Swiped past in less than this: a fast Skip instead of a Skip.
  static const Duration fastSkip = Duration(seconds: 1);

  /// Whether the Shopper did something with [item] (opened details, saved,
  /// shared, …) at or after [since]. A Feed Item acted on is never skipped.
  final bool Function(FeedItem item, DateTime since) actedOn;

  FeedItem? _current;
  DateTime? _shownAt;
  bool _viewed2s = false;
  bool _viewed5s = false;

  /// The Feed Item on screen, if any.
  FeedItem? get current => _current;

  /// [item] came on screen at [now], replacing the one before, which the
  /// Shopper swiped past. Showing the Feed Item already on screen again
  /// changes nothing.
  List<NewEvent> show(FeedItem item, DateTime now) {
    if (_current?.id == item.id) return const [];

    final events = leave(now, swiped: true);
    _current = item;
    _shownAt = now;
    _viewed2s = false;
    _viewed5s = false;
    return [...events, _event(EventType.impression, item, dwell: null)];
  }

  /// The views the Feed Item on screen has earned by [now] and not yet
  /// recorded.
  List<NewEvent> check(DateTime now) {
    final item = _current;
    final shownAt = _shownAt;
    if (item == null || shownAt == null) return const [];

    final dwell = now.difference(shownAt);
    final events = <NewEvent>[];
    if (!_viewed2s && dwell >= view2s) {
      _viewed2s = true;
      events.add(_event(EventType.view2s, item, dwell: view2s));
    }
    if (!_viewed5s && dwell >= view5s) {
      _viewed5s = true;
      events.add(_event(EventType.view5s, item, dwell: view5s));
    }
    return events;
  }

  /// Nothing is on screen any more from [now]. [swiped] says whether the
  /// Shopper swiped past it (which may be a Skip) or it went for another
  /// reason, like a new filter or another tab (never a Skip).
  List<NewEvent> leave(DateTime now, {required bool swiped}) {
    final item = _current;
    final shownAt = _shownAt;
    if (item == null || shownAt == null) return const [];

    final events = check(now);
    final dwell = now.difference(shownAt);
    if (swiped && dwell < view2s && !actedOn(item, shownAt)) {
      events.add(
        _event(
          dwell < fastSkip ? EventType.fastSkip : EventType.skip,
          item,
          dwell: dwell,
        ),
      );
    }

    _current = null;
    _shownAt = null;
    return events;
  }

  /// How long from [now] until the next view is due; null when none is.
  Duration? untilNextCheck(DateTime now) {
    final shownAt = _shownAt;
    if (shownAt == null) return null;
    final due = !_viewed2s
        ? view2s
        : !_viewed5s
        ? view5s
        : null;
    if (due == null) return null;
    final left = due - now.difference(shownAt);
    return left.isNegative ? Duration.zero : left;
  }

  static NewEvent _event(
    EventType type,
    FeedItem item, {
    required Duration? dwell,
  }) => NewEvent(
    type,
    feedItemId: item.id,
    productId: switch (item) {
      final ProductFeedItem productItem => productItem.product.id,
      BrandAd() => null,
    },
    offerId: switch (item) {
      final ProductFeedItem productItem => productItem.offer.id,
      BrandAd() => null,
    },
    isAd: item.isAd,
    dwell: dwell,
  );
}

/// Whether [events] hold an action on [item] at or after [since]: one about
/// the Feed Item itself or any of its Products.
bool actedOnFeedItem(Iterable<Event> events, FeedItem item, DateTime since) {
  final productIds = {for (final product in item.products) product.id};
  return events.any(
    (event) =>
        event.type.isAction &&
        !event.occurredAt.isBefore(since) &&
        (event.feedItemId == item.id || productIds.contains(event.productId)),
  );
}

import '../events/models/event.dart';
import 'ranking.dart';

/// One taste signal about a Product, by its ID. The data gateway looks the
/// Product up to learn its Brand, category and price.
class ProductSignal {
  const ProductSignal(this.type, this.productId);

  final SignalType type;
  final String productId;
}

/// What the data gateway ranks For You with: the Shopper's interests, the
/// Products they marked Not interested, and their long-term taste signals.
class ShopperTaste {
  const ShopperTaste({
    this.interests = const {},
    this.notInterested = const {},
    this.signals = const [],
    this.sessionSignals = const {},
  });

  /// What the Shopper did inside each Shopping Session, by session ID,
  /// oldest first. Only ever used for that session's own feed.
  final Map<String, List<ProductSignal>> sessionSignals;

  /// Categories picked at onboarding.
  final Set<String> interests;

  /// Product IDs never to show again.
  final Set<String> notInterested;

  /// Oldest first.
  final List<ProductSignal> signals;
}

/// The long-term taste signals in [events]: every Event about a Product
/// that says something about taste, outside any Shopping Session.
/// Impressions, unsaves, reports and filter changes say nothing.
List<ProductSignal> longTermSignals(Iterable<Event> events) => [
  for (final event in events)
    if (event.sessionId == null)
      if (event.productId case final productId?)
        if (signalFor(event.type) case final type?)
          ProductSignal(type, productId),
];

/// The taste signals in [events] that happened inside a Shopping Session,
/// grouped by session ID. Never mixed into the long-term ones.
Map<String, List<ProductSignal>> sessionSignals(Iterable<Event> events) {
  final bySession = <String, List<ProductSignal>>{};
  for (final event in events) {
    final sessionId = event.sessionId;
    final productId = event.productId;
    final type = signalFor(event.type);
    if (sessionId == null || productId == null || type == null) continue;
    (bySession[sessionId] ??= []).add(ProductSignal(type, productId));
  }
  return bySession;
}

/// The taste signal an Event of [type] gives, if any.
SignalType? signalFor(EventType type) => switch (type) {
  EventType.notInterested => SignalType.notInterested,
  EventType.fastSkip => SignalType.fastSkip,
  EventType.skip => SignalType.skip,
  EventType.view2s => SignalType.view2s,
  EventType.view5s => SignalType.view5s,
  EventType.detailOpen => SignalType.details,
  EventType.share => SignalType.share,
  EventType.save => SignalType.save,
  EventType.outboundClick => SignalType.outboundClick,
  EventType.impression ||
  EventType.unsave ||
  EventType.filterChange ||
  EventType.sessionStart ||
  EventType.sessionEnd ||
  EventType.report => null,
};

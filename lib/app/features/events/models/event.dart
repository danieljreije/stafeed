import 'package:flutter/foundation.dart';

/// What a Shopper did, as recorded in an [Event].
enum EventType {
  impression('Impression'),
  view2s('Viewed 2s'),
  view5s('Viewed 5s'),
  skip('Skip'),
  fastSkip('Fast skip'),
  detailOpen('Details opened'),
  save('Save'),
  unsave('Unsave'),
  notInterested('Not interested'),
  share('Share'),
  outboundClick('Outbound Click'),
  filterChange('Filter change'),
  sessionStart('Session start'),
  sessionEnd('Session end'),
  report('Report');

  const EventType(this.label);

  /// How the debug Events screen names it.
  final String label;

  /// Whether the Shopper did something with a Product, as opposed to only
  /// looking at it or swiping past. A Feed Item acted on is never a Skip.
  bool get isAction => switch (this) {
    detailOpen ||
    save ||
    unsave ||
    notInterested ||
    share ||
    outboundClick ||
    report => true,
    _ => false,
  };
}

/// An Event about to be recorded: what happened and to what. The Events log
/// gives it its unique ID and timestamp.
@immutable
class NewEvent {
  const NewEvent(
    this.type, {
    this.feedItemId,
    this.productId,
    this.offerId,
    this.sessionId,
    this.isAd,
    this.dwell,
    this.details = const {},
  });

  final EventType type;

  /// The Feed Item it happened on, when it happened in the feed.
  final String? feedItemId;
  final String? productId;
  final String? offerId;

  /// The Shopping Session it happened in. Always null until Shopping
  /// Sessions exist (#11).
  final String? sessionId;

  /// For Events about a Feed Item: whether that Feed Item is an Ad.
  final bool? isAd;

  /// How long the Feed Item had been on screen.
  final Duration? dwell;

  /// Anything else worth keeping, e.g. the new filter of a filter change.
  final Map<String, String> details;
}

/// A recorded Shopper action, kept on the phone until it is sent.
@immutable
class Event {
  const Event({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.feedItemId,
    this.productId,
    this.offerId,
    this.sessionId,
    this.isAd,
    this.dwell,
    this.details = const {},
  });

  /// [event] as it happened at [occurredAt], under [id].
  Event.from(NewEvent event, {required this.id, required DateTime occurredAt})
    : type = event.type,
      occurredAt = occurredAt.toUtc(),
      feedItemId = event.feedItemId,
      productId = event.productId,
      offerId = event.offerId,
      sessionId = event.sessionId,
      isAd = event.isAd,
      dwell = event.dwell,
      details = event.details;

  /// Unique across every Event, so the backend can drop a duplicate.
  final String id;
  final EventType type;

  /// When it happened, in UTC.
  final DateTime occurredAt;
  final String? feedItemId;
  final String? productId;
  final String? offerId;
  final String? sessionId;
  final bool? isAd;
  final Duration? dwell;
  final Map<String, String> details;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'occurredAt': occurredAt.toIso8601String(),
    if (feedItemId != null) 'feedItemId': feedItemId,
    if (productId != null) 'productId': productId,
    if (offerId != null) 'offerId': offerId,
    if (sessionId != null) 'sessionId': sessionId,
    if (isAd != null) 'isAd': isAd,
    if (dwell != null) 'dwellMs': dwell!.inMilliseconds,
    if (details.isNotEmpty) 'details': details,
  };

  /// Throws [FormatException] when [json] isn't a stored Event.
  factory Event.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Not an Event');
    final id = json['id'];
    final typeName = json['type'];
    final occurredAt = DateTime.tryParse('${json['occurredAt']}');
    final type = EventType.values.asNameMap()[typeName];
    if (id is! String || type == null || occurredAt == null) {
      throw const FormatException('Not an Event');
    }

    String? text(String key) {
      final value = json[key];
      return value is String ? value : null;
    }

    final isAd = json['isAd'];
    final dwellMs = json['dwellMs'];
    final details = json['details'];
    return Event(
      id: id,
      type: type,
      occurredAt: occurredAt.toUtc(),
      feedItemId: text('feedItemId'),
      productId: text('productId'),
      offerId: text('offerId'),
      sessionId: text('sessionId'),
      isAd: isAd is bool ? isAd : null,
      dwell: dwellMs is int ? Duration(milliseconds: dwellMs) : null,
      details: details is Map
          ? {
              for (final entry in details.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            }
          : const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Event &&
      other.id == id &&
      other.type == type &&
      other.occurredAt == occurredAt &&
      other.feedItemId == feedItemId &&
      other.productId == productId &&
      other.offerId == offerId &&
      other.sessionId == sessionId &&
      other.isAd == isAd &&
      other.dwell == dwell &&
      mapEquals(other.details, details);

  @override
  int get hashCode => Object.hash(
    id,
    type,
    occurredAt,
    feedItemId,
    productId,
    offerId,
    sessionId,
    isAd,
    dwell,
    Object.hashAllUnordered(details.entries.map((e) => '${e.key}=${e.value}')),
  );

  @override
  String toString() =>
      'Event($id, ${type.name}, $occurredAt, item: $feedItemId, '
      'product: $productId, dwell: $dwell)';
}

/// How many Ads the Shopper was shown this week (since Monday 00:00, local
/// time), counted from impressions. An Ad shown again counts again.
int adsWatchedThisWeek(Iterable<Event> events, DateTime now) {
  final local = now.toLocal();
  final weekStart = DateTime(
    local.year,
    local.month,
    local.day - (local.weekday - DateTime.monday),
  );
  return events
      .where(
        (event) =>
            event.type == EventType.impression &&
            event.isAd == true &&
            !event.occurredAt.isBefore(weekStart) &&
            !event.occurredAt.isAfter(now),
      )
      .length;
}

/// Profile's line about the Ads the Shopper watched.
String adsWatchedLine(int count) =>
    "You've watched $count ${count == 1 ? 'ad' : 'ads'} this week. "
    'Advertisers thank you.';

// Impression, dwell and Skip detection in the feed (ticket #9).

import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/events/feed_watch.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/media.dart';

import '../saved/support/saved_fixtures.dart';

void main() {
  final start = DateTime.utc(2026, 11, 14, 12);
  DateTime at(int milliseconds) =>
      start.add(Duration(milliseconds: milliseconds));

  final shoe = savedTestProduct('shoe');
  final bag = savedTestProduct('bag');
  final shoeAd = AffiliateAd(product: shoe, offer: shoe.offers.first);
  final bagAd = AffiliateAd(product: bag, offer: bag.offers.first);
  final brandAd = BrandAd(
    id: 'brand-1',
    brand: 'Northstar',
    headline: 'Run further',
    media: const [ImageMedia('https://img.example/b.jpg')],
    products: [shoe],
  );

  List<EventType> types(List<NewEvent> events) => [
    for (final event in events) event.type,
  ];

  FeedWatch watch({Set<String> actedOnIds = const {}}) =>
      FeedWatch(actedOn: (item, since) => actedOnIds.contains(item.id));

  test('showing a Feed Item records one impression with what it is', () {
    final events = watch().show(shoeAd, start);

    expect(types(events), [EventType.impression]);
    expect(events.single.feedItemId, 'shoe');
    expect(events.single.productId, 'shoe');
    expect(events.single.offerId, 'shoe-offer');
    expect(events.single.isAd, isTrue);
  });

  test('the same Feed Item shown again without leaving is not a new '
      'impression', () {
    final feed = watch()..show(shoeAd, start);

    expect(feed.show(shoeAd, at(500)), isEmpty);
  });

  test('a Brand Ad is recorded as an Ad with no single Product', () {
    final event = watch().show(brandAd, start).single;

    expect(event.feedItemId, 'brand-1');
    expect(event.productId, isNull);
    expect(event.isAd, isTrue);
  });

  test('staying 2s and 5s records each view once', () {
    final feed = watch()..show(shoeAd, start);

    expect(feed.check(at(1999)), isEmpty);
    expect(types(feed.check(at(2000))), [EventType.view2s]);
    expect(feed.check(at(3000)), isEmpty);
    expect(types(feed.check(at(5000))), [EventType.view5s]);
    expect(feed.check(at(60000)), isEmpty);
  });

  test('a late check records both views it missed, in order', () {
    final feed = watch()..show(shoeAd, start);

    final events = feed.check(at(7000));

    expect(types(events), [EventType.view2s, EventType.view5s]);
    expect(events.map((e) => e.dwell), [
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ]);
  });

  test('tells when the next view is due', () {
    final feed = watch();
    expect(feed.untilNextCheck(start), isNull);

    feed.show(shoeAd, start);
    expect(feed.untilNextCheck(at(500)), const Duration(milliseconds: 1500));
    feed.check(at(2000));
    expect(feed.untilNextCheck(at(2000)), const Duration(seconds: 3));
    feed.check(at(5000));
    expect(feed.untilNextCheck(at(5000)), isNull);
  });

  test('swiping past within 1s is a fast Skip, then the next impression', () {
    final feed = watch()..show(shoeAd, start);

    final events = feed.show(bagAd, at(600));

    expect(types(events), [EventType.fastSkip, EventType.impression]);
    expect(events.first.feedItemId, 'shoe');
    expect(events.first.dwell, const Duration(milliseconds: 600));
    expect(events.last.feedItemId, 'bag');
  });

  test('swiping past between 1s and 2s is a Skip', () {
    final feed = watch()..show(shoeAd, start);

    final events = feed.show(bagAd, at(1500));

    expect(types(events), [EventType.skip, EventType.impression]);
    expect(events.first.dwell, const Duration(milliseconds: 1500));
  });

  test('swiping past after 2s is a view, not a Skip', () {
    final feed = watch()..show(shoeAd, start);

    expect(types(feed.show(bagAd, at(2500))), [
      EventType.view2s,
      EventType.impression,
    ]);
  });

  test('swiping past a Feed Item the Shopper acted on is not a Skip', () {
    final feed = watch(actedOnIds: {'shoe'})..show(shoeAd, start);

    expect(types(feed.show(bagAd, at(300))), [EventType.impression]);
  });

  test('leaving without a swipe (new filter, other tab) is never a Skip', () {
    final feed = watch()..show(shoeAd, start);

    expect(feed.leave(at(300), swiped: false), isEmpty);
    expect(feed.current, isNull);
    expect(feed.check(at(5000)), isEmpty);
  });

  test('swiping past the last Feed Item to the end page can be a Skip', () {
    final feed = watch()..show(shoeAd, start);

    expect(types(feed.leave(at(300), swiped: true)), [EventType.fastSkip]);
  });

  test('coming back to a Feed Item is a new impression', () {
    final feed = watch()
      ..show(shoeAd, start)
      ..show(bagAd, at(3000));

    expect(types(feed.show(shoeAd, at(6000))), [
      EventType.view2s,
      EventType.impression,
    ]);
  });

  group('actedOnFeedItem', () {
    Event action(
      EventType type, {
      String? feedItemId,
      String? productId,
      int atMs = 100,
    }) => Event(
      id: '$type-$atMs',
      type: type,
      occurredAt: at(atMs),
      feedItemId: feedItemId,
      productId: productId,
    );

    test('counts actions on the Feed Item or its Products since it showed', () {
      expect(
        actedOnFeedItem(
          [action(EventType.save, productId: 'shoe')],
          shoeAd,
          start,
        ),
        isTrue,
      );
      expect(
        actedOnFeedItem(
          [action(EventType.detailOpen, feedItemId: 'brand-1')],
          brandAd,
          start,
        ),
        isTrue,
      );
      expect(
        actedOnFeedItem(
          [action(EventType.detailOpen, productId: 'shoe')],
          brandAd,
          start,
        ),
        isTrue,
        reason: 'a Brand Ad is acted on through its linked Products',
      );
    });

    test('ignores looking, other Products and earlier actions', () {
      expect(
        actedOnFeedItem(
          [
            action(EventType.impression, feedItemId: 'shoe', productId: 'shoe'),
            action(EventType.view2s, feedItemId: 'shoe', productId: 'shoe'),
            action(EventType.save, productId: 'bag'),
            action(EventType.save, productId: 'shoe', atMs: -1),
          ],
          shoeAd,
          start,
        ),
        isFalse,
      );
    });
  });
}

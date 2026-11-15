import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/ranking/ranking.dart';
import 'package:stafeed/app/features/ranking/shopper_taste.dart';

/// Every Feed Item of a feed, page after page.
Future<List<FeedItem>> wholeFeed(
  FixtureDataGateway gateway,
  FeedFilter filter,
) async {
  final items = <FeedItem>[];
  var page = await gateway.getFeedPage(filter: filter);
  items.addAll(page.items);
  while (page.nextCursor != null) {
    page = await gateway.getFeedPage(filter: filter, cursor: page.nextCursor);
    items.addAll(page.items);
  }
  return items;
}

String brandOf(FeedItem item) => switch (item) {
  BrandAd(:final brand) => brand,
  ProductFeedItem(:final product) => product.brand,
};

void main() {
  const session = FeedFilter(sessionId: 's1');

  test('Not an Ad fills a Shopping Session, never For You', () async {
    final gateway = FixtureDataGateway();

    final forYou = await wholeFeed(gateway, const FeedFilter());
    final inSession = await wholeFeed(gateway, session);

    expect(forYou.whereType<NotAnAd>(), isEmpty);
    expect(inSession.whereType<NotAnAd>(), isNotEmpty);
    // Every Ad of For You is still there; Not an Ad only adds to it.
    expect(
      inSession.where((item) => item.isAd).map((item) => item.id).toSet(),
      forYou.map((item) => item.id).toSet(),
    );
  });

  test('Not an Ad comes after the Ads it competes with', () async {
    final items = await wholeFeed(
      FixtureDataGateway(),
      const FeedFilter(sessionId: 's1', category: 'sneakers'),
    );

    final firstNotAnAd = items.indexWhere((item) => item is NotAnAd);
    expect(firstNotAnAd, greaterThan(0));
    expect(items.take(firstNotAnAd).every((item) => item.isAd), isTrue);
  });

  test('a session narrowed to a Brand shows only that Brand', () async {
    final gateway = FixtureDataGateway();
    final brand = (await gateway.getSupportedFilters()).brands.first;

    final items = await wholeFeed(
      gateway,
      FeedFilter(sessionId: 's1', brand: brand),
    );

    expect(items, isNotEmpty);
    expect(items.map(brandOf), everyElement(brand));
  });

  test('a session budget leaves out what costs more', () async {
    final items = await wholeFeed(
      FixtureDataGateway(destinationCountry: 'US'),
      const FeedFilter(sessionId: 's1', maxPrice: Money(10000, 'USD')),
    );

    expect(items, isNotEmpty);
    for (final item in items.whereType<ProductFeedItem>()) {
      expect(item.offer.price.currencyCode, 'USD');
      expect(item.offer.price.minorUnits, lessThanOrEqualTo(10000));
    }
  });

  test('the source says which session filters it supports', () async {
    final filters = await FixtureDataGateway().getSupportedFilters();

    expect(filters.supportsMaxPrice, isTrue);
    expect(filters.brands, isNotEmpty);
    expect(filters.brands, orderedEquals([...filters.brands]..sort()));
  });

  test('what happens in a session ranks that session, never For You', () async {
    final baseline = FixtureDataGateway();
    final watches = (await wholeFeed(baseline, const FeedFilter()))
        .whereType<AffiliateAd>()
        .where((ad) => ad.product.category == 'watches')
        .toList();

    // Lots of saves of watches, all inside session s1.
    final taste = ShopperTaste(
      sessionSignals: {
        's1': [
          for (final ad in watches)
            ProductSignal(SignalType.save, ad.product.id),
        ],
      },
    );
    final withSessionTaste = FixtureDataGateway(taste: () async => taste);

    final forYouBefore = await wholeFeed(baseline, const FeedFilter());
    final forYouAfter = await wholeFeed(withSessionTaste, const FeedFilter());
    expect(
      forYouAfter.map((item) => item.id),
      orderedEquals(forYouBefore.map((item) => item.id)),
    );

    final sessionFirst = (await withSessionTaste.getFeedPage(filter: session))
        .items
        .first;
    expect(sessionFirst.products.first.category, 'watches');

    // Another session doesn't see s1's taste either.
    final otherFirst = (await withSessionTaste.getFeedPage(
      filter: const FeedFilter(sessionId: 's2'),
    )).items.first;
    final plainFirst = (await baseline.getFeedPage(
      filter: const FeedFilter(sessionId: 's2'),
    )).items.first;
    expect(otherFirst.id, plainFirst.id);
  });

  test('a cursor only continues its own session and filters', () async {
    final gateway = FixtureDataGateway();
    final page = await gateway.getFeedPage(filter: session);

    expect(
      () => gateway.getFeedPage(
        filter: const FeedFilter(sessionId: 's2'),
        cursor: page.nextCursor,
      ),
      throwsArgumentError,
    );
    expect(
      () => gateway.getFeedPage(
        filter: const FeedFilter(sessionId: 's1', maxPrice: Money(5000, 'USD')),
        cursor: page.nextCursor,
      ),
      throwsArgumentError,
    );
  });
}

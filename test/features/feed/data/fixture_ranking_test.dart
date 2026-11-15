import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_brand_ads.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/ranking/ranking.dart';
import 'package:stafeed/app/features/ranking/shopper_taste.dart';

import 'fixture_data_gateway_test.dart' show readWholeFeed;

/// The Fixture gateway ranks For You (#10).
void main() {
  String brandOf(FeedItem item) => switch (item) {
    BrandAd(:final brand) => brand,
    ProductFeedItem(:final product) => product.brand,
  };

  FixtureDataGateway withTaste(ShopperTaste taste, {String? country}) =>
      FixtureDataGateway(destinationCountry: country, taste: () async => taste);

  test(
    'never the same Brand twice in a row, in every country and filter',
    () async {
      for (final country in [null, 'US', 'GB', 'AE', 'LB']) {
        for (final filter in [
          const FeedFilter(),
          const FeedFilter(category: 'sneakers'),
          const FeedFilter(query: 'Northstar'),
        ]) {
          final items = await readWholeFeed(
            FixtureDataGateway(destinationCountry: country),
            filter: filter,
          );
          final brands = items.map(brandOf).toList();
          final everyBrandTheSame = brands.toSet().length == 1;
          if (everyBrandTheSame) continue;

          for (var i = 1; i < brands.length; i++) {
            // The last few may have to repeat when only one Brand is left.
            final left = brands.sublist(i).toSet();
            if (left.length == 1 && left.single == brands[i - 1]) break;
            expect(
              brands[i],
              isNot(brands[i - 1]),
              reason: '$country ${filter.category} ${filter.query} at $i',
            );
          }
        }
      }
    },
  );

  test('cold start: the Shopper\'s interests come first', () async {
    final items = await readWholeFeed(
      withTaste(const ShopperTaste(interests: {'watches'})),
    );
    final watches = items
        .where((item) => item.products.any((p) => p.category == 'watches'))
        .length;

    expect(watches, greaterThan(0));
    expect(
      items.take(watches),
      everyElement(
        predicate<FeedItem>(
          (item) => item.products.any((p) => p.category == 'watches'),
        ),
      ),
    );
  });

  test('a Product marked Not interested is never served again', () async {
    final hidden = fixtureBrandAds.first.products.first;
    final items = await readWholeFeed(
      withTaste(ShopperTaste(notInterested: {hidden.id})),
    );

    expect(
      items.whereType<ProductFeedItem>().map((i) => i.product.id),
      isNot(contains(hidden.id)),
    );
    // A Brand Ad linking it keeps its other Products.
    final ad = items.whereType<BrandAd>().firstWhere(
      (ad) => ad.id == fixtureBrandAds.first.id,
    );
    expect(ad.products.map((p) => p.id), isNot(contains(hidden.id)));
    expect(ad.products, isNotEmpty);
  });

  test('the gateway hides a Product as soon as it is marked', () async {
    final gateway = FixtureDataGateway();
    final first = (await gateway.getFeedPage()).items.first as AffiliateAd;

    await gateway.markNotInterested(first.product.id);
    final items = await readWholeFeed(gateway);

    expect(gateway.notInterestedProductIds, {first.product.id});
    expect(items.map((i) => i.id), isNot(contains(first.id)));
  });

  test('Not interested ranks the same Brand and category lower in the pages '
      'still to come', () async {
    final rejected = fixtureProducts.firstWhere(
      (p) => p.id == 'fixture-snk-01',
    );
    // Same Brand and category as the rejected Product.
    final similar = fixtureProducts.firstWhere((p) => p.id == 'fixture-snk-04');

    final before = await readWholeFeed(FixtureDataGateway());
    final after = await readWholeFeed(
      withTaste(
        ShopperTaste(
          notInterested: {rejected.id},
          signals: [ProductSignal(SignalType.notInterested, rejected.id)],
        ),
      ),
    );

    int place(List<FeedItem> items) =>
        items.indexWhere((item) => item.id == similar.id);
    expect(place(after), greaterThan(place(before) + 5));
  });

  test('each page is ranked from the taste at that moment, with no repeats and '
      'nothing lost', () async {
    var taste = const ShopperTaste();
    final gateway = FixtureDataGateway(taste: () async => taste);

    final first = await gateway.getFeedPage();
    // The Shopper saves a watch while browsing the first page.
    final watch = fixtureProducts.firstWhere((p) => p.category == 'watches');
    taste = ShopperTaste(signals: [ProductSignal(SignalType.save, watch.id)]);

    final rest = <FeedItem>[];
    FeedCursor? cursor = first.nextCursor;
    while (cursor != null) {
      final page = await gateway.getFeedPage(cursor: cursor);
      rest.addAll(page.items);
      cursor = page.nextCursor;
    }

    final all = [...first.items, ...rest];
    final everything = await readWholeFeed(FixtureDataGateway());
    expect(all.map((i) => i.id).toSet(), hasLength(all.length));
    expect(all.map((i) => i.id), unorderedEquals(everything.map((i) => i.id)));

    // Watches now come right after the first page.
    expect(rest.first.products.any((p) => p.category == 'watches'), isTrue);
    expect(
      everything
          .sublist(first.items.length)
          .first
          .products
          .any((p) => p.category == 'watches'),
      isFalse,
    );
  });
}

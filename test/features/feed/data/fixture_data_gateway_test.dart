import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_brand_ads.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/models/media.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/models/offer.dart';
import 'package:stafeed/app/features/feed/models/product.dart';

/// Walks every page of a feed through the gateway, following its cursors.
Future<List<FeedItem>> readWholeFeed(
  FixtureDataGateway gateway, {
  FeedFilter filter = const FeedFilter(),
}) async {
  final items = <FeedItem>[];
  FeedCursor? cursor;
  var pages = 0;

  do {
    final page = await gateway.getFeedPage(filter: filter, cursor: cursor);
    items.addAll(page.items);
    cursor = page.nextCursor;
    pages++;
    expect(pages, lessThan(100), reason: 'feed never ended');
  } while (cursor != null);

  return items;
}

void main() {
  late FixtureDataGateway gateway;

  setUp(() {
    gateway = FixtureDataGateway();
  });

  test('serves sample data', () {
    expect(gateway.servesSampleData, isTrue);
  });

  group('Fixtures', () {
    test(
      'cover about 56 Products across sneakers and 4 other categories',
      () async {
        final filters = await gateway.getSupportedFilters();
        final categoryIds = filters.categories.map((c) => c.id).toList();

        expect(categoryIds, [
          'sneakers',
          'bags',
          'watches',
          'tech-accessories',
          'home-decor',
        ]);
        expect(filters.categories.first.label, 'Sneakers');
      },
    );

    test(
      'have at least 8 Brands, two currencies and varied ships-to countries',
      () async {
        final items = await readWholeFeed(gateway);

        final affiliateAds = items.whereType<AffiliateAd>();

        final brands = affiliateAds.map((i) => i.product.brand).toSet();
        final currencies = affiliateAds
            .map((i) => i.offer.price.currencyCode)
            .toSet();
        final shipsTo = affiliateAds.map((i) => i.offer.shipsTo).toSet();

        expect(brands.length, greaterThanOrEqualTo(8));
        expect(currencies, {'USD', 'GBP'});
        expect(shipsTo.length, greaterThan(1));
      },
    );
  });

  group('For You feed', () {
    test(
      'first page is a full page of Ads with a cursor to the next page',
      () async {
        final page = await gateway.getFeedPage();

        expect(page.items, hasLength(FixtureDataGateway.defaultPageSize));
        expect(page.items.every((item) => item.isAd), isTrue);
        expect(page.nextCursor, isNotNull);
      },
    );

    test('pages through every Ad exactly once, then ends', () async {
      final items = await readWholeFeed(gateway);
      final ids = items.map((i) => i.id).toList();

      expect(ids.toSet(), hasLength(ids.length), reason: 'no repeats');
      expect(items.length, inInclusiveRange(48, 56));
      expect(items.every((item) => item.isAd), isTrue);
    });

    test('never includes Not an Ad Products', () async {
      final items = await readWholeFeed(gateway);

      expect(items.whereType<NotAnAd>(), isEmpty);
      expect(
        items.whereType<ProductFeedItem>().any((i) => !i.offer.isAffiliate),
        isFalse,
      );
    });

    test('only offers that are available', () async {
      final items = await readWholeFeed(gateway);

      expect(
        items.whereType<ProductFeedItem>().every((i) => i.offer.isAvailable),
        isTrue,
      );
    });

    test('is deterministic across gateway instances', () async {
      final first = await readWholeFeed(FixtureDataGateway());
      final second = await readWholeFeed(FixtureDataGateway());

      expect(first.map((i) => i.id).toList(), second.map((i) => i.id).toList());
    });

    test('asking for the same cursor twice returns the same page', () async {
      final firstPage = await gateway.getFeedPage();
      final cursor = firstPage.nextCursor!;

      final once = await gateway.getFeedPage(cursor: cursor);
      final twice = await gateway.getFeedPage(cursor: cursor);

      expect(once.items.map((i) => i.id), twice.items.map((i) => i.id));
      expect(once.nextCursor, twice.nextCursor);
    });

    test('second page continues where the first page stopped', () async {
      final firstPage = await gateway.getFeedPage();
      final secondPage = await gateway.getFeedPage(
        cursor: firstPage.nextCursor,
      );
      final whole = await readWholeFeed(gateway);

      expect(
        [...firstPage.items, ...secondPage.items].map((i) => i.id),
        whole
            .take(firstPage.items.length + secondPage.items.length)
            .map((i) => i.id),
      );
    });
  });

  group('Brand Ads', () {
    test('the Fixtures include 2 to 3 Brand Ads, all images', () async {
      final ads = (await readWholeFeed(gateway)).whereType<BrandAd>().toList();

      expect(ads.length, inInclusiveRange(2, 3));
      expect(ads.map((ad) => ad.id), fixtureBrandAds.map((ad) => ad.id));
      for (final ad in ads) {
        expect(ad.isSponsored, isTrue);
        expect(ad.media, isNotEmpty);
        expect(ad.media, everyElement(isA<ImageMedia>()));
        expect(ad.products, isNotEmpty);
      }
    });

    test('at least one has several images to swipe through', () {
      expect(fixtureBrandAds.any((ad) => ad.media.length > 1), isTrue);
    });

    test('each links Products that are in the feed themselves', () async {
      final items = await readWholeFeed(gateway);
      final affiliateProductIds = {
        for (final item in items.whereType<AffiliateAd>()) item.product.id,
      };

      for (final ad in items.whereType<BrandAd>()) {
        expect(
          ad.products.map((p) => p.id),
          everyElement(isIn(affiliateProductIds)),
          reason: ad.id,
        );
      }
    });

    test('each comes right after the last of its linked Products', () async {
      final items = await readWholeFeed(gateway);

      for (final ad in items.whereType<BrandAd>()) {
        final before = items[items.indexOf(ad) - 1];

        expect(before, isA<AffiliateAd>(), reason: ad.id);
        expect(before.id, ad.products.last.id, reason: ad.id);
      }
    });

    test('the feed opens on three Affiliate Ads', () async {
      final page = await gateway.getFeedPage();

      expect(page.items.take(3), everyElement(isA<AffiliateAd>()));
    });

    test(
      'a category filter keeps a Brand Ad linked to that category',
      () async {
        final ad = fixtureBrandAds.first;
        final category = ad.products.first.category;
        final other = fixtureCategories
            .map((c) => c.id)
            .firstWhere((id) => ad.products.every((p) => p.category != id));

        final inCategory = await readWholeFeed(
          gateway,
          filter: FeedFilter(category: category),
        );
        final elsewhere = await readWholeFeed(
          gateway,
          filter: FeedFilter(category: other),
        );

        expect(inCategory.map((i) => i.id), contains(ad.id));
        expect(elsewhere.map((i) => i.id), isNot(contains(ad.id)));
      },
    );

    test('search finds a Brand Ad by its Brand and by its headline', () async {
      final ad = fixtureBrandAds.first;

      final byBrand = await readWholeFeed(
        gateway,
        filter: FeedFilter(query: ad.brand.toUpperCase()),
      );
      final byHeadline = await readWholeFeed(
        gateway,
        filter: FeedFilter(query: ad.headline),
      );

      expect(byBrand.map((i) => i.id), contains(ad.id));
      expect(byHeadline.map((i) => i.id), [ad.id]);
    });

    test('a Brand Ad whose Products are not in the feed goes last', () async {
      final unlinked = BrandAd(
        id: 'unlinked',
        brand: 'Nobody',
        headline: 'Nothing to see',
        media: const [],
        products: const [],
      );
      final items = await readWholeFeed(
        FixtureDataGateway(brandAds: [unlinked]),
      );

      expect(items.last, same(unlinked));
      expect(items.whereType<BrandAd>(), hasLength(1));
    });
  });

  group('Category filter', () {
    test('returns only Products in that category, across all pages', () async {
      final items = await readWholeFeed(
        gateway,
        filter: const FeedFilter(category: 'watches'),
      );

      expect(items, isNotEmpty);
      expect(
        items.every((i) => i.products.any((p) => p.category == 'watches')),
        isTrue,
      );
    });

    test('sneakers span several pages', () async {
      final firstPage = await gateway.getFeedPage(
        filter: const FeedFilter(category: 'sneakers'),
      );
      final all = await readWholeFeed(
        gateway,
        filter: const FeedFilter(category: 'sneakers'),
      );

      expect(firstPage.nextCursor, isNotNull);
      expect(all.length, greaterThan(firstPage.items.length));
    });

    test('an unknown category gives an empty last page', () async {
      final page = await gateway.getFeedPage(
        filter: const FeedFilter(category: 'no-such-category'),
      );

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('Search', () {
    test('matches title, Brand and category, ignoring case', () async {
      final everything = await readWholeFeed(gateway);
      final someItem = everything[3] as AffiliateAd;

      final byTitle = await readWholeFeed(
        gateway,
        filter: FeedFilter(query: someItem.product.title.toUpperCase()),
      );
      final byBrand = await readWholeFeed(
        gateway,
        filter: FeedFilter(query: someItem.product.brand.toLowerCase()),
      );
      final byCategory = await readWholeFeed(
        gateway,
        filter: const FeedFilter(query: 'sneakers'),
      );

      expect(byTitle.map((i) => i.id), contains(someItem.id));
      expect(byBrand, isNotEmpty);
      expect(
        byBrand.every(
          (i) => i.products.any((p) => p.brand == someItem.product.brand),
        ),
        isTrue,
      );
      expect(byCategory, isNotEmpty);
      expect(
        byCategory.every(
          (i) => i.products.any((p) => p.category == 'sneakers'),
        ),
        isTrue,
      );
    });

    test('needs every word to match', () async {
      final items = await readWholeFeed(
        gateway,
        filter: const FeedFilter(query: 'running sneakers'),
      );

      expect(items, isNotEmpty);
      expect(
        items.every(
          (i) => i.products.any(
            (p) =>
                p.category == 'sneakers' && p.attributes['style'] == 'Running',
          ),
        ),
        isTrue,
      );
    });

    test('with no matches gives an empty last page', () async {
      final page = await gateway.getFeedPage(
        filter: const FeedFilter(query: 'zzz no such thing'),
      );

      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });
  });

  group('Cursors are opaque and tied to their filter', () {
    test('a cursor from one filter is rejected for another', () async {
      final page = await gateway.getFeedPage(
        filter: const FeedFilter(category: 'sneakers'),
      );

      await expectLater(
        gateway.getFeedPage(
          filter: const FeedFilter(category: 'bags'),
          cursor: page.nextCursor,
        ),
        throwsArgumentError,
      );
    });

    test('a made-up cursor is rejected', () async {
      await expectLater(
        gateway.getFeedPage(cursor: const FeedCursor('10')),
        throwsArgumentError,
      );
    });

    test('a cursor does not expose a plain offset', () async {
      final page = await gateway.getFeedPage();

      expect(int.tryParse(page.nextCursor!.token), isNull);
    });
  });

  group('Destination Country', () {
    const countries = ['US', 'GB', 'AE', 'LB'];

    Product product(String id, List<Offer> offers) => Product(
      id: id,
      title: 'Product $id',
      description: '',
      brand: 'Brand',
      category: 'sneakers',
      imageUrls: const [],
      offers: offers,
    );

    Offer offer(
      String id,
      Set<String> shipsTo, {
      bool isAffiliate = true,
      bool isAvailable = true,
    }) => Offer(
      id: id,
      merchant: 'Merchant $id',
      price: const Money(1000, 'USD'),
      shipsTo: shipsTo,
      url: Uri.https('example.com', '/$id'),
      isAffiliate: isAffiliate,
      isAvailable: isAvailable,
    );

    bool canBeBoughtIn(Product product, String country) => product.offers.any(
      (offer) => offer.isAvailable && offer.shipsTo.contains(country),
    );

    test('every Offer in the feed ships there, for each country', () async {
      for (final country in countries) {
        final items = await readWholeFeed(
          FixtureDataGateway(destinationCountry: country),
        );
        final offers = items.whereType<ProductFeedItem>().map((i) => i.offer);

        expect(offers, isNotEmpty, reason: country);
        expect(
          offers.every((offer) => offer.shipsTo.contains(country)),
          isTrue,
          reason: country,
        );
      }
    });

    test(
      'holds exactly the Fixtures with an Ad Offer that ships there',
      () async {
        for (final country in countries) {
          final items = await readWholeFeed(
            FixtureDataGateway(destinationCountry: country),
          );
          final expected = [
            for (final product in fixtureProducts)
              if (product.offers.any(
                (offer) =>
                    offer.isAffiliate &&
                    offer.isAvailable &&
                    offer.shipsTo.contains(country),
              ))
                product.id,
          ];

          expect(
            items.whereType<AffiliateAd>().map((i) => i.product.id),
            expected,
            reason: country,
          );
          // The Fixtures really do differ by country, so this proves something.
          expect(expected.length, lessThan(fixtureProducts.length));
        }
      },
    );

    test('countries get different feeds', () async {
      final feeds = <String>{};
      for (final country in countries) {
        final items = await readWholeFeed(
          FixtureDataGateway(destinationCountry: country),
        );
        feeds.add(items.map((i) => i.id).join(','));
      }

      expect(feeds.length, greaterThan(1));
    });

    test('still pages through every Feed Item exactly once', () async {
      final items = await readWholeFeed(
        FixtureDataGateway(destinationCountry: 'GB'),
      );
      final ids = items.map((i) => i.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.length, greaterThan(FixtureDataGateway.defaultPageSize));
    });

    test('without a Destination Country every Fixture is served', () async {
      final everything = await readWholeFeed(FixtureDataGateway());
      final gb = await readWholeFeed(
        FixtureDataGateway(destinationCountry: 'GB'),
      );

      expect(gb.length, lessThan(everything.length));
    });

    test('the country code is read in any letter case', () async {
      final lower = await readWholeFeed(
        FixtureDataGateway(destinationCountry: 'gb'),
      );
      final upper = await readWholeFeed(
        FixtureDataGateway(destinationCountry: 'GB'),
      );

      expect(lower.map((i) => i.id), upper.map((i) => i.id));
      expect(lower, isNotEmpty);
    });

    test("shows a Product's first Offer that ships there", () async {
      final gateway = FixtureDataGateway(
        products: [
          product('two-offers', [
            offer('uk', {'GB'}),
            offer('us', {'US'}),
          ]),
        ],
        brandAds: const [],
        destinationCountry: 'US',
      );

      final item = (await readWholeFeed(gateway)).single as AffiliateAd;

      expect(item.offer.id, 'us');
    });

    test('leaves out a Product whose only Offer shipping there '
        'is unavailable or earns nothing', () async {
      final gateway = FixtureDataGateway(
        products: [
          product('sold-out-here', [
            offer('us', {'US'}, isAvailable: false),
            offer('uk', {'GB'}),
          ]),
          product('not-an-ad-here', [
            offer('us-free', {'US'}, isAffiliate: false),
            offer('uk-paid', {'GB'}),
          ]),
          product('ships', [
            offer('us-ok', {'US'}),
          ]),
        ],
        brandAds: const [],
        destinationCountry: 'US',
      );

      final items = await readWholeFeed(gateway);

      expect(items.map((i) => i.id), ['ships']);
    });

    test('a Brand Ad only links Products that can be bought there', () async {
      for (final country in countries) {
        final items = await readWholeFeed(
          FixtureDataGateway(destinationCountry: country),
        );

        for (final ad in items.whereType<BrandAd>()) {
          expect(ad.products, isNotEmpty, reason: '${ad.id} in $country');
          expect(
            ad.products.every((p) => canBeBoughtIn(p, country)),
            isTrue,
            reason: '${ad.id} in $country',
          );
        }
      }
    });

    test('a Brand Ad keeps its words and pictures when a linked Product '
        'is dropped', () async {
      final here = product('here', [
        offer('here', {'US'}),
      ]);
      final elsewhere = product('elsewhere', [
        offer('elsewhere', {'GB'}),
      ]);
      final supplied = BrandAd(
        id: 'ad',
        brand: 'Maker',
        headline: 'As supplied',
        media: const [ImageMedia('https://example.com/ad.jpg')],
        products: [here, elsewhere],
      );
      final gateway = FixtureDataGateway(
        products: [here, elsewhere],
        brandAds: [supplied],
        destinationCountry: 'US',
      );

      final ad = (await readWholeFeed(gateway)).whereType<BrandAd>().single;

      expect(ad.id, supplied.id);
      expect(ad.brand, supplied.brand);
      expect(ad.headline, supplied.headline);
      expect(ad.media, supplied.media);
      expect(ad.products, [here]);
    });

    test('a Brand Ad with no Product to buy there is left out', () async {
      final elsewhere = product('elsewhere', [
        offer('elsewhere', {'GB'}),
      ]);
      final gateway = FixtureDataGateway(
        products: [elsewhere],
        brandAds: [
          BrandAd(
            id: 'ad',
            brand: 'Maker',
            headline: 'Not for here',
            media: const [],
            products: [elsewhere],
          ),
        ],
        destinationCountry: 'US',
      );

      expect(await readWholeFeed(gateway), isEmpty);
    });

    test(
      'category chips only list categories with something to show',
      () async {
        final gateway = FixtureDataGateway(
          products: [
            product('sneaker', [
              offer('a', {'US'}),
            ]),
            Product(
              id: 'bag',
              title: 'Bag',
              description: '',
              brand: 'Brand',
              category: 'bags',
              imageUrls: const [],
              offers: [
                offer('b', {'GB'}),
              ],
            ),
          ],
          brandAds: const [],
          destinationCountry: 'US',
        );

        final filters = await gateway.getSupportedFilters();

        expect(filters.categories.map((c) => c.id), ['sneakers']);
      },
    );

    test('search and category filters stay inside the country', () async {
      final gateway = FixtureDataGateway(destinationCountry: 'LB');

      final sneakers = await readWholeFeed(
        gateway,
        filter: const FeedFilter(category: 'sneakers'),
      );
      final searched = await readWholeFeed(
        gateway,
        filter: const FeedFilter(query: 'runner'),
      );

      for (final item in [...sneakers, ...searched]) {
        if (item is ProductFeedItem) {
          expect(item.offer.shipsTo, contains('LB'), reason: item.id);
        }
      }
      expect(sneakers, isNotEmpty);
    });

    test('a cursor from one country is rejected for another', () async {
      final page = await FixtureDataGateway(destinationCountry: 'US')
          .getFeedPage();
      expect(page.nextCursor, isNotNull);

      await expectLater(
        FixtureDataGateway(destinationCountry: 'GB')
            .getFeedPage(cursor: page.nextCursor),
        throwsArgumentError,
      );
    });
  });
}

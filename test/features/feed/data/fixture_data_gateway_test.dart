import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';

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

        final brands = items.map((i) => i.product.brand).toSet();
        final currencies = items.map((i) => i.offer.price.currencyCode).toSet();
        final shipsTo = items.map((i) => i.offer.shipsTo).toSet();

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
      final ids = items.map((i) => i.product.id).toList();

      expect(ids.toSet(), hasLength(ids.length), reason: 'no repeats');
      expect(items.length, inInclusiveRange(48, 56));
      expect(items.every((item) => item.isAd), isTrue);
    });

    test('never includes Not an Ad Products', () async {
      final items = await readWholeFeed(gateway);

      expect(items.any((item) => !item.offer.isAffiliate), isFalse);
    });

    test('only offers that are available', () async {
      final items = await readWholeFeed(gateway);

      expect(items.every((item) => item.offer.isAvailable), isTrue);
    });

    test('is deterministic across gateway instances', () async {
      final first = await readWholeFeed(FixtureDataGateway());
      final second = await readWholeFeed(FixtureDataGateway());

      expect(
        first.map((i) => i.product.id).toList(),
        second.map((i) => i.product.id).toList(),
      );
    });

    test('asking for the same cursor twice returns the same page', () async {
      final firstPage = await gateway.getFeedPage();
      final cursor = firstPage.nextCursor!;

      final once = await gateway.getFeedPage(cursor: cursor);
      final twice = await gateway.getFeedPage(cursor: cursor);

      expect(
        once.items.map((i) => i.product.id),
        twice.items.map((i) => i.product.id),
      );
      expect(once.nextCursor, twice.nextCursor);
    });

    test('second page continues where the first page stopped', () async {
      final firstPage = await gateway.getFeedPage();
      final secondPage = await gateway.getFeedPage(
        cursor: firstPage.nextCursor,
      );
      final whole = await readWholeFeed(gateway);

      expect(
        [...firstPage.items, ...secondPage.items].map((i) => i.product.id),
        whole
            .take(firstPage.items.length + secondPage.items.length)
            .map((i) => i.product.id),
      );
    });
  });

  group('Category filter', () {
    test('returns only Products in that category, across all pages', () async {
      final items = await readWholeFeed(
        gateway,
        filter: const FeedFilter(category: 'watches'),
      );

      expect(items, isNotEmpty);
      expect(items.every((i) => i.product.category == 'watches'), isTrue);
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
      final someItem = everything[3];

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

      expect(byTitle.map((i) => i.product.id), contains(someItem.product.id));
      expect(
        byBrand.every((i) => i.product.brand == someItem.product.brand),
        isTrue,
      );
      expect(byCategory, isNotEmpty);
      expect(byCategory.every((i) => i.product.category == 'sneakers'), isTrue);
    });

    test('needs every word to match', () async {
      final items = await readWholeFeed(
        gateway,
        filter: const FeedFilter(query: 'running sneakers'),
      );

      expect(items, isNotEmpty);
      expect(
        items.every(
          (i) =>
              i.product.category == 'sneakers' &&
              i.product.attributes['style'] == 'Running',
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
}

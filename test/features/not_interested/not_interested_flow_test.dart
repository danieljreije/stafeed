// Not interested and the ranked For You in the whole app (ticket #10), on
// the Fixtures: a Product marked Not interested leaves the feed at once,
// never comes back (also after a restart), and its Brand and category rank
// lower; the Shopper's interests lead a fresh For You.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/events/data/events_storage.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/events/providers/events_provider.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/widgets/product_card.dart';
import 'package:stafeed/app/features/not_interested/data/not_interested_storage.dart';
import 'package:stafeed/app/features/not_interested/not_interested_action.dart';
import 'package:stafeed/app/features/not_interested/providers/not_interested_provider.dart';
import 'package:stafeed/app/features/product/platform/product_platform.dart';
import 'package:stafeed/app/features/product/product_details_screen.dart';
import 'package:stafeed/app/stafeed_app.dart';

import '../../support/shopper.dart';
import '../product/support/fake_product_platform.dart';

Future<List<AffiliateAd>> firstAffiliateAds() async =>
    (await FixtureDataGateway(
      destinationCountry: 'US',
    ).getFeedPage()).items.whereType<AffiliateAd>().toList();

/// Every Feed Item of For You, as the app's own data gateway serves it.
Future<List<FeedItem>> wholeFeed(ProviderContainer container) async {
  final gateway = container.read(dataGatewayProvider);
  final items = <FeedItem>[];
  FeedCursor? cursor;
  do {
    final page = await gateway.getFeedPage(cursor: cursor);
    items.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null);
  return items;
}

class _FailingNotInterestedStorage extends NotInterestedStorage {
  @override
  Future<void> save(Set<String> productIds) async =>
      throw StateError('disk full');
}

void main() {
  setUp(() async {
    useEmptyDeviceStorage();
    await storeOnboardedShopper();
  });

  Future<void> launchApp(
    WidgetTester tester, {
    List<dynamic> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          externalLinksProvider.overrideWithValue(FakeExternalLinks()),
          shareSheetProvider.overrideWithValue(FakeShareSheet()),
          ...overrides.cast(),
        ],
        child: const StafeedApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card(String title) => find.widgetWithText(ProductCard, title);

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('Not interested on a feed card hides it at once and for good, '
      'also after a restart', (tester) async {
    final [first, second, ...] = await firstAffiliateAds();
    await launchApp(tester);
    expect(card(first.product.title), findsOneWidget);

    await tester.tap(find.byTooltip('Not interested'));
    await tester.pumpAndSettle();

    expect(card(first.product.title), findsNothing);
    expect(card(second.product.title), findsOneWidget);
    expect(find.text(notInterestedMessage), findsOneWidget);

    final events = await EventsStorage().load();
    final marked = events.where((e) => e.type == EventType.notInterested);
    expect(marked, hasLength(1));
    expect(marked.single.productId, first.product.id);
    expect(marked.single.feedItemId, first.id);
    expect(marked.single.isAd, isTrue);
    // Acting on it is never a Skip.
    expect(
      events.where(
        (e) =>
            (e.type == EventType.skip || e.type == EventType.fastSkip) &&
            e.productId == first.product.id,
      ),
      isEmpty,
    );

    // A restart, then a search for exactly that Product.
    await launchApp(tester);
    expect(card(first.product.title), findsNothing);
    await search(tester, first.product.title);
    expect(card(first.product.title), findsNothing);
  });

  testWidgets('Not interested in details goes back to a feed without it', (
    tester,
  ) async {
    final [first, second, ...] = await firstAffiliateAds();
    await launchApp(tester);

    await tester.tap(find.text(first.product.title));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byTooltip('Not interested'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(card(first.product.title), findsNothing);
    expect(card(second.product.title), findsOneWidget);
    expect(find.text(notInterestedMessage), findsOneWidget);
    expect(await NotInterestedStorage().load(), {first.product.id});
  });

  testWidgets('when the device will not keep it, it is still hidden and the '
      'Shopper is told', (tester) async {
    final [first, ...] = await firstAffiliateAds();
    await launchApp(
      tester,
      overrides: [
        notInterestedStorageProvider.overrideWithValue(
          _FailingNotInterestedStorage(),
        ),
      ],
    );

    await tester.tap(find.byTooltip('Not interested'));
    await tester.pumpAndSettle();

    expect(card(first.product.title), findsNothing);
    expect(find.text(notInterestedWriteFailedMessage), findsOneWidget);
  });

  testWidgets("a fresh For You opens on the Shopper's interests", (
    tester,
  ) async {
    await storeOnboardedShopper(interests: {'watches'});
    await launchApp(tester);

    final shown = tester.widget<ProductCard>(find.byType(ProductCard).first);
    expect(shown.item.product.category, 'watches');
  });

  test('Not interested ranks the same Brand and category lower in For You, '
      'from the Events and the stored mark', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = await wholeFeed(container);
    final rejected = (before.first as AffiliateAd).product;
    final similar = before.whereType<AffiliateAd>().firstWhere(
      (ad) =>
          ad.product.id != rejected.id &&
          ad.product.brand == rejected.brand &&
          ad.product.category == rejected.category,
    );

    await container
        .read(eventsLogProvider.notifier)
        .record(NewEvent(EventType.notInterested, productId: rejected.id));
    await container.read(notInterestedProvider.notifier).mark(rejected.id);

    final after = await wholeFeed(container);
    int place(List<FeedItem> items) =>
        items.indexWhere((item) => item.id == similar.id);

    expect(after.map((i) => i.id), isNot(contains(rejected.id)));
    expect(place(after), greaterThan(place(before) + 5));
  });
}

// Saved Products in the whole app (ticket #8), on the Fixtures: saved from
// the feed or from details, the same everywhere, kept across a restart and
// shown even when the feed doesn't hold them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/widgets/product_card.dart';
import 'package:stafeed/app/features/product/platform/product_platform.dart';
import 'package:stafeed/app/features/product/product_details_screen.dart';
import 'package:stafeed/app/features/saved/data/saved_products_storage.dart';
import 'package:stafeed/app/features/saved/models/saved_product.dart';
import 'package:stafeed/app/features/saved/saved_screen.dart';
import 'package:stafeed/app/features/shopper/models/destination_country.dart';
import 'package:stafeed/app/stafeed_app.dart';

import '../../support/shopper.dart';
import '../product/support/fake_product_platform.dart';

Future<AffiliateAd> firstAffiliateAd() async => (await FixtureDataGateway(
  destinationCountry: 'US',
).getFeedPage()).items.whereType<AffiliateAd>().first;

void main() {
  setUp(() async {
    useEmptyDeviceStorage();
    await storeOnboardedShopper();
  });

  /// Starts the app the way a launch does: nothing kept in memory, only
  /// what is in the device's storage.
  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          externalLinksProvider.overrideWithValue(FakeExternalLinks()),
          shareSheetProvider.overrideWithValue(FakeShareSheet()),
        ],
        child: const StafeedApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  Finder savedRow(String title) => find.descendant(
    of: find.byType(SavedScreen),
    matching: find.widgetWithText(ListTile, title),
  );

  testWidgets('saved from details: the feed card and Saved both show it, and '
      'unsaving there clears both', (tester) async {
    final first = await firstAffiliateAd();
    await launchApp(tester);

    await tester.tap(find.text(first.product.title));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from Saved'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ProductCard, 'Saved'), findsOneWidget);

    await openTab(tester, 'Saved');
    expect(savedRow(first.product.title), findsOneWidget);

    // Back into details from Saved, and unsave there.
    await tester.tap(savedRow(first.product.title));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Sold by ${first.offer.merchant}'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from Saved'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(savedRow(first.product.title), findsNothing);
    await openTab(tester, 'Feed');
    expect(find.widgetWithText(ProductCard, 'Save'), findsOneWidget);
  });

  testWidgets('saved in the feed: kept after a restart, and shown while the '
      'feed holds something else', (tester) async {
    final first = await firstAffiliateAd();
    await launchApp(tester);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    // A restart, then a feed that doesn't hold the Saved Product.
    await launchApp(tester);
    expect(find.widgetWithText(ProductCard, 'Saved'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzzz no such thing');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await openTab(tester, 'Saved');
    expect(savedRow(first.product.title), findsOneWidget);
  });

  testWidgets('a Saved Product that no longer ships to the Shopper is '
      'marked', (tester) async {
    final usOnly = fixtureProducts.firstWhere(
      (product) =>
          product.offers.any(
            (offer) =>
                offer.isAffiliate &&
                offer.isAvailable &&
                offer.shipsTo.contains('US'),
          ) &&
          product.offers.every((offer) => !offer.shipsTo.contains('LB')),
    );
    final offer = usOnly.offers.firstWhere(
      (offer) => offer.shipsTo.contains('US'),
    );
    // Saved while the Shopper was in the US...
    await SavedProductsStorage().save([
      SavedProduct.snapshot(usOnly, offer, savedAt: DateTime.utc(2026, 11)),
    ]);
    // ...who now has things delivered to Lebanon.
    await storeOnboardedShopper(country: DestinationCountry.lebanon);

    await launchApp(tester);
    await openTab(tester, 'Saved');

    expect(
      find.descendant(
        of: savedRow(usOnly.title),
        matching: find.text('Not available any more'),
      ),
      findsOneWidget,
    );
  });
}

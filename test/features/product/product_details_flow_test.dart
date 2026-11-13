// Opening Product details from the feed and coming back (ticket #7). The
// whole app from its root, on the Fixtures, for a Shopper in the US.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/product/platform/product_platform.dart';
import 'package:stafeed/app/features/product/product_details_screen.dart';
import 'package:stafeed/app/stafeed_app.dart';

import '../../support/shopper.dart';
import 'support/fake_product_platform.dart';

final feedPages = find.byWidgetPredicate(
  (widget) => widget is PageView && widget.scrollDirection == Axis.vertical,
);

Future<List<FeedItem>> fixtureFeed() async =>
    (await FixtureDataGateway(destinationCountry: 'US').getFeedPage()).items;

void main() {
  setUp(() async {
    useEmptyDeviceStorage();
    await storeOnboardedShopper();
  });

  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalLinksProvider.overrideWithValue(FakeExternalLinks()),
          shareSheetProvider.overrideWithValue(FakeShareSheet()),
        ],
        child: const StafeedApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeUp(WidgetTester tester, {int times = 1}) async {
    for (var i = 0; i < times; i++) {
      await tester.drag(feedPages, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  testWidgets("tapping an Affiliate Ad opens that Product's details", (
    tester,
  ) async {
    final first = (await fixtureFeed()).first as AffiliateAd;
    await launchApp(tester);

    await tester.tap(find.text(first.product.title));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Sold by ${first.offer.merchant}'), findsOneWidget);
    expect(find.text(first.product.description), findsOneWidget);
  });

  testWidgets('the Save button still saves instead of opening details', (
    tester,
  ) async {
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text('Saved'), findsWidgets);
  });

  testWidgets('back from details lands on the same Feed Item', (tester) async {
    final feed = await fixtureFeed();
    final third = feed[2] as AffiliateAd;
    await launchApp(tester);
    await swipeUp(tester, times: 2);
    expect(find.text(third.product.title), findsOneWidget);

    await tester.tap(find.text(third.product.title));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.text(third.product.title), findsOneWidget);
    expect(find.text(feed.first.products.single.title), findsNothing);
  });

  testWidgets("a Brand Ad's chip opens that Product's details", (tester) async {
    final feed = await fixtureFeed();
    final index = feed.indexWhere((item) => item is BrandAd);
    final ad = feed[index] as BrandAd;
    final linked = ad.products.first;
    await launchApp(tester);
    await swipeUp(tester, times: index);

    await tester.tap(find.widgetWithText(ActionChip, linked.title));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text(linked.description), findsOneWidget);
  });
}

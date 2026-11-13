// The whole app from its root (ticket #6): onboarding on first launch only,
// the four tabs keeping their place, and a feed that only holds what ships
// to the Shopper's Destination Country. Runs on the Fixtures.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/app_name.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/shopper/data/shopper_config_storage.dart';
import 'package:stafeed/app/features/shopper/models/destination_country.dart';
import 'package:stafeed/app/features/shopper/models/shopper_config.dart';
import 'package:stafeed/app/stafeed_app.dart';

import '../support/shopper.dart';

const welcomeLine = "Welcome to Stafeed. It's all ads. We're not hiding it.";

/// Starts the app the way a launch does: nothing kept in memory, only what
/// is in the device's storage.
Future<void> launchApp(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: StafeedApp()));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, label));
  await tester.pumpAndSettle();
}

/// The feed itself. (A Feed Item with several pictures has a sideways
/// PageView of its own.)
final feedPages = find.byWidgetPredicate(
  (widget) => widget is PageView && widget.scrollDirection == Axis.vertical,
);

/// Swipes to the next Feed Item.
Future<void> swipeUp(WidgetTester tester) async {
  await tester.drag(feedPages, const Offset(0, -400));
  await tester.pumpAndSettle();
}

/// Types into the feed's search box and waits out its typing delay.
Future<void> searchFeed(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The Affiliate Ads the Fixtures hold for a Shopper in [country], in feed
/// order.
Future<List<AffiliateAd>> firstAffiliateAds(DestinationCountry country) async {
  final page = await FixtureDataGateway(destinationCountry: country.code)
      .getFeedPage();
  return page.items.whereType<AffiliateAd>().toList();
}

/// A Fixture that can be bought in [soldIn] but has no Offer shipping to
/// [notSoldIn].
Product fixtureSoldOnlyIn(
  DestinationCountry soldIn, {
  required DestinationCountry notSoldIn,
}) => fixtureProducts.firstWhere(
  (product) =>
      product.offers.any(
        (offer) =>
            offer.isAffiliate &&
            offer.isAvailable &&
            offer.shipsTo.contains(soldIn.code),
      ) &&
      product.offers.every((offer) => !offer.shipsTo.contains(notSoldIn.code)),
);

void main() {
  setUp(useEmptyDeviceStorage);

  group('Onboarding', () {
    testWidgets('first launch shows the welcome line, and no tabs yet', (
      tester,
    ) async {
      await launchApp(tester);

      expect(find.text(welcomeLine), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(feedPages, findsNothing);
    });

    testWidgets('the welcome line says the app name defined in one place', (
      tester,
    ) async {
      await launchApp(tester);

      expect(appName, 'Stafeed');
      expect(
        find.text("Welcome to $appName. It's all ads. We're not hiding it."),
        findsOneWidget,
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        appName,
      );
    });

    testWidgets('offers the four Destination Countries, and needs one picked', (
      tester,
    ) async {
      await launchApp(tester);
      await tapText(tester, "Let's go");

      for (final country in [
        'United States',
        'United Kingdom',
        'United Arab Emirates',
        'Lebanon',
      ]) {
        expect(find.text(country), findsOneWidget);
      }

      // Nothing picked yet: Continue does nothing.
      await tapText(tester, 'Continue');
      expect(find.text('United States'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets(
      'country, currency and interests are kept, then the Feed opens',
      (tester) async {
        final ads = await firstAffiliateAds(DestinationCountry.unitedKingdom);

        await launchApp(tester);
        await tapText(tester, "Let's go");
        await tapText(tester, 'United Kingdom');
        // The country's own currency is suggested; the Shopper picks another.
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'GBP'))
              .selected,
          isTrue,
        );
        await tapText(tester, 'EUR');
        await tapText(tester, 'Continue');
        await tapText(tester, 'Sneakers');
        await tapText(tester, 'Watches');
        await tapText(tester, 'Show me the ads');

        // Straight into the Feed, with the tabs.
        expect(find.text(welcomeLine), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text(ads.first.product.title), findsOneWidget);

        expect(
          await ShopperConfigStorage().load(),
          const ShopperConfig(
            destinationCountry: DestinationCountry.unitedKingdom,
            currencyCode: 'EUR',
            interests: {'sneakers', 'watches'},
          ),
        );
      },
    );

    testWidgets('interests can be skipped', (tester) async {
      await launchApp(tester);
      await tapText(tester, "Let's go");
      await tapText(tester, 'Lebanon');
      await tapText(tester, 'Continue');
      await tapText(tester, 'Sneakers');
      await tapText(tester, 'Skip');

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        await ShopperConfigStorage().load(),
        const ShopperConfig(
          destinationCountry: DestinationCountry.lebanon,
          currencyCode: 'USD',
        ),
      );
    });

    testWidgets('is shown once: the next launch opens the Feed', (
      tester,
    ) async {
      final ads = await firstAffiliateAds(DestinationCountry.unitedStates);

      await launchApp(tester);
      await tapText(tester, "Let's go");
      await tapText(tester, 'United States');
      await tapText(tester, 'Continue');
      await tapText(tester, 'Skip');
      expect(find.text(ads.first.product.title), findsOneWidget);

      await launchApp(tester);

      expect(find.text(welcomeLine), findsNothing);
      expect(find.text("Let's go"), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text(ads.first.product.title), findsOneWidget);
    });

    testWidgets('a launch that never finished onboarding shows it again', (
      tester,
    ) async {
      await launchApp(tester);
      await tapText(tester, "Let's go");
      await tapText(tester, 'United States');

      await launchApp(tester);

      expect(find.text(welcomeLine), findsOneWidget);
    });
  });

  group('Tabs', () {
    setUp(storeOnboardedShopper);

    testWidgets('are Feed, Search, Saved and Profile, opening on the Feed', (
      tester,
    ) async {
      await launchApp(tester);

      for (final tab in ['Feed', 'Search', 'Saved', 'Profile']) {
        expect(find.widgetWithText(NavigationDestination, tab), findsOneWidget);
      }
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(feedPages, findsOneWidget);
    });

    testWidgets('the old Home landing screen is gone', (tester) async {
      await launchApp(tester);

      expect(find.text('Start Exploring'), findsNothing);
      expect(find.text('Discover'), findsNothing);
    });

    testWidgets('the Feed keeps its place while the Shopper is on other tabs', (
      tester,
    ) async {
      final ads = await firstAffiliateAds(DestinationCountry.unitedStates);
      // The feed opens on Affiliate Ads, so the third Feed Item is ads[2].
      final page = await FixtureDataGateway(destinationCountry: 'US')
          .getFeedPage();
      expect(page.items[2], isA<AffiliateAd>());

      await launchApp(tester);
      await swipeUp(tester);
      await swipeUp(tester);
      expect(find.text(ads[2].product.title), findsOneWidget);

      for (final tab in ['Search', 'Saved', 'Profile']) {
        await openTab(tester, tab);
        expect(find.text(ads[2].product.title), findsNothing);
      }
      await openTab(tester, 'Feed');

      expect(find.text(ads[2].product.title), findsOneWidget);
      expect(find.text(ads[0].product.title), findsNothing);
    });

    testWidgets('Search keeps what was typed while the Shopper is elsewhere', (
      tester,
    ) async {
      await launchApp(tester);
      await openTab(tester, 'Search');
      await tester.enterText(find.byType(TextField), 'white sneakers');
      await tester.pumpAndSettle();

      await openTab(tester, 'Feed');
      expect(find.text('white sneakers'), findsNothing);
      await openTab(tester, 'Profile');
      await openTab(tester, 'Search');

      expect(find.text('white sneakers'), findsOneWidget);
    });

    testWidgets('Saved keeps its scroll position', (tester) async {
      await launchApp(tester);
      // Save enough Products to fill more than one screen of the list.
      // (A Brand Ad has no Save button; it is swiped past.)
      var saved = 0;
      while (saved < 10) {
        final save = find.byIcon(Icons.favorite_border);
        if (save.evaluate().isNotEmpty) {
          await tester.tap(save);
          await tester.pumpAndSettle();
          saved++;
        }
        await swipeUp(tester);
      }

      await openTab(tester, 'Saved');
      expect(find.byType(ListTile), findsWidgets);
      double listOffset() => tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      expect(listOffset(), 0);

      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      final scrolledTo = listOffset();
      expect(scrolledTo, greaterThan(0));

      await openTab(tester, 'Feed');
      await openTab(tester, 'Profile');
      await openTab(tester, 'Saved');

      expect(listOffset(), scrolledTo);
    });

    testWidgets('a Product saved in the Feed shows in Saved', (tester) async {
      final ads = await firstAffiliateAds(DestinationCountry.unitedStates);

      await launchApp(tester);
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      await openTab(tester, 'Saved');

      expect(
        find.widgetWithText(ListTile, ads.first.product.title),
        findsOneWidget,
      );
    });

    testWidgets('Search sends a category to the Feed', (tester) async {
      final watches = fixtureProducts.firstWhere(
        (product) =>
            product.category == 'watches' &&
            product.offers.any(
              (offer) =>
                  offer.isAffiliate &&
                  offer.isAvailable &&
                  offer.shipsTo.contains('US'),
            ),
      );

      await launchApp(tester);
      await openTab(tester, 'Search');
      await tester.tap(find.widgetWithText(ListTile, 'Watches'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text(watches.title), findsOneWidget);
    });

    testWidgets('Profile shows what the Shopper chose', (tester) async {
      await storeOnboardedShopper(
        country: DestinationCountry.unitedArabEmirates,
        interests: {'bags'},
      );

      await launchApp(tester);
      await openTab(tester, 'Profile');

      expect(find.text('United Arab Emirates'), findsOneWidget);
      expect(find.text('AED'), findsOneWidget);
      expect(find.text('Bags'), findsOneWidget);
    });
  });

  group('Destination Country', () {
    testWidgets('the Feed opens on the first Fixture that ships there', (
      tester,
    ) async {
      for (final country in DestinationCountry.values) {
        useEmptyDeviceStorage();
        await storeOnboardedShopper(country: country);
        final ads = await firstAffiliateAds(country);

        await launchApp(tester);

        expect(
          find.text(ads.first.product.title),
          findsOneWidget,
          reason: country.label,
        );
        expect(
          ads.first.offer.shipsTo,
          contains(country.code),
          reason: country.label,
        );
      }
    });

    testWidgets("a Product that doesn't ship there can't be found", (
      tester,
    ) async {
      final usOnly = fixtureSoldOnlyIn(
        DestinationCountry.unitedStates,
        notSoldIn: DestinationCountry.lebanon,
      );

      // A Shopper in the United States finds it...
      await storeOnboardedShopper(country: DestinationCountry.unitedStates);
      await launchApp(tester);
      await searchFeed(tester, usOnly.title);
      expect(find.text(usOnly.title), findsWidgets);
      expect(find.text('No matches'), findsNothing);

      // ...a Shopper in Lebanon doesn't.
      useEmptyDeviceStorage();
      await storeOnboardedShopper(country: DestinationCountry.lebanon);
      await launchApp(tester);
      await searchFeed(tester, usOnly.title);
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('every Feed Item swiped past ships there', (tester) async {
      const country = DestinationCountry.unitedKingdom;
      final elsewhere = {
        for (final product in fixtureProducts)
          if (product.offers.every(
            (offer) => !offer.shipsTo.contains(country.code),
          ))
            product.title,
      };
      expect(elsewhere, isNotEmpty);

      await storeOnboardedShopper(country: country);
      await launchApp(tester);

      // Two pages' worth of Feed Items.
      for (var i = 0; i < 2 * FixtureDataGateway.defaultPageSize; i++) {
        for (final title in elsewhere) {
          expect(find.text(title), findsNothing, reason: 'Feed Item $i');
        }
        await swipeUp(tester);
      }
    });
  });
}

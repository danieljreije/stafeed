// Web end-to-end test (#36): starts the whole app from main() on the Fixture
// data gateway and uses it like a Shopper would, in a real browser.
//
// Run locally (needs chromedriver on port 4444, see PROJECT_STATUS.md):
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/shopper_journey_test.dart -d web-server \
//     --browser-dimension=430x932 --headless
//
// It never uses pumpAndSettle: product photos load from the network and show
// a spinner meanwhile, so "settled" depends on the network. Instead each step
// waits for the exact thing the Shopper would look for.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/widgets/product_card.dart';
import 'package:stafeed/main.dart' as app;

/// Pumps frames until [condition] holds, or fails with [what] after [timeout].
Future<void> waitFor(
  WidgetTester tester,
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  final onScreen = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .join(' | ');
  final typed = find
      .byType(EditableText)
      .evaluate()
      .map((element) => '"${(element.widget as EditableText).controller.text}"')
      .join(', ');
  fail(
    'Timed out after ${timeout.inSeconds}s waiting for: $what\n'
    'Text on screen: $onScreen\n'
    'Typed in text fields: $typed',
  );
}

Future<void> waitForText(WidgetTester tester, String text) => waitFor(
  tester,
  'text "$text"',
  () => find.text(text).evaluate().isNotEmpty,
);

/// Waits until [text] is fully on screen and has stopped moving, then taps
/// it. On Android a new page slides in, so a button can already exist while
/// it is still partly off screen, and a tap then misses it.
Future<void> tapText(WidgetTester tester, String text) async {
  Rect? previous;
  await waitFor(tester, 'text "$text" to be fully on screen and still', () {
    final found = find.text(text);
    if (found.evaluate().length != 1) return false;
    final rect = tester.getRect(found);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final still = rect == previous;
    previous = rect;
    return still &&
        rect.left >= 0 &&
        rect.top >= 0 &&
        rect.right <= screen.width &&
        rect.bottom <= screen.height;
  });
  await tester.tap(find.text(text));
}

/// The Feed Items this journey meets are all Affiliate Ads: the Fixtures'
/// Brand Ads come later in the feed. Reading any other kind through this
/// list fails the test.
List<AffiliateAd> affiliateAds(List<FeedItem> items) =>
    items.cast<AffiliateAd>();

/// The card currently filling the feed shows [item]'s title and nothing else.
Future<void> waitForCard(WidgetTester tester, AffiliateAd item) => waitFor(
  tester,
  'the "${item.product.title}" card to be the only card on screen',
  () =>
      find.text(item.product.title).evaluate().length == 1 &&
      find.byIcon(Icons.favorite_border).evaluate().length +
              find.byIcon(Icons.favorite).evaluate().length ==
          1,
);

/// Taps one of the four tabs at the bottom of the app.
Future<void> openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(NavigationDestination, label);
  await waitFor(tester, 'the "$label" tab', () => tab.evaluate().length == 1);
  await tester.tap(tab);
}

/// The feed itself. (A Feed Item with several pictures has a sideways
/// PageView of its own.)
final feedPages = find.byWidgetPredicate(
  (widget) => widget is PageView && widget.scrollDirection == Axis.vertical,
);

/// A real finger swipe: drags most of the card's height over 300ms.
Future<void> swipeUp(WidgetTester tester) async {
  final feed = feedPages;
  final card = tester.getRect(feed);
  expect(
    card.height,
    greaterThan(400),
    reason:
        'the feed is too short to swipe: run with '
        '--browser-dimension=430x932, or the feed layout has regressed',
  );
  // Start low on the card, clear of the search box and chips on top.
  await tester.timedDragFrom(
    Offset(card.center.dx, card.top + card.height * 0.8),
    Offset(0, -card.height * 0.6),
    const Duration(milliseconds: 300),
  );
}

/// Set only by a manual run of the Nightly Android check (#39) with
/// force_failure, to prove that a failure opens an issue. Never set otherwise.
const forceFailure = bool.fromEnvironment('STAFEED_FORCE_E2E_FAILURE');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new Shopper is onboarded, then swipes, saves, switches tabs, '
      'searches, filters and recovers from an empty search', (tester) async {
    if (forceFailure) {
      fail(
        'Deliberate failure (STAFEED_FORCE_E2E_FAILURE): nothing is broken.',
      );
    }

    // What the Fixtures say a Shopper in the United States should see, asked
    // from the same gateway the app uses so the test follows Fixture edits.
    final gateway = FixtureDataGateway(destinationCountry: 'US');
    final forYou = affiliateAds((await gateway.getFeedPage()).items);
    const query = 'Kestrel';
    final searched = affiliateAds(
      (await gateway.getFeedPage(filter: const FeedFilter(query: query))).items,
    );
    final watches = affiliateAds(
      (await gateway.getFeedPage(filter: const FeedFilter(category: 'watches')))
          .items,
    );
    expect(forYou.length, greaterThanOrEqualTo(3));
    expect(searched, isNotEmpty);
    expect(searched.first.product.id, isNot(forYou.first.product.id));
    expect(watches, isNotEmpty);
    expect(watches.first.product.id, isNot(forYou.first.product.id));

    // A fresh Shopper: nothing saved, and no onboarding done, in an earlier
    // run in this browser.
    await SharedPreferencesAsync().clear();

    // Start the real app from its root. A first launch opens on onboarding,
    // with no tabs yet.
    app.main();
    await waitForText(
      tester,
      "Welcome to Stafeed. It's all ads. We're not hiding it.",
    );
    expect(find.byType(NavigationBar), findsNothing);

    // Destination Country (with its usual currency), then skip interests.
    await tapText(tester, "Let's go");
    await tapText(tester, 'United States');
    await waitFor(
      tester,
      'USD to be suggested as the currency',
      () => find
          .widgetWithText(ChoiceChip, 'USD')
          .evaluate()
          .any((element) => (element.widget as ChoiceChip).selected),
    );
    await tapText(tester, 'Continue');
    await tapText(tester, 'Skip');

    // The app opens straight into For You, on the first Fixture that ships
    // to the United States, labelled as sample data.
    await waitForCard(tester, forYou[0]);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final item in forYou.take(3)) {
      expect(item.offer.shipsTo, contains('US'));
    }
    expect(find.text('Sample data · not real products'), findsOneWidget);
    expect(find.text(forYou[0].offer.price.format()), findsOneWidget);
    // Every Ad says it is one.
    expect(find.text('AD'), findsOneWidget);
    expect(find.text('Stafeed may earn a commission'), findsOneWidget);

    // Swipe through For You.
    await swipeUp(tester);
    await waitForCard(tester, forYou[1]);
    await swipeUp(tester);
    await waitForCard(tester, forYou[2]);

    // Save the Product on screen.
    final saved = forYou[2].product;
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await waitFor(
      tester,
      'the card to show Saved',
      () =>
          find.widgetWithText(ProductCard, 'Saved').evaluate().isNotEmpty &&
          find.byIcon(Icons.favorite).evaluate().isNotEmpty,
    );

    // Find it in the Saved tab.
    await openTab(tester, 'Saved');
    await waitFor(
      tester,
      '"${saved.title}" in the Saved list',
      () => find.widgetWithText(ListTile, saved.title).evaluate().isNotEmpty,
    );
    expect(find.byType(ListTile), findsOneWidget);

    // Back on the Feed tab, For You is where the Shopper left it.
    await openTab(tester, 'Feed');
    await waitForCard(tester, forYou[2]);
    expect(find.widgetWithText(ProductCard, 'Saved'), findsOneWidget);

    // Search.
    await tester.enterText(find.byType(TextField), query);
    await waitForCard(tester, searched.first);

    // A search with no matches shows the empty state, with the search box,
    // chips and sample-data marker still there.
    // (Typing comes before any chip tap on purpose: in a browser the test's
    // simulated typing doesn't land after the app has cleared the box
    // itself. A real keyboard is not affected.)
    await tester.enterText(find.byType(TextField), 'zzz no such thing');
    await waitForText(tester, 'No matches');
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Watches'), findsOneWidget);
    expect(find.text('Sample data · not real products'), findsOneWidget);

    // The controls still work from the empty state: a category filter
    // replaces the search...
    await tester.tap(find.widgetWithText(ChoiceChip, 'Watches'));
    await waitForCard(tester, watches.first);
    expect(find.text('No matches'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    // ...and All brings For You back.
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await waitForCard(tester, forYou[0]);
  });
}

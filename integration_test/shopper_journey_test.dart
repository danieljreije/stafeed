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

/// The card currently filling the feed shows [item]'s title and nothing else.
Future<void> waitForCard(WidgetTester tester, FeedItem item) => waitFor(
  tester,
  'the "${item.product.title}" card to be the only card on screen',
  () =>
      find.text(item.product.title).evaluate().length == 1 &&
      find.byIcon(Icons.favorite_border).evaluate().length +
              find.byIcon(Icons.favorite).evaluate().length ==
          1,
);

/// Stands in for the browser's Back button: the feed has no on-screen back
/// control today.
void goBack(WidgetTester tester) {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
}

/// A real finger swipe: drags most of the card's height over 300ms.
Future<void> swipeUp(WidgetTester tester) async {
  final feed = find.byType(PageView);
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a Shopper swipes, saves, searches, filters and recovers from an '
      'empty search', (tester) async {
    // What the Fixtures say the Shopper should see, asked from the same
    // gateway the app uses so the test follows Fixture edits.
    final gateway = FixtureDataGateway();
    final forYou = (await gateway.getFeedPage()).items;
    const query = 'Kestrel';
    final searched = (await gateway.getFeedPage(
      filter: const FeedFilter(query: query),
    )).items;
    final watches = (await gateway.getFeedPage(
      filter: const FeedFilter(category: 'watches'),
    )).items;
    expect(forYou.length, greaterThanOrEqualTo(3));
    expect(searched, isNotEmpty);
    expect(searched.first.product.id, isNot(forYou.first.product.id));
    expect(watches, isNotEmpty);
    expect(watches.first.product.id, isNot(forYou.first.product.id));

    // A fresh Shopper: nothing saved from an earlier run in this browser.
    await SharedPreferencesAsync().clear();

    // Start the real app from its root.
    app.main();
    await waitForText(tester, 'Start Exploring');
    expect(find.text('Discover'), findsOneWidget);

    // For You opens on the first Fixture, labelled as sample data.
    await tester.tap(find.text('Start Exploring'));
    await waitForCard(tester, forYou[0]);
    expect(find.text('Sample data · not real products'), findsOneWidget);
    expect(find.text(forYou[0].offer.price.format()), findsOneWidget);

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
          find.text('Saved').evaluate().isNotEmpty &&
          find.byIcon(Icons.favorite).evaluate().isNotEmpty,
    );

    // Find it in Saved.
    goBack(tester);
    await waitForText(tester, 'Saved Products');
    await tester.tap(find.text('Saved Products'));
    await waitFor(
      tester,
      '"${saved.title}" in the Saved list',
      () => find.widgetWithText(ListTile, saved.title).evaluate().isNotEmpty,
    );
    expect(find.byType(ListTile), findsOneWidget);

    // Back to For You, which opens at the top of the feed again.
    goBack(tester);
    await waitForText(tester, 'Start Exploring');
    await tester.tap(find.text('Start Exploring'));
    await waitForCard(tester, forYou[0]);

    // Search.
    await tester.enterText(find.byType(TextField), query);
    await waitForCard(tester, searched.first);

    // A search with no matches shows the empty state, with the search box,
    // chips and sample-data marker still there.
    // (Typing comes before any chip tap on purpose: in a browser the test's
    // simulated typing doesn't land after the app has cleared the box
    // itself. A real keyboard is not affected.)
    await tester.enterText(find.byType(TextField), 'zzz no such thing');
    await waitForText(tester, 'No products available.');
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Watches'), findsOneWidget);
    expect(find.text('Sample data · not real products'), findsOneWidget);

    // The controls still work from the empty state: a category filter
    // replaces the search...
    await tester.tap(find.widgetWithText(ChoiceChip, 'Watches'));
    await waitForCard(tester, watches.first);
    expect(find.text('No products available.'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );

    // ...and All brings For You back.
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await waitForCard(tester, forYou[0]);
  });
}

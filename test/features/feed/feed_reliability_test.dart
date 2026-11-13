// How the feed screen behaves while pages load, fail, run out or are
// refreshed (ticket #3). The data gateway is scripted, so each test decides
// when and in which order the answers arrive.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/models/supported_filters.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';

import 'support/scripted_data_gateway.dart';

/// Opens the feed on a scripted gateway. The first page is still on its way.
Future<ScriptedDataGateway> pumpFeed(WidgetTester tester) async {
  final gateway = ScriptedDataGateway(
    categories: const [ProductCategory(id: 'shoes', label: 'Shoes')],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataGatewayProvider.overrideWithValue(gateway)],
      child: const MaterialApp(home: FeedScreen()),
    ),
  );
  await tester.pump();

  return gateway;
}

/// Lets answers reach the screen and animations move on. Spinners never
/// stop, so the tests step the clock instead of waiting for stillness.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Swipes to the next Feed Item.
Future<void> swipeUp(WidgetTester tester) async {
  await tester.drag(find.byType(PageView), const Offset(0, -400));
  await settle(tester);
}

/// Pulls the feed down from the top, far enough to refresh.
Future<void> pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(0, 300), 1000);
  await settle(tester);
}

/// Search box, chips and sample-data marker are all on screen.
void expectControls() {
  expect(find.byType(TextField), findsOneWidget);
  expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
  expect(find.widgetWithText(ChoiceChip, 'Shoes'), findsOneWidget);
  expect(find.textContaining('Sample data'), findsOneWidget);
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('states under the controls', () {
    testWidgets('loading keeps the controls', (tester) async {
      await pumpFeed(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expectControls();
    });

    testWidgets('empty says No matches and offers to clear the filters', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a']));
      await settle(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Shoes'));
      await settle(tester);
      expect(gateway.requests.last.filter.category, 'shoes');
      gateway.requests.last.succeed([]);
      await settle(tester);

      expect(find.text('No matches'), findsOneWidget);
      expectControls();
      // Below the controls, not behind them.
      expect(
        tester.getTopLeft(find.text('No matches')).dy,
        greaterThan(tester.getBottomLeft(find.textContaining('Sample')).dy),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Clear filters'));
      await settle(tester);

      expect(gateway.requests, hasLength(3));
      expect(gateway.requests.last.filter.category, isNull);
      expect(gateway.requests.last.filter.query, isEmpty);

      gateway.requests.last.succeed(feedItems(['a']));
      await settle(tester);

      expect(find.text('Product a'), findsOneWidget);
      expect(find.text('No matches'), findsNothing);
    });

    testWidgets('a failed first page shows Retry, and Retry works once', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.fail();
      await settle(tester);

      final retry = find.widgetWithText(FilledButton, 'Retry');
      expect(find.text("Couldn't load the feed."), findsOneWidget);
      expect(retry, findsOneWidget);
      expectControls();
      expect(
        tester.getTopLeft(find.text("Couldn't load the feed.")).dy,
        greaterThan(tester.getBottomLeft(find.textContaining('Sample')).dy),
      );

      await tester.tap(retry);
      await tester.pump();

      // One new request; the button is gone, so it can't be tapped twice.
      expect(gateway.requests, hasLength(2));
      expect(retry, findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expectControls();

      gateway.requests.last.succeed(feedItems(['a']));
      await settle(tester);

      expect(find.text('Product a'), findsOneWidget);
      expect(find.text("Couldn't load the feed."), findsNothing);
    });

    testWidgets('a first page that answers after the filter changed is not '
        'shown', (tester) async {
      final gateway = await pumpFeed(tester);
      final forYou = gateway.requests.last;

      await tester.tap(find.widgetWithText(ChoiceChip, 'Shoes'));
      await settle(tester);
      final shoes = gateway.requests.last;

      forYou.succeed(feedItems(['a']));
      await settle(tester);

      expect(find.text('Product a'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      shoes.succeed(feedItems(['s1']));
      await settle(tester);

      expect(find.text('Product s1'), findsOneWidget);
    });
  });

  group('load more', () {
    testWidgets('swiping loads the next page once, however far it goes', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(
        feedItems(['a', 'b', 'c', 'd']),
        next: 'page-2',
      );
      await settle(tester);

      await swipeUp(tester);
      await swipeUp(tester);
      await swipeUp(tester);

      expect(find.text('Product d'), findsOneWidget);
      expect(gateway.requests, hasLength(2));
      expect(gateway.requests.last.cursor, const FeedCursor('page-2'));
      // The spinner for the page on its way.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gateway.requests.last.succeed(feedItems(['d', 'e']));
      await settle(tester);
      await swipeUp(tester);

      // No duplicate of d: the next card is e.
      expect(find.text('Product e'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure keeps the Feed Items and shows an inline Retry '
        'that works once', (tester) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a', 'b']), next: 'page-2');
      await settle(tester);

      await swipeUp(tester);
      expect(gateway.requests, hasLength(2));
      gateway.requests.last.fail();
      await settle(tester);

      final retry = find.widgetWithText(FilledButton, 'Retry loading');
      expect(retry, findsOneWidget);
      expect(find.text('Product b'), findsOneWidget);
      expectControls();

      await tester.tap(retry);
      await tester.pump();

      // One new request for the same page; the button is gone meanwhile.
      expect(gateway.requests, hasLength(3));
      expect(gateway.requests.last.cursor, const FeedCursor('page-2'));
      expect(retry, findsNothing);
      expect(find.text('Product b'), findsOneWidget);

      gateway.requests.last.succeed(feedItems(['c']));
      await settle(tester);
      await swipeUp(tester);

      expect(find.text('Product c'), findsOneWidget);
      expect(retry, findsNothing);
    });

    testWidgets('the end of the feed is quiet', (tester) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a', 'b']));
      await settle(tester);

      await swipeUp(tester);
      expect(find.text('Product b'), findsOneWidget);
      await swipeUp(tester);

      expect(find.text("You've seen everything for now"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Retry loading'), findsNothing);
      expect(gateway.requests, hasLength(1));
      expectControls();
    });
  });

  group('pull to refresh', () {
    testWidgets('keeps the old list until the new first page arrives', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a', 'b']), next: 'page-2');
      await settle(tester);

      await pullToRefresh(tester);

      expect(gateway.requests, hasLength(2));
      expect(gateway.requests.last.isFirstPage, isTrue);
      expect(find.text('Product a'), findsOneWidget);
      expectControls();

      gateway.requests.last.succeed(feedItems(['x', 'y']), next: 'fresh-2');
      await settle(tester);

      expect(find.text('Product x'), findsOneWidget);
      expect(find.text('Product a'), findsNothing);
    });

    testWidgets('a failed refresh keeps the old list and says so', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a', 'b']), next: 'page-2');
      await settle(tester);

      await pullToRefresh(tester);
      gateway.requests.last.fail();
      await settle(tester);

      expect(find.text('Product a'), findsOneWidget);
      expect(find.text("Couldn't refresh the feed."), findsOneWidget);
      expectControls();

      // The old list still pages on from where it was.
      await swipeUp(tester);
      expect(find.text('Product b'), findsOneWidget);
      expect(gateway.requests.last.cursor, const FeedCursor('page-2'));

      // Let the message go away by itself.
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
    });

    testWidgets('a feed of one Feed Item can be pulled to refresh', (
      tester,
    ) async {
      final gateway = await pumpFeed(tester);
      gateway.requests.last.succeed(feedItems(['a']), next: 'page-2');
      await settle(tester);

      await pullToRefresh(tester);

      expect(gateway.requests, hasLength(2));
      expect(gateway.requests.last.isFirstPage, isTrue);
    });
  });
}

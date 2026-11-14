// Events recorded by the whole app (ticket #9): what the feed records as
// the Shopper swipes, the actions recorded around it, the buffer surviving
// a restart, Profile's ad counter and the debug Events screen. The whole
// app from its root, on the Fixtures, for a Shopper in the US.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/events/data/events_storage.dart';
import 'package:stafeed/app/features/events/events_screen.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/events/providers/events_provider.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/product/platform/product_platform.dart';
import 'package:stafeed/app/stafeed_app.dart';

import '../../support/shopper.dart';
import '../product/support/fake_product_platform.dart';

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

  late ProviderContainer app;

  /// Starts the app as a launch does, with Event times following the test's
  /// own clock.
  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          eventsClockProvider.overrideWithValue(
            () => tester.binding.clock.now(),
          ),
          externalLinksProvider.overrideWithValue(FakeExternalLinks()),
          shareSheetProvider.overrideWithValue(FakeShareSheet()),
        ],
        child: const StafeedApp(),
      ),
    );
    await tester.pumpAndSettle();
    app = ProviderScope.containerOf(tester.element(find.byType(StafeedApp)));
  }

  List<Event> recorded() => app.read(eventsLogProvider).value ?? const [];

  List<EventType> recordedTypes() => [
    for (final event in recorded()) event.type,
  ];

  Future<void> swipeUp(WidgetTester tester) async {
    await tester.drag(feedPages, const Offset(0, -400));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(NavigationDestination, label));
    await tester.pumpAndSettle();
  }

  testWidgets('the first Feed Item on screen is one impression of an Ad', (
    tester,
  ) async {
    final first = (await fixtureFeed()).first;
    await launchApp(tester);

    final impression = recorded().single;
    expect(impression.type, EventType.impression);
    expect(impression.feedItemId, first.id);
    expect(impression.isAd, isTrue);
  });

  testWidgets('staying on a Feed Item records a 2s and a 5s view, once each', (
    tester,
  ) async {
    await launchApp(tester);

    await tester.pump(const Duration(seconds: 2));
    expect(recordedTypes(), [EventType.impression, EventType.view2s]);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 30));
    expect(recordedTypes(), [
      EventType.impression,
      EventType.view2s,
      EventType.view5s,
    ]);
  });

  testWidgets('swiping straight past a Feed Item is a Skip, then the next '
      'impression', (tester) async {
    final feed = await fixtureFeed();
    await launchApp(tester);

    await swipeUp(tester);

    final events = recorded();
    expect(events.map((e) => e.type), [
      EventType.impression,
      anyOf(EventType.fastSkip, EventType.skip),
      EventType.impression,
    ]);
    expect(events[1].feedItemId, feed[0].id);
    expect(events[1].dwell, lessThan(const Duration(seconds: 2)));
    expect(events[2].feedItemId, feed[1].id);
  });

  testWidgets('swiping past after a while is not a Skip', (tester) async {
    await launchApp(tester);

    await tester.pump(const Duration(seconds: 3));
    await swipeUp(tester);

    expect(recordedTypes(), [
      EventType.impression,
      EventType.view2s,
      EventType.impression,
    ]);
  });

  testWidgets('a Feed Item the Shopper saved is not skipped, and the save is '
      'recorded', (tester) async {
    final first = (await fixtureFeed()).first as AffiliateAd;
    await launchApp(tester);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    await swipeUp(tester);

    expect(recordedTypes(), [
      EventType.impression,
      EventType.save,
      EventType.impression,
    ]);
    final save = recorded()[1];
    expect(save.productId, first.product.id);
    expect(save.offerId, first.offer.id);
  });

  testWidgets('opening details, sharing, handing off and reporting are each '
      'recorded once', (tester) async {
    final first = (await fixtureFeed()).first as AffiliateAd;
    await launchApp(tester);

    await tester.tap(find.text(first.product.title));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();
    final handOff = find.textContaining('View at');
    await tester.ensureVisible(handOff);
    await tester.tap(handOff);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrong price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send report'));
    await tester.pumpAndSettle();

    final actions = recorded().where((e) => e.type.isAction).toList();
    expect(actions.map((e) => e.type), [
      EventType.detailOpen,
      EventType.share,
      EventType.outboundClick,
      EventType.report,
    ]);
    for (final action in actions) {
      expect(action.productId, first.product.id);
    }
    expect(actions.first.feedItemId, first.id);
    expect(actions.first.offerId, first.offer.id);
    expect(actions.last.details, {'reason': 'wrongPrice'});
  });

  testWidgets('a filter change is recorded with the new filter, and the new '
      "feed's first Feed Item is a new impression", (tester) async {
    await launchApp(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Bags'));
    await tester.pumpAndSettle();

    final events = recorded();
    expect(events.map((e) => e.type), [
      EventType.impression,
      EventType.filterChange,
      EventType.impression,
    ]);
    expect(events[1].details, {'category': 'bags'});
  });

  testWidgets('another tab is not a Skip; coming back is a new impression', (
    tester,
  ) async {
    await launchApp(tester);

    await openTab(tester, 'Saved');
    await tester.pump(const Duration(seconds: 10));
    expect(recordedTypes(), [EventType.impression]);

    await openTab(tester, 'Feed');
    expect(recordedTypes(), [EventType.impression, EventType.impression]);
  });

  testWidgets('every Event has its own ID, and the buffer survives a '
      'restart', (tester) async {
    await launchApp(tester);
    await swipeUp(tester);
    await swipeUp(tester);
    final before = recorded();
    expect(before.map((e) => e.id).toSet(), hasLength(before.length));

    // Let the last write reach the device, then start again.
    await tester.pumpAndSettle();
    expect(await EventsStorage().load(), before);
    await launchApp(tester);

    expect(recorded().take(before.length), before);
  });

  testWidgets("Profile counts this week's Ads watched", (tester) async {
    await launchApp(tester);
    await swipeUp(tester);
    await swipeUp(tester);

    await openTab(tester, 'Profile');

    expect(
      find.text("You've watched 3 ads this week. Advertisers thank you."),
      findsOneWidget,
    );
  });

  testWidgets('the debug Events screen lists recent Events, newest first', (
    tester,
  ) async {
    await launchApp(tester);
    await tester.pump(const Duration(seconds: 2));
    await openTab(tester, 'Profile');

    await tester.tap(find.text('Events (debug)'));
    await tester.pumpAndSettle();

    expect(find.byType(EventsScreen), findsOneWidget);
    expect(
      find.text('2 Events kept on this phone, waiting to be sent.'),
      findsOneWidget,
    );
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles, ['Viewed 2s', 'Impression']);
  });
}

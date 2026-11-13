import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/widgets/product_card.dart';

Future<void> pumpFeed(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: FeedScreen())),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows the first Fixture with its price in its own currency', (
    tester,
  ) async {
    final firstPage = await FixtureDataGateway().getFeedPage();
    final first = firstPage.items.first as AffiliateAd;

    await pumpFeed(tester);

    expect(find.text(first.product.title), findsOneWidget);
    expect(find.text(first.offer.price.format()), findsOneWidget);
  });

  testWidgets('the Feed Item fills the whole screen behind the search bar', (
    tester,
  ) async {
    await pumpFeed(tester);

    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(ProductCard)), screen);
  });

  testWidgets('marks the feed as sample data', (tester) async {
    await pumpFeed(tester);

    expect(find.textContaining('Sample data'), findsOneWidget);
  });

  testWidgets('category chips come from the data source', (tester) async {
    final filters = await FixtureDataGateway().getSupportedFilters();

    await pumpFeed(tester);

    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    for (final category in filters.categories) {
      expect(find.widgetWithText(ChoiceChip, category.label), findsOneWidget);
    }
    // The old DummyJSON chips are gone.
    expect(find.widgetWithText(ChoiceChip, 'Phones'), findsNothing);
  });

  testWidgets('tapping a category chip shows that category', (tester) async {
    final watchesPage = await FixtureDataGateway().getFeedPage(
      filter: const FeedFilter(category: 'watches'),
    );

    await pumpFeed(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Watches'));
    await tester.pumpAndSettle();

    final firstWatch = watchesPage.items.first as AffiliateAd;
    expect(find.text(firstWatch.product.title), findsOneWidget);
  });

  testWidgets(
    'a search with no matches keeps the search box, chips and marker',
    (tester) async {
      await pumpFeed(tester);

      await tester.enterText(find.byType(TextField), 'zzz no such thing');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.textContaining('Sample data'), findsOneWidget);
    },
  );

  testWidgets('the Save button is not covered by the search box', (
    tester,
  ) async {
    await pumpFeed(tester);

    // A real tap at the heart's position, so a control drawn on top of it
    // would swallow the tap and the Product would stay unsaved.
    await tester.tapAt(tester.getCenter(find.byIcon(Icons.favorite_border)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });
}

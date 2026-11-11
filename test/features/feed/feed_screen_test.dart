import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';

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
    final first = firstPage.items.first;

    await pumpFeed(tester);

    expect(find.text(first.product.title), findsOneWidget);
    expect(find.text(first.offer.price.format()), findsOneWidget);
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

    expect(find.text(watchesPage.items.first.product.title), findsOneWidget);
  });
}

// The Saved tab (ticket #8): shown from the snapshots on the device, never
// from the feed, with Products that can't be bought any more marked.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/saved/data/saved_products_storage.dart';
import 'package:stafeed/app/features/saved/providers/saved_products_provider.dart';
import 'package:stafeed/app/features/saved/save_action.dart';
import 'package:stafeed/app/features/saved/saved_screen.dart';

import '../../support/shopper.dart';
import '../feed/support/scripted_data_gateway.dart';
import 'support/saved_fixtures.dart';

void main() {
  late ScriptedDataGateway gateway;

  setUp(() {
    useEmptyDeviceStorage();
    // Knows every Product unless a test says otherwise. Its feed never
    // answers: the Saved tab mustn't need it.
    gateway = ScriptedDataGateway()
      ..onGetProduct = (id) async => savedTestProduct(id);
  });

  Future<void> openSaved(
    WidgetTester tester, {
    SavedProductsStorage? storage,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataGatewayProvider.overrideWithValue(gateway),
          if (storage != null)
            savedProductsStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(home: SavedScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says so when nothing is saved', (tester) async {
    await openSaved(tester);

    expect(find.textContaining('Nothing saved yet'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('shows every Saved Product from its snapshot, newest first, '
      'with no feed loaded', (tester) async {
    await SavedProductsStorage().save([
      savedSnapshot('a', title: 'Trail Runner', price: 8550),
      savedSnapshot('b', title: 'Day Bag', merchant: 'Peak Supply'),
    ]);

    await openSaved(tester);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data);
    expect(titles, ['Trail Runner', 'Day Bag']);
    expect(find.text(r'$85.50 · Acme Store'), findsOneWidget);
    expect(find.text(r'$45.00 · Peak Supply'), findsOneWidget);
    expect(gateway.requests, isEmpty, reason: 'the feed is never asked');
  });

  testWidgets('marks Products that are gone or out of stock', (tester) async {
    await SavedProductsStorage().save([
      savedSnapshot('gone', title: 'Gone'),
      savedSnapshot('sold-out', title: 'Sold out'),
      savedSnapshot('fine', title: 'Fine'),
    ]);
    gateway.onGetProduct = (id) async => switch (id) {
      'gone' => null,
      'sold-out' => savedTestProduct(
        id,
        offers: [savedTestOffer('o', isAvailable: false)],
      ),
      _ => savedTestProduct(id),
    };

    await openSaved(tester);

    Finder markOn(String title, String mark) => find.descendant(
      of: find.widgetWithText(ListTile, title),
      matching: find.text(mark),
    );
    expect(markOn('Gone', 'Not available any more'), findsOneWidget);
    expect(markOn('Sold out', 'Out of stock'), findsOneWidget);
    expect(find.text('Not available any more'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('offline, Saved Products still show, unmarked', (tester) async {
    await SavedProductsStorage().save([savedSnapshot('a', title: 'Trail')]);
    gateway.onGetProduct = (_) => Future.error(StateError('offline'));

    await openSaved(tester);

    expect(find.widgetWithText(ListTile, 'Trail'), findsOneWidget);
    expect(find.text('Not available any more'), findsNothing);
    expect(find.text('Out of stock'), findsNothing);
  });

  testWidgets('a picture that fails to load keeps its row in shape', (
    tester,
  ) async {
    await SavedProductsStorage().save([savedSnapshot('a', title: 'Trail')]);

    await openSaved(tester);

    // Test runs have no network: the picture fails, the icon shows.
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(tester.getSize(find.byType(ListTile)).height, lessThan(120));
  });

  testWidgets('the heart removes a Saved Product, for good', (tester) async {
    await SavedProductsStorage().save([
      savedSnapshot('a', title: 'Trail Runner'),
      savedSnapshot('b', title: 'Day Bag'),
    ]);
    await openSaved(tester);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Trail Runner'),
        matching: find.byTooltip('Remove from Saved'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trail Runner'), findsNothing);
    expect(find.text('Day Bag'), findsOneWidget);
    expect(
      (await SavedProductsStorage().load()).map((saved) => saved.productId),
      ['b'],
    );
  });

  testWidgets('a removal the device won\'t store is undone and said', (
    tester,
  ) async {
    await SavedProductsStorage().save([savedSnapshot('a', title: 'Trail')]);
    final storage = FlakySavedProductsStorage()
      ..error = StateError('disk full');
    await openSaved(tester, storage: storage);

    await tester.tap(find.byTooltip('Remove from Saved'));
    await tester.pumpAndSettle();

    expect(find.text(savedWriteFailedMessage), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Trail'), findsOneWidget);
  });

  testWidgets('Saved Products that can\'t be read offer Retry', (tester) async {
    await SavedProductsStorage().save([savedSnapshot('a', title: 'Trail')]);
    final storage = UnreadableSavedProductsStorage();
    await openSaved(tester, storage: storage);

    expect(find.text("Couldn't load your Saved Products."), findsOneWidget);

    storage.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Trail'), findsOneWidget);
  });
}

// Saving and removing Saved Products (ticket #8): safe while loading, kept
// on the device, and honest when the device won't store a change.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/saved/data/saved_products_storage.dart';
import 'package:stafeed/app/features/saved/providers/saved_products_provider.dart';

import '../../support/shopper.dart';
import '../feed/support/scripted_data_gateway.dart';
import 'support/saved_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 11, 14, 12);

  setUp(useEmptyDeviceStorage);

  ProviderContainer container({
    SavedProductsStorage? storage,
    ScriptedDataGateway? gateway,
  }) {
    final container = ProviderContainer(
      overrides: [
        savedProductsClockProvider.overrideWithValue(() => now),
        if (storage != null)
          savedProductsStorageProvider.overrideWithValue(storage),
        if (gateway != null) dataGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  final shoe = savedTestProduct('shoe', title: 'Trail Runner');
  final bag = savedTestProduct('bag', title: 'Day Bag');

  Future<void> toggle(ProviderContainer container, Product product) => container
      .read(savedProductsProvider.notifier)
      .toggle(product, product.offers.first);

  test('saving stores a snapshot, newest first, on the device', () async {
    final app = container();
    await app.read(savedProductsProvider.future);

    await toggle(app, shoe);
    await toggle(app, bag);

    final expected = [
      for (final product in [bag, shoe])
        savedSnapshot(product.id, title: product.title, savedAt: now),
    ];
    expect(app.read(savedProductsProvider).value, expected);
    expect(app.read(savedProductIdsProvider), {'bag', 'shoe'});
    expect(await SavedProductsStorage().load(), expected);
  });

  test('saving a saved Product again removes it', () async {
    final app = container();
    await toggle(app, shoe);
    await toggle(app, shoe);

    expect(app.read(savedProductsProvider).value, isEmpty);
    expect(await SavedProductsStorage().load(), isEmpty);
  });

  test('remove takes one Saved Product out', () async {
    final app = container();
    await toggle(app, shoe);
    await toggle(app, bag);

    await app.read(savedProductsProvider.notifier).remove('shoe');

    expect(app.read(savedProductIdsProvider), {'bag'});
    expect(
      (await SavedProductsStorage().load()).map((saved) => saved.productId),
      ['bag'],
    );
  });

  test('Saved Products survive a restart', () async {
    await toggle(container(), shoe);

    final afterRestart = container();
    expect(
      (await afterRestart.read(savedProductsProvider.future)).single.title,
      'Trail Runner',
    );
  });

  test('saving while the Saved Products are still loading never throws and '
      'keeps what was already saved', () async {
    await SavedProductsStorage().save([savedSnapshot('bag')]);
    final app = container();

    // Nothing has been read yet: the very first thing is a save.
    expect(app.read(savedProductsProvider).isLoading, isTrue);
    await toggle(app, shoe);

    expect(app.read(savedProductIdsProvider), {'shoe', 'bag'});
    expect(await SavedProductsStorage().load(), hasLength(2));
  });

  test('two quick saves both end up on the device', () async {
    final app = container();
    await app.read(savedProductsProvider.future);

    await Future.wait([toggle(app, shoe), toggle(app, bag)]);

    expect(
      (await SavedProductsStorage().load()).map((saved) => saved.productId),
      unorderedEquals(['shoe', 'bag']),
    );
  });

  group('when the device won\'t store the change', () {
    test('saving shows straight away, then goes back and says so', () async {
      final storage = FlakySavedProductsStorage();
      final app = container(storage: storage);
      await toggle(app, bag);
      storage.error = StateError('disk full');

      final saving = toggle(app, shoe);
      expect(app.read(savedProductIdsProvider), {'shoe', 'bag'});

      await expectLater(saving, throwsA(isA<SavedProductsWriteException>()));
      expect(app.read(savedProductIdsProvider), {'bag'});
      expect(
        (await SavedProductsStorage().load()).map((saved) => saved.productId),
        ['bag'],
      );
    });

    test('removing goes back too', () async {
      final storage = FlakySavedProductsStorage();
      final app = container(storage: storage);
      await toggle(app, shoe);
      storage.error = StateError('disk full');

      await expectLater(
        app.read(savedProductsProvider.notifier).remove('shoe'),
        throwsA(isA<SavedProductsWriteException>()),
      );
      expect(app.read(savedProductIdsProvider), {'shoe'});
    });
  });

  test('saving when the Saved Products could not be read says so instead of '
      'overwriting them', () async {
    await SavedProductsStorage().save([savedSnapshot('bag')]);
    final app = container(storage: UnreadableSavedProductsStorage());
    await expectLater(
      app.read(savedProductsProvider.future),
      throwsA(isA<StateError>()),
    );

    await expectLater(
      toggle(app, shoe),
      throwsA(isA<SavedProductsWriteException>()),
    );
    expect(await SavedProductsStorage().load(), [savedSnapshot('bag')]);
  });

  group('availability', () {
    Future<SavedProductAvailability> availabilityOf(
      ScriptedDataGateway gateway,
    ) {
      final app = container(gateway: gateway);
      final sub = app.listen(
        savedProductAvailabilityProvider('shoe'),
        (_, _) {},
      );
      addTearDown(sub.close);
      return app.read(savedProductAvailabilityProvider('shoe').future);
    }

    test('a Product with an Offer in stock is available', () async {
      expect(
        await availabilityOf(ScriptedDataGateway(products: {'shoe': shoe})),
        SavedProductAvailability.available,
      );
    });

    test('a Product with no Offer in stock is out of stock', () async {
      final soldOut = savedTestProduct(
        'shoe',
        offers: [savedTestOffer('o1', isAvailable: false)],
      );
      expect(
        await availabilityOf(ScriptedDataGateway(products: {'shoe': soldOut})),
        SavedProductAvailability.outOfStock,
      );
    });

    test('a Product the gateway no longer has is gone', () async {
      expect(
        await availabilityOf(ScriptedDataGateway()),
        SavedProductAvailability.gone,
      );
    });

    test('a failed check is an error, not "gone"', () async {
      final gateway = ScriptedDataGateway()
        ..onGetProduct = (_) => Future.error(StateError('offline'));
      await expectLater(availabilityOf(gateway), throwsA(isA<StateError>()));
    });
  });
}

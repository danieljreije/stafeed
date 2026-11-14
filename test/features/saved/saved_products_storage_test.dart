// Saved Products are kept on the device with their snapshots (ticket #8),
// using the in-memory shared-preferences mode.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/saved/data/saved_products_storage.dart';
import 'package:stafeed/app/features/saved/models/saved_product.dart';

import '../../support/shopper.dart';
import 'support/saved_fixtures.dart';

void main() {
  setUp(useEmptyDeviceStorage);

  test('nothing is saved on a new phone', () async {
    expect(await SavedProductsStorage().load(), isEmpty);
  });

  test('Saved Products are read back by a later launch, in order', () async {
    final saved = [
      savedSnapshot('a', savedAt: DateTime.utc(2026, 11, 14, 10)),
      savedSnapshot('b', savedAt: DateTime.utc(2026, 11, 13, 8)),
    ];

    await SavedProductsStorage().save(saved);

    // A new storage object, as after a restart.
    expect(await SavedProductsStorage().load(), saved);
  });

  test('a snapshot keeps title, Brand, image, price, currency and '
      'Merchant', () async {
    final product = savedTestProduct(
      'p1',
      title: 'Trail Runner',
      imageUrls: ['https://img.example/first.jpg', 'https://img.example/2.jpg'],
    );
    final offer = savedTestOffer('o1', price: 8550, merchant: 'Peak Supply');

    await SavedProductsStorage().save([
      SavedProduct.snapshot(
        product,
        offer,
        savedAt: DateTime.utc(2026, 11, 14),
      ),
    ]);
    final [read] = await SavedProductsStorage().load();

    expect(read.productId, 'p1');
    expect(read.offerId, 'o1');
    expect(read.title, 'Trail Runner');
    expect(read.brand, 'Northstar');
    expect(read.imageUrl, 'https://img.example/first.jpg');
    expect(read.price, const Money(8550, 'USD'));
    expect(read.merchant, 'Peak Supply');
    expect(read.savedAt, DateTime.utc(2026, 11, 14));
  });

  test('a Product without pictures is saved without an image', () async {
    await SavedProductsStorage().save([
      SavedProduct.snapshot(
        savedTestProduct('p1', imageUrls: const []),
        savedTestOffer('o1'),
        savedAt: DateTime.utc(2026, 11, 14),
      ),
    ]);

    final [read] = await SavedProductsStorage().load();
    expect(read.imageUrl, isNull);
  });

  test('saving again replaces what was stored', () async {
    final storage = SavedProductsStorage();
    await storage.save([savedSnapshot('a'), savedSnapshot('b')]);
    await storage.save([savedSnapshot('b')]);

    expect(await storage.load(), [savedSnapshot('b')]);
  });

  test('an unreadable entry is left out, the others are kept', () async {
    await SavedProductsStorage().save([savedSnapshot('a')]);
    final stored = await SharedPreferencesAsync().getString('saved_products');
    await SharedPreferencesAsync().setString(
      'saved_products',
      stored!.replaceFirst('[', '[{"productId": 3},'),
    );

    expect(await SavedProductsStorage().load(), [savedSnapshot('a')]);
  });

  group('something unreadable in storage means nothing saved', () {
    for (final (name, stored) in [
      ('not JSON', 'not json at all'),
      ('JSON of another shape', '{"productId": "a"}'),
    ]) {
      test(name, () async {
        await SharedPreferencesAsync().setString('saved_products', stored);

        expect(await SavedProductsStorage().load(), isEmpty);
      });
    }
  });

  test('bare Product IDs saved by an older version are dropped on the next '
      'save', () async {
    await SharedPreferencesAsync().setStringList('saved_product_ids', ['x']);

    await SavedProductsStorage().save([savedSnapshot('a')]);

    expect(
      await SharedPreferencesAsync().getStringList('saved_product_ids'),
      isNull,
    );
  });
}

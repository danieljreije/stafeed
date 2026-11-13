// The Shopper's onboarding choices survive a restart (ticket #6).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stafeed/app/features/shopper/data/shopper_config_storage.dart';
import 'package:stafeed/app/features/shopper/models/destination_country.dart';
import 'package:stafeed/app/features/shopper/models/shopper_config.dart';

import '../../support/shopper.dart';

void main() {
  setUp(useEmptyDeviceStorage);

  test('nothing is stored before onboarding', () async {
    expect(await ShopperConfigStorage().load(), isNull);
  });

  test('a saved config is read back by a later launch', () async {
    const config = ShopperConfig(
      destinationCountry: DestinationCountry.unitedArabEmirates,
      currencyCode: 'AED',
      interests: {'sneakers', 'home-decor'},
    );

    await ShopperConfigStorage().save(config);

    expect(await ShopperConfigStorage().load(), config);
  });

  test('saving again replaces the earlier config', () async {
    final storage = ShopperConfigStorage();
    await storage.save(
      const ShopperConfig(
        destinationCountry: DestinationCountry.unitedStates,
        currencyCode: 'USD',
        interests: {'bags'},
      ),
    );

    const later = ShopperConfig(
      destinationCountry: DestinationCountry.lebanon,
      currencyCode: 'USD',
    );
    await storage.save(later);

    expect(await storage.load(), later);
  });

  test('each Destination Country has a two-letter code and a currency', () {
    expect(DestinationCountry.values.map((country) => country.code), [
      'US',
      'GB',
      'AE',
      'LB',
    ]);
    for (final country in DestinationCountry.values) {
      expect(shopperCurrencies, contains(country.defaultCurrency));
      expect(DestinationCountry.fromCode(country.code), country);
    }
    expect(DestinationCountry.fromCode('FR'), isNull);
  });

  group('something unreadable in storage means onboarding again', () {
    for (final (name, stored) in [
      ('not JSON', 'not json at all'),
      ('JSON of another shape', '[1, 2, 3]'),
      ('a country the app does not know', '{"destinationCountry":"FR"}'),
      ('no currency', '{"destinationCountry":"US"}'),
    ]) {
      test(name, () async {
        await SharedPreferencesAsync().setString('shopper_config', stored);

        expect(await ShopperConfigStorage().load(), isNull);
      });
    }
  });
}

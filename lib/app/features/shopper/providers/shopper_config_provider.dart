import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shopper_config_storage.dart';
import '../models/destination_country.dart';
import '../models/shopper_config.dart';

final shopperConfigStorageProvider = Provider<ShopperConfigStorage>(
  (ref) => ShopperConfigStorage(),
);

/// The Shopper's config. Null until onboarding is finished.
class ShopperConfigNotifier extends AsyncNotifier<ShopperConfig?> {
  @override
  Future<ShopperConfig?> build() =>
      ref.read(shopperConfigStorageProvider).load();

  /// Uses [config] from now on and keeps it for the next launch.
  Future<void> save(ShopperConfig config) async {
    state = AsyncData(config);

    await ref.read(shopperConfigStorageProvider).save(config);
  }
}

final shopperConfigProvider =
    AsyncNotifierProvider<ShopperConfigNotifier, ShopperConfig?>(
      ShopperConfigNotifier.new,
    );

/// The Shopper's Destination Country, or null before onboarding is done.
final destinationCountryProvider = Provider<DestinationCountry?>(
  (ref) => switch (ref.watch(shopperConfigProvider)) {
    AsyncData(:final value) => value?.destinationCountry,
    _ => null,
  },
);

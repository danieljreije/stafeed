import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/shopper/data/shopper_config_storage.dart';
import 'package:stafeed/app/features/shopper/models/destination_country.dart';
import 'package:stafeed/app/features/shopper/models/shopper_config.dart';

/// A phone with nothing stored on it: a Shopper who has never opened the app.
void useEmptyDeviceStorage() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

/// Stores a finished onboarding, the way the app itself stores it, so the
/// app opens straight into the Feed.
Future<void> storeOnboardedShopper({
  DestinationCountry country = DestinationCountry.unitedStates,
  Set<String> interests = const {},
}) => ShopperConfigStorage().save(
  ShopperConfig(
    destinationCountry: country,
    currencyCode: country.defaultCurrency,
    interests: interests,
  ),
);

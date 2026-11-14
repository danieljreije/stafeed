import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/providers/events_provider.dart';
import '../../not_interested/providers/not_interested_provider.dart';
import '../../ranking/shopper_taste.dart';
import '../../shopper/providers/shopper_config_provider.dart';
import '../data/data_gateway.dart';
import '../data/fixture_data_gateway.dart';
import '../models/supported_filters.dart';

/// The app's single route to data. Fixtures only for now; the API gateway
/// arrives with the Supabase backend.
///
/// The gateway knows the Shopper's Destination Country, so nothing it
/// serves has to be filtered again by the screens. A new country gives a new
/// gateway, and the feed loads again from it.
///
/// For You is ranked from the Shopper's taste (see [readShopperTaste]),
/// read afresh for every page, so a change of taste never reloads the feed;
/// it shapes the pages still to come.
final dataGatewayProvider = Provider<DataGateway>(
  (ref) => FixtureDataGateway(
    destinationCountry: ref.watch(destinationCountryProvider)?.code,
    taste: () => readShopperTaste(ref),
  ),
);

/// The Shopper's taste as stored on this phone: their interests, the
/// Products they marked Not interested, and the long-term signals in their
/// Events. Waits until all three are read.
Future<ShopperTaste> readShopperTaste(Ref ref) async {
  // A gateway left over from an older Destination Country.
  if (!ref.mounted) return const ShopperTaste();

  final config = ref.read(shopperConfigProvider.future);
  final notInterested = ref.read(notInterestedProvider.future);
  final events = ref.read(eventsLogProvider.future);

  Future<T> orElse<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } on Object {
      return fallback;
    }
  }

  return ShopperTaste(
    interests: (await orElse(config, null))?.interests ?? const {},
    notInterested: await orElse(notInterested, const <String>{}),
    signals: longTermSignals(await orElse(events, const [])),
  );
}

final supportedFiltersProvider = FutureProvider<SupportedFilters>(
  (ref) => ref.watch(dataGatewayProvider).getSupportedFilters(),
);

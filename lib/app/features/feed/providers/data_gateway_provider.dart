import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final dataGatewayProvider = Provider<DataGateway>(
  (ref) => FixtureDataGateway(
    destinationCountry: ref.watch(destinationCountryProvider)?.code,
  ),
);

final supportedFiltersProvider = FutureProvider<SupportedFilters>(
  (ref) => ref.watch(dataGatewayProvider).getSupportedFilters(),
);

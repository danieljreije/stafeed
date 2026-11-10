import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/data_gateway.dart';
import '../data/fixture_data_gateway.dart';
import '../models/supported_filters.dart';

/// The app's single route to data. Fixtures only for now; the API gateway
/// arrives with the Supabase backend.
final dataGatewayProvider = Provider<DataGateway>(
  (ref) => FixtureDataGateway(),
);

final supportedFiltersProvider = FutureProvider<SupportedFilters>(
  (ref) => ref.watch(dataGatewayProvider).getSupportedFilters(),
);

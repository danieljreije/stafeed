import 'package:flutter/foundation.dart';

import 'destination_country.dart';

/// What the Shopper chose at onboarding: Destination Country, currency and
/// interests. Having one means onboarding is done.
@immutable
class ShopperConfig {
  const ShopperConfig({
    required this.destinationCountry,
    required this.currencyCode,
    this.interests = const {},
  });

  final DestinationCountry destinationCountry;

  /// ISO 4217 code of the currency the Shopper prefers.
  final String currencyCode;

  /// Category IDs the Shopper picked. Empty when they skipped.
  final Set<String> interests;

  Map<String, Object?> toJson() => {
    'destinationCountry': destinationCountry.code,
    'currencyCode': currencyCode,
    'interests': interests.toList(),
  };

  /// Null when [json] isn't a config this version understands; the Shopper
  /// then goes through onboarding again instead of the app breaking.
  static ShopperConfig? fromJson(Object? json) {
    if (json is! Map) return null;

    final country = switch (json['destinationCountry']) {
      final String code => DestinationCountry.fromCode(code),
      _ => null,
    };
    final currencyCode = json['currencyCode'];
    final interests = json['interests'];
    if (country == null || currencyCode is! String) return null;

    return ShopperConfig(
      destinationCountry: country,
      currencyCode: currencyCode,
      interests: {
        if (interests is List)
          for (final interest in interests)
            if (interest is String) interest,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShopperConfig &&
      other.destinationCountry == destinationCountry &&
      other.currencyCode == currencyCode &&
      setEquals(other.interests, interests);

  @override
  int get hashCode => Object.hash(
    destinationCountry,
    currencyCode,
    Object.hashAllUnordered(interests),
  );

  @override
  String toString() =>
      'ShopperConfig(${destinationCountry.code}, $currencyCode, $interests)';
}

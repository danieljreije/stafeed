/// Where the Shopper wants Products delivered. Offers that don't ship there
/// are never shown.
///
/// The onboarding list for now; the real launch market is still open (#24).
enum DestinationCountry {
  unitedStates('US', 'United States', 'USD'),
  unitedKingdom('GB', 'United Kingdom', 'GBP'),
  unitedArabEmirates('AE', 'United Arab Emirates', 'AED'),
  lebanon('LB', 'Lebanon', 'USD');

  const DestinationCountry(this.code, this.label, this.defaultCurrency);

  /// ISO 3166-1 alpha-2 code, as used in an Offer's ships-to list.
  final String code;

  /// The name the Shopper sees.
  final String label;

  /// The currency suggested when the Shopper picks this country.
  final String defaultCurrency;

  static DestinationCountry? fromCode(String? code) {
    for (final country in values) {
      if (country.code == code) return country;
    }
    return null;
  }
}

/// The currencies a Shopper can pick, as ISO 4217 codes.
const List<String> shopperCurrencies = ['USD', 'GBP', 'EUR', 'AED'];

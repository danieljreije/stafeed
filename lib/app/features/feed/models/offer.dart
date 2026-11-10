import 'money.dart';

/// One Merchant's terms for a Product.
class Offer {
  const Offer({
    required this.id,
    required this.merchant,
    required this.price,
    required this.shipsTo,
    required this.url,
    required this.isAffiliate,
    this.isAvailable = true,
  });

  final String id;

  /// The seller the Shopper is handed off to.
  final String merchant;
  final Money price;

  /// ISO 3166-1 alpha-2 codes of the countries this Offer ships to.
  final Set<String> shipsTo;

  /// Where the Merchant Handoff goes. Kept exactly as the source gave it.
  final Uri url;

  /// True when Stafeed earns from this Offer (affiliate or pay-per-click),
  /// which makes it an Ad. False means Not an Ad.
  final bool isAffiliate;
  final bool isAvailable;
}

import 'package:flutter/foundation.dart';

/// A Merchant Handoff: the Shopper left Stafeed for the Merchant from one
/// Product and Offer. Recorded through the data gateway.
@immutable
class OutboundClick {
  const OutboundClick({
    required this.productId,
    required this.offerId,
    required this.merchant,
    required this.url,
  });

  final String productId;
  final String offerId;
  final String merchant;

  /// Where the Shopper was sent, exactly as the Offer gave it.
  final Uri url;

  @override
  bool operator ==(Object other) =>
      other is OutboundClick &&
      other.productId == productId &&
      other.offerId == offerId &&
      other.merchant == merchant &&
      other.url == url;

  @override
  int get hashCode => Object.hash(productId, offerId, merchant, url);

  @override
  String toString() => 'OutboundClick($productId, $offerId, $merchant, $url)';
}

/// Why a Shopper reports a Product.
enum ReportReason {
  wrongPrice('Wrong price'),
  misleading('Misleading'),
  prohibitedItem('Prohibited item'),
  brokenLink('Broken link'),
  other('Other');

  const ReportReason(this.label);

  /// What the Shopper reads when picking it.
  final String label;
}

/// A Shopper's report that something is wrong with a Product or its Offer.
/// Stored through the data gateway.
@immutable
class ProductReport {
  const ProductReport({
    required this.productId,
    required this.offerId,
    required this.reason,
    this.note = '',
  });

  final String productId;

  /// The Offer the Shopper was looking at, if any.
  final String? offerId;
  final ReportReason reason;

  /// The Shopper's own words. May be empty.
  final String note;

  @override
  bool operator ==(Object other) =>
      other is ProductReport &&
      other.productId == productId &&
      other.offerId == offerId &&
      other.reason == reason &&
      other.note == note;

  @override
  int get hashCode => Object.hash(productId, offerId, reason, note);

  @override
  String toString() =>
      'ProductReport($productId, $offerId, ${reason.name}, "$note")';
}

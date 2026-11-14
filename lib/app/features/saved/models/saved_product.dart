import 'package:flutter/foundation.dart';

import '../../feed/models/money.dart';
import '../../feed/models/offer.dart';
import '../../feed/models/product.dart';

/// A Product the Shopper kept for later, with a snapshot of what they saw
/// when they saved it (title, image, price, Merchant), so the Saved tab can
/// show it without the feed, offline and after a restart.
@immutable
class SavedProduct {
  const SavedProduct({
    required this.productId,
    required this.offerId,
    required this.title,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.merchant,
    required this.savedAt,
  });

  /// The snapshot of [product] as shown with [offer], saved at [savedAt].
  factory SavedProduct.snapshot(
    Product product,
    Offer offer, {
    required DateTime savedAt,
  }) => SavedProduct(
    productId: product.id,
    offerId: offer.id,
    title: product.title,
    brand: product.brand,
    imageUrl: product.imageUrls.isEmpty ? null : product.imageUrls.first,
    price: offer.price,
    merchant: offer.merchant,
    savedAt: savedAt,
  );

  /// Reads what [toJson] wrote. Throws [FormatException] when [json] isn't
  /// a Saved Product.
  factory SavedProduct.fromJson(Object? json) {
    if (json case {
      'productId': final String productId,
      'offerId': final String offerId,
      'title': final String title,
      'brand': final String brand,
      'imageUrl': final String? imageUrl,
      'priceMinorUnits': final int priceMinorUnits,
      'currency': final String currency,
      'merchant': final String merchant,
      'savedAt': final String savedAt,
    }) {
      final savedAtTime = DateTime.tryParse(savedAt);
      if (savedAtTime != null) {
        return SavedProduct(
          productId: productId,
          offerId: offerId,
          title: title,
          brand: brand,
          imageUrl: imageUrl,
          price: Money(priceMinorUnits, currency),
          merchant: merchant,
          savedAt: savedAtTime,
        );
      }
    }
    throw const FormatException('Not a Saved Product');
  }

  final String productId;

  /// The Offer the Shopper saw, so its details open on the same one.
  final String offerId;
  final String title;
  final String brand;

  /// The Product's first picture when it was saved; null when it had none.
  final String? imageUrl;

  /// The price when it was saved. Today's price is on the details screen.
  final Money price;
  final String merchant;
  final DateTime savedAt;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'offerId': offerId,
    'title': title,
    'brand': brand,
    'imageUrl': imageUrl,
    'priceMinorUnits': price.minorUnits,
    'currency': price.currencyCode,
    'merchant': merchant,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is SavedProduct &&
      other.productId == productId &&
      other.offerId == offerId &&
      other.title == title &&
      other.brand == brand &&
      other.imageUrl == imageUrl &&
      other.price == price &&
      other.merchant == merchant &&
      other.savedAt.isAtSameMomentAs(savedAt);

  @override
  int get hashCode => Object.hash(
    productId,
    offerId,
    title,
    brand,
    imageUrl,
    price,
    merchant,
    savedAt.millisecondsSinceEpoch,
  );

  @override
  String toString() => 'SavedProduct($productId, $title)';
}

import 'offer.dart';

/// A thing someone can buy, independent of who sells it.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.category,
    required this.imageUrls,
    required this.offers,
    this.attributes = const {},
  });

  /// Stable ID from the source.
  final String id;
  final String title;
  final String description;

  /// The maker of the Product (not the Merchant selling it).
  final String brand;

  /// Category ID, as listed in the source's supported filters.
  final String category;
  final Map<String, String> attributes;
  final List<String> imageUrls;
  final List<Offer> offers;
}

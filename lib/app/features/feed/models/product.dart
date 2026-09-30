class Product {
  final String id;
  final String name;
  final String brand;
  final int priceInCents;
  final String currencyCode;
  final String category;
  final String imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.priceInCents,
    required this.currencyCode,
    required this.category,
    required this.imageUrl,
  });
}
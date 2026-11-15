/// A category a data source can filter by.
class ProductCategory {
  const ProductCategory({required this.id, required this.label});

  final String id;
  final String label;
}

/// The filters a data source actually supports, so the app only offers
/// real ones.
class SupportedFilters {
  const SupportedFilters({
    required this.categories,
    this.brands = const [],
    this.supportsMaxPrice = false,
  });

  final List<ProductCategory> categories;

  /// Brands a Shopping Session can be narrowed to. Empty when the source
  /// can't filter by Brand.
  final List<String> brands;

  /// Whether a Shopping Session can set a budget.
  final bool supportsMaxPrice;
}

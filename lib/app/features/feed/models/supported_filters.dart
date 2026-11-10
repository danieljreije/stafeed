/// A category a data source can filter by.
class ProductCategory {
  const ProductCategory({required this.id, required this.label});

  final String id;
  final String label;
}

/// The filters a data source actually supports, so the app only offers
/// real ones.
class SupportedFilters {
  const SupportedFilters({required this.categories});

  final List<ProductCategory> categories;
}

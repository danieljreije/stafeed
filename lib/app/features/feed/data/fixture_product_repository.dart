import '../models/product.dart';
import 'product_repository.dart';
import 'sample_products.dart';

class FixtureProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
    String? category,
    String? query,
  }) async {
    Iterable<Product> filteredProducts = sampleProducts;

    if (query != null && query.trim().isNotEmpty) {
      final search = query.trim().toLowerCase();

      filteredProducts = filteredProducts.where(
        (product) => product.name.toLowerCase().contains(search),
      );
    } else if (category != null) {
      filteredProducts = filteredProducts.where(
        (product) => product.category == category,
      );
    }

    return filteredProducts.skip(skip).take(limit).toList();
  }
}

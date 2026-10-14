import '../models/product.dart';
import 'product_repository.dart';
import 'sample_products.dart';

class FixtureProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts({int limit = 10, int skip = 0}) async {
    return sampleProducts.skip(skip).take(limit).toList();
  }
}

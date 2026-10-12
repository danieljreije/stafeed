import '../models/product.dart';
import 'product_repository.dart';
import 'sample_products.dart';

class FixtureProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async {
    return sampleProducts;
  }
}
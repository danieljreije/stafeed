import '../models/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    int limit = 10,
    int skip = 0,
  });
}
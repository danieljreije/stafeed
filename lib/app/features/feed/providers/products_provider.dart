import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../data/product_repository.dart';
import '../data/fixture_product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => FixtureProductRepository(),
);

final productsProvider = FutureProvider<List<Product>>(
  (ref) async {
    final repository = ref.watch(productRepositoryProvider);

    return repository.getProducts();
  },
);
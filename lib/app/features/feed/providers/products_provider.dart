import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../data/product_repository.dart';
import 'package:http/http.dart' as http;

import '../data/api_product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) {
    final client = http.Client();

    ref.onDispose(client.close);

    return ApiProductRepository(client);
  },
);
final productsProvider = FutureProvider<List<Product>>(
  (ref) async {
    final repository = ref.watch(productRepositoryProvider);

    return repository.getProducts();
  },
);
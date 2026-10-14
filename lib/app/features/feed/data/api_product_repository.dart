import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final http.Client _client;

  ApiProductRepository(this._client);

  @override
  Future<List<Product>> getProducts() async {
    final url = Uri.https('dummyjson.com', '/products', {
      'limit': '10',
      'skip': '0',
    });

    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    final items = decoded['products'] as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;

      return Product(
        id: 'dummyjson-${json['id']}',
        name: json['title'] as String,
        brand: json['brand'] as String? ?? 'Unknown brand',
        priceInCents: ((json['price'] as num) * 100).round(),
        currencyCode: 'USD',
        category: json['category'] as String,
        imageUrl: json['thumbnail'] as String,
      );
    }).toList();
  }
}

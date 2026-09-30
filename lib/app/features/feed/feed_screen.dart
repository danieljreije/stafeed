import 'package:flutter/material.dart';

import 'data/sample_products.dart';
import 'widgets/product_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: sampleProducts.length,
        onPageChanged: (index) {
          debugPrint('Viewing product: ${sampleProducts[index].name}');
        },
        itemBuilder: (context, index) {
          return ProductCard(product: sampleProducts[index]);
        },
      ),
    );
  }
}

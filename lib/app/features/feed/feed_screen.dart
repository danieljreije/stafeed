import 'package:flutter/material.dart';

import 'data/sample_products.dart';
import 'widgets/product_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final Set<String> savedProductIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: sampleProducts.length,
            onPageChanged: (index) {
              debugPrint('Viewing product: ${sampleProducts[index].name}');
            },
            itemBuilder: (context, index) {
              final product = sampleProducts[index];
              return ProductCard(
                product: product,
                isSaved: savedProductIds.contains(product.id),
                onSaveToggle: () {
                  setState(() {
                    debugPrint(savedProductIds.toString());
                    if (savedProductIds.contains(product.id)) {
                      savedProductIds.remove(product.id);
                    } else {
                      savedProductIds.add(product.id);
                    }
                  });
                },
              );
            },
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Text(
              'Saved: ${savedProductIds.length}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

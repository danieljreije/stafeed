import 'package:flutter/material.dart';

import '../models/feed_item.dart';

class ProductCard extends StatelessWidget {
  final FeedItem item;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const ProductCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final offer = item.offer;

    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.imageUrls.isEmpty)
            const Center(child: Icon(Icons.image_not_supported_outlined, size: 48))
          else
          Image.network(
            product.imageUrls.first,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image_outlined, size: 48),
              );
            },
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${product.brand} • ${offer.merchant}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 4),
                Text(
                  product.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.price.format(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                IconButton(
                  onPressed: () {
                    onSaveToggle();
                  },
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color: isSaved ? Colors.red : Colors.white,
                  ),
                ),
                Text(
                  isSaved ? 'Saved' : 'Save',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

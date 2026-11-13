import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import '../models/product.dart';
import 'feed_card_frame.dart';
import 'feed_item_labels.dart';

/// The card for a Brand Ad: the ad's own media and words, labelled AD and
/// Sponsored, with one chip per linked Product.
class BrandAdCard extends StatelessWidget {
  const BrandAdCard({super.key, required this.ad, required this.onProductTap});

  final BrandAd ad;

  /// Called with the Product whose chip the Shopper tapped.
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return FeedCardFrame(
      media: ad.media,
      details: [
        AdLabel(isSponsored: ad.isSponsored),
        const SizedBox(height: 8),
        Text(
          ad.brand,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ad.headline,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        if (ad.products.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final product in ad.products)
                ActionChip(
                  // Solid, so the chip reads on any picture.
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: Colors.black),
                  label: Text(product.title),
                  onPressed: () => onProductTap(product),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

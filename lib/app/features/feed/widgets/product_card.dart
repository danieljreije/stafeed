import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import 'feed_card_frame.dart';
import 'feed_item_labels.dart';

/// The card for a Feed Item that shows one Product with its chosen Offer:
/// an Affiliate Ad (labelled AD) or a Not an Ad Feed Item (labelled so).
class ProductCard extends StatelessWidget {
  final ProductFeedItem item;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  /// Opens the Product's details. Called when the card itself is tapped.
  final VoidCallback? onOpen;

  const ProductCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onSaveToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final offer = item.offer;

    final (label, note) = switch (item) {
      AffiliateAd() => (const AdLabel(), FeedItemNote.affiliate),
      NotAnAd() => (const NotAnAdLabel(), FeedItemNote.notAnAd),
    };

    return FeedCardFrame(
      media: item.media,
      onTap: onOpen,
      details: [
        label,
        const SizedBox(height: 8),
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
        const SizedBox(height: 6),
        FeedItemNote(note),
      ],
      sideActions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onSaveToggle,
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
    );
  }
}

import 'package:flutter/material.dart';

import '../../app_name.dart';
import '../feed/models/offer.dart';
import '../feed/models/product.dart';
import '../feed/widgets/sample_data_marker.dart';

/// Where "View at Merchant" lands for a Fixture: Fixtures aren't real
/// inventory and their links go nowhere, so this page says what the real
/// Merchant Handoff would do.
class FixtureMerchantScreen extends StatelessWidget {
  const FixtureMerchantScreen({
    super.key,
    required this.product,
    required this.offer,
  });

  final Product product;
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(offer.merchant)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: SampleDataMarker(),
          ),
          const SizedBox(height: 20),
          Text(
            'Here the real app would open ${offer.merchant}.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            '${product.title} is sample data, not something you can buy. '
            "For a real Product you'd land on ${offer.merchant}'s own page "
            'for it and buy it there. $appName never takes payment.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Back to $appName'),
          ),
        ],
      ),
    );
  }
}

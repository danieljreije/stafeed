import 'package:flutter/material.dart';

/// Tells the Shopper the feed is running on Fixtures, so demo content is
/// never mistaken for real Products.
class SampleDataMarker extends StatelessWidget {
  const SampleDataMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sample data. These are not real products.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.amber.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Sample data · not real products',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

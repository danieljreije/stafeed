import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/models/offer.dart';
import '../feed/models/product.dart';
import 'providers/saved_products_provider.dart';

/// What the Shopper is told when a save or removal couldn't be stored.
const savedWriteFailedMessage =
    "Couldn't update your Saved Products. "
    'Try again.';

/// Saves [product] as shown with [offer], or removes it when it is already
/// saved. A failure is told to the Shopper instead of thrown.
Future<void> toggleSaved(
  BuildContext context,
  WidgetRef ref,
  Product product,
  Offer offer,
) => _reportingFailure(
  context,
  () => ref.read(savedProductsProvider.notifier).toggle(product, offer),
);

/// Removes the Saved Product for [productId]. A failure is told to the
/// Shopper instead of thrown.
Future<void> removeSaved(
  BuildContext context,
  WidgetRef ref,
  String productId,
) => _reportingFailure(
  context,
  () => ref.read(savedProductsProvider.notifier).remove(productId),
);

Future<void> _reportingFailure(
  BuildContext context,
  Future<void> Function() change,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await change();
  } on SavedProductsWriteException {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(savedWriteFailedMessage)));
  }
}

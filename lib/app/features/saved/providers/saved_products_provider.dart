import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/models/event.dart';
import '../../events/providers/events_provider.dart';

import '../../feed/models/offer.dart';
import '../../feed/models/product.dart';
import '../../feed/providers/data_gateway_provider.dart';
import '../data/saved_products_storage.dart';
import '../models/saved_product.dart';

final savedProductsStorageProvider = Provider<SavedProductsStorage>(
  (ref) => SavedProductsStorage(),
);

/// When a Saved Product was saved. A provider so tests can fix the time.
final savedProductsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Saving or removing a Saved Product couldn't be stored on the device. The
/// Saved Products are back to how they were before the attempt.
class SavedProductsWriteException implements Exception {
  const SavedProductsWriteException(this.cause);

  final Object cause;

  @override
  String toString() => 'SavedProductsWriteException($cause)';
}

/// The Shopper's Saved Products, newest first, kept on the device.
class SavedProductsNotifier extends AsyncNotifier<List<SavedProduct>> {
  /// Writes run one after another, so the device always ends up holding
  /// the latest list.
  Future<void> _lastWrite = Future.value();

  @override
  Future<List<SavedProduct>> build() =>
      ref.read(savedProductsStorageProvider).load();

  /// Saves [product] as shown with [offer], or removes it when it is
  /// already saved.
  ///
  /// Safe to call while the Saved Products are still loading: it waits for
  /// them. Throws [SavedProductsWriteException] when the change couldn't be
  /// stored (or the Saved Products couldn't be read), leaving them as they
  /// were.
  Future<void> toggle(Product product, Offer offer) async {
    var saving = false;
    final changed = await _change((current) {
      saving = !current.any((saved) => saved.productId == product.id);
      return saving
          ? [
              SavedProduct.snapshot(
                product,
                offer,
                savedAt: ref.read(savedProductsClockProvider)(),
              ),
              ...current,
            ]
          : [
              for (final saved in current)
                if (saved.productId != product.id) saved,
            ];
    });
    if (changed) {
      _record(
        saving ? EventType.save : EventType.unsave,
        product.id,
        offerId: offer.id,
      );
    }
  }

  /// Removes the Saved Product for [productId], if there is one. Throws
  /// like [toggle].
  Future<void> remove(String productId) async {
    final changed = await _change(
      (current) => current.any((saved) => saved.productId == productId)
          ? [
              for (final saved in current)
                if (saved.productId != productId) saved,
            ]
          : null,
    );
    if (changed) _record(EventType.unsave, productId);
  }

  /// Records a save or unsave, once it is stored.
  void _record(EventType type, String productId, {String? offerId}) {
    if (!ref.mounted) return;
    unawaited(
      ref
          .read(eventsLogProvider.notifier)
          .record(NewEvent(type, productId: productId, offerId: offerId)),
    );
  }

  /// Applies [update] to the latest Saved Products, shows the result
  /// straight away and stores it. [update] returns null for no change.
  /// True when something changed and was stored. If storing fails, the list
  /// goes back to what it was and the failure is thrown.
  Future<bool> _change(
    List<SavedProduct>? Function(List<SavedProduct> current) update,
  ) async {
    if (!state.hasValue) {
      try {
        await future;
      } on Object catch (error) {
        throw SavedProductsWriteException(error);
      }
    }

    // Read after any wait, so a change made meanwhile isn't lost.
    final previous = state.requireValue;
    final updated = update(previous);
    if (updated == null) return false;
    state = AsyncData(updated);

    final storage = ref.read(savedProductsStorageProvider);
    final write = _lastWrite.then((_) => storage.save(updated));
    _lastWrite = write.catchError((Object _) {});

    try {
      await write;
    } on Object catch (error) {
      // Only undo when nothing newer has been shown since.
      if (ref.mounted && identical(state.value, updated)) {
        state = AsyncData(previous);
      }
      throw SavedProductsWriteException(error);
    }
    return true;
  }
}

final savedProductsProvider =
    AsyncNotifierProvider<SavedProductsNotifier, List<SavedProduct>>(
      SavedProductsNotifier.new,
      // Never retried by itself: the Saved tab offers a Retry button.
      retry: (retryCount, error) => null,
    );

/// The IDs of the Saved Products, for showing a Save button's state. Empty
/// while they are loading or when they couldn't be read.
final savedProductIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final saved
        in ref.watch(savedProductsProvider).value ?? const <SavedProduct>[])
      saved.productId,
  },
);

/// Whether a Saved Product can still be bought.
enum SavedProductAvailability {
  /// Still there, with an Offer in stock.
  available,

  /// Still there, but no Offer that ships to the Shopper is in stock.
  outOfStock,

  /// The source doesn't know it any more, or it no longer ships to the
  /// Shopper's Destination Country.
  gone,
}

/// Asks the data gateway about one Saved Product, so the Saved tab can mark
/// the ones that can't be bought any more. An error (offline, say) leaves
/// the Saved Product unmarked; never retried by itself.
final savedProductAvailabilityProvider = FutureProvider.autoDispose
    .family<SavedProductAvailability, String>((ref, productId) async {
      final product = await ref
          .watch(dataGatewayProvider)
          .getProduct(productId);
      if (product == null) return SavedProductAvailability.gone;
      return product.offers.any((offer) => offer.isAvailable)
          ? SavedProductAvailability.available
          : SavedProductAvailability.outOfStock;
    }, retry: (retryCount, error) => null);

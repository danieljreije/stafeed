import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/not_interested_storage.dart';

final notInterestedStorageProvider = Provider<NotInterestedStorage>(
  (ref) => NotInterestedStorage(),
);

/// Thrown when a Not interested couldn't be stored on the device. The
/// Product stays hidden until the app closes.
class NotInterestedWriteException implements Exception {
  const NotInterestedWriteException(this.cause);

  final Object cause;

  @override
  String toString() => 'NotInterestedWriteException($cause)';
}

/// The Products the Shopper marked Not interested, by ID. They are never
/// shown in a feed again.
class NotInterestedNotifier extends AsyncNotifier<Set<String>> {
  /// Writes run one after another, so the device ends up with the latest
  /// set.
  Future<void> _lastWrite = Future.value();

  @override
  Future<Set<String>> build() async {
    try {
      return await ref.read(notInterestedStorageProvider).load();
    } on Object {
      // Unreadable storage must not stop the feed; nothing is hidden yet.
      return const {};
    }
  }

  /// Hides [productId] for good. Shows at once; throws
  /// [NotInterestedWriteException] when the device won't store it (it stays
  /// hidden until the app closes, and is stored with the next one).
  Future<void> mark(String productId) async {
    if (!state.hasValue) {
      try {
        await future;
      } on Object {
        // build() never fails.
      }
    }
    if (!ref.mounted) return;

    final current = state.value ?? const <String>{};
    final updated = {...current, productId};
    // Written even when already hidden: an earlier write may have failed.
    if (!current.contains(productId)) state = AsyncData(updated);

    final storage = ref.read(notInterestedStorageProvider);
    final write = _lastWrite.then((_) => storage.save(updated));
    _lastWrite = write.catchError((Object _) {});
    try {
      await write;
    } on Object catch (error) {
      throw NotInterestedWriteException(error);
    }
  }
}

final notInterestedProvider =
    AsyncNotifierProvider<NotInterestedNotifier, Set<String>>(
      NotInterestedNotifier.new,
      retry: (retryCount, error) => null,
    );

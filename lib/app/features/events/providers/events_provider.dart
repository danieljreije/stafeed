import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_storage.dart';
import '../models/event.dart';

final eventsStorageProvider = Provider<EventsStorage>((ref) => EventsStorage());

/// When an Event happens. A provider so tests can fix or move the time.
final eventsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Makes each Event's unique ID. A provider so tests can predict them.
final eventIdsProvider = Provider<String Function()>((ref) => randomEventId);

/// A random (version 4) UUID.
String randomEventId() {
  final random = Random.secure();
  final bytes = [for (var i = 0; i < 16; i++) random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}

/// The Events recorded on this phone, oldest first, kept on the device
/// until they are sent to the backend (#19, #20).
class EventsLog extends AsyncNotifier<List<Event>> {
  /// The most Events kept. Beyond it the oldest are dropped, so a phone
  /// that never reaches the backend doesn't fill up.
  static const int maxBuffered = 5000;

  /// Writes run one after another, so the device always ends up holding
  /// the latest buffer.
  Future<void> _lastWrite = Future.value();

  @override
  Future<List<Event>> build() async {
    try {
      return await ref.read(eventsStorageProvider).load();
    } on Object {
      // An unreadable buffer must never stop the app from recording.
      return const [];
    }
  }

  /// The Events recorded so far; empty while they are being read.
  List<Event> get recorded => state.value ?? const [];

  /// Records [event] once, with a new unique ID and the current time, and
  /// stores it. Never throws: recording must never get in the Shopper's
  /// way. An Event the device won't store stays in memory and is stored
  /// with the next one.
  Future<void> record(NewEvent event) async {
    if (!ref.mounted) return;
    final recorded = Event.from(
      event,
      id: ref.read(eventIdsProvider)(),
      occurredAt: ref.read(eventsClockProvider)(),
    );
    final storage = ref.read(eventsStorageProvider);

    if (!state.hasValue) {
      try {
        await future;
      } on Object {
        // build() never fails; nothing to do.
      }
      if (!ref.mounted) return;
    }

    final current = state.value ?? const <Event>[];
    final updated = [
      ...current.length >= maxBuffered
          ? current.skip(current.length - maxBuffered + 1)
          : current,
      recorded,
    ];
    state = AsyncData(updated);

    final write = _lastWrite.then((_) => storage.save(updated));
    _lastWrite = write.catchError((Object _) {});
    await _lastWrite;
  }
}

final eventsLogProvider = AsyncNotifierProvider<EventsLog, List<Event>>(
  EventsLog.new,
  retry: (retryCount, error) => null,
);

/// Profile's count of the Ads watched this week.
final adsWatchedThisWeekProvider = Provider<int>(
  (ref) => adsWatchedThisWeek(
    ref.watch(eventsLogProvider).value ?? const [],
    ref.read(eventsClockProvider)(),
  ),
);

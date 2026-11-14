// The Events log (ticket #9): each Event recorded once with a unique ID and
// timestamp, buffered on the device across a restart, and the Profile's
// ad counter.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stafeed/app/features/events/data/events_storage.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/events/providers/events_provider.dart';

import '../../support/shopper.dart';

/// Storage whose writes fail while [error] is set, like a full disk.
class FlakyEventsStorage extends EventsStorage {
  Object? error;

  @override
  Future<void> save(List<Event> events) async {
    if (error case final error?) throw error;
    await super.save(events);
  }
}

void main() {
  setUp(useEmptyDeviceStorage);

  var now = DateTime.utc(2026, 11, 14, 12);

  ProviderContainer container({EventsStorage? storage}) {
    final container = ProviderContainer(
      overrides: [
        eventsClockProvider.overrideWithValue(() => now),
        if (storage != null) eventsStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> record(ProviderContainer app, NewEvent event) =>
      app.read(eventsLogProvider.notifier).record(event);

  test('each Event is recorded once, with a unique ID and its time', () async {
    final app = container();

    await record(app, const NewEvent(EventType.impression, feedItemId: 'a'));
    now = now.add(const Duration(seconds: 3));
    await record(app, const NewEvent(EventType.impression, feedItemId: 'a'));

    final events = app.read(eventsLogProvider).requireValue;
    expect(events, hasLength(2));
    expect(events.map((e) => e.id).toSet(), hasLength(2));
    expect(events.map((e) => e.occurredAt), [
      DateTime.utc(2026, 11, 14, 12),
      DateTime.utc(2026, 11, 14, 12, 0, 3),
    ]);
    for (final event in events) {
      expect(
        event.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });

  test('random Event IDs do not repeat', () {
    final ids = {for (var i = 0; i < 1000; i++) randomEventId()};
    expect(ids, hasLength(1000));
  });

  test('the buffer survives a restart, in order', () async {
    final first = container();
    await record(first, const NewEvent(EventType.impression, feedItemId: 'a'));
    await record(
      first,
      const NewEvent(
        EventType.skip,
        feedItemId: 'a',
        productId: 'a',
        offerId: 'a-1',
        isAd: true,
        dwell: Duration(milliseconds: 1500),
      ),
    );
    await record(
      first,
      const NewEvent(EventType.filterChange, details: {'category': 'bags'}),
    );
    final before = first.read(eventsLogProvider).requireValue;

    // A new app on the same device.
    final second = container();
    expect(await second.read(eventsLogProvider.future), before);
    expect(before.map((e) => e.type), [
      EventType.impression,
      EventType.skip,
      EventType.filterChange,
    ]);
  });

  test('Events recorded while the buffer is still loading are all kept, in '
      'order', () async {
    final first = container();
    await record(first, const NewEvent(EventType.impression, feedItemId: 'a'));

    final second = container();
    await Future.wait([
      record(second, const NewEvent(EventType.view2s, feedItemId: 'a')),
      record(second, const NewEvent(EventType.view5s, feedItemId: 'a')),
    ]);

    expect((await EventsStorage().load()).map((e) => e.type), [
      EventType.impression,
      EventType.view2s,
      EventType.view5s,
    ]);
  });

  test('a write the device refuses never throws, and is stored with the '
      'next Event', () async {
    final storage = FlakyEventsStorage()..error = Exception('disk full');
    final app = container(storage: storage);

    await record(app, const NewEvent(EventType.share, productId: 'a'));
    expect(app.read(eventsLogProvider).requireValue, hasLength(1));
    expect(await EventsStorage().load(), isEmpty);

    storage.error = null;
    await record(app, const NewEvent(EventType.save, productId: 'a'));
    expect((await EventsStorage().load()).map((e) => e.type), [
      EventType.share,
      EventType.save,
    ]);
  });

  test('an unreadable entry is skipped and the others are kept', () async {
    final app = container();
    await record(app, const NewEvent(EventType.impression, feedItemId: 'a'));
    final good = (await EventsStorage().load()).single;

    // Corrupt the buffer around the good entry.
    await SharedPreferencesAsync().setString(
      'events_buffer',
      jsonEncode([
        {'id': 3},
        good.toJson(),
        'nonsense',
        {'type': 'skip'},
      ]),
    );

    expect(await EventsStorage().load(), [good]);
  });

  group('ads watched this week', () {
    // Saturday 14 November 2026; the week began on Monday the 9th.
    final saturday = DateTime(2026, 11, 14, 18);

    Event impression(DateTime at, {bool isAd = true, String id = ''}) => Event(
      id: '${at.toIso8601String()}$id',
      type: EventType.impression,
      occurredAt: at.toUtc(),
      feedItemId: 'x',
      isAd: isAd,
    );

    test('counts Ad impressions since Monday 00:00, local time', () {
      final events = [
        impression(DateTime(2026, 11, 8, 23, 59)), // last Sunday
        impression(DateTime(2026, 11, 9)), // Monday, midnight
        impression(DateTime(2026, 11, 12, 9)),
        impression(DateTime(2026, 11, 14, 17)),
        impression(DateTime(2026, 11, 14, 17), id: 'again'),
      ];

      expect(adsWatchedThisWeek(events, saturday), 4);
    });

    test('ignores views, skips and Feed Items that are not Ads', () {
      final at = DateTime(2026, 11, 13, 10);
      final events = [
        impression(at, isAd: false),
        Event(
          id: 'v',
          type: EventType.view2s,
          occurredAt: at.toUtc(),
          isAd: true,
        ),
        Event(
          id: 's',
          type: EventType.skip,
          occurredAt: at.toUtc(),
          isAd: true,
        ),
      ];

      expect(adsWatchedThisWeek(events, saturday), 0);
    });

    test('on a Monday morning only counts that morning', () {
      final monday = DateTime(2026, 11, 16, 8);
      final events = [
        impression(DateTime(2026, 11, 15, 22)),
        impression(DateTime(2026, 11, 16, 7)),
      ];

      expect(adsWatchedThisWeek(events, monday), 1);
    });

    test('the Profile line says it', () {
      expect(
        adsWatchedLine(12),
        "You've watched 12 ads this week. Advertisers thank you.",
      );
      expect(
        adsWatchedLine(0),
        "You've watched 0 ads this week. Advertisers thank you.",
      );
      expect(
        adsWatchedLine(1),
        "You've watched 1 ad this week. Advertisers thank you.",
      );
    });

    test('the provider counts the recorded impressions', () async {
      now = DateTime.utc(2026, 11, 14, 12);
      final app = container();
      expect(app.read(adsWatchedThisWeekProvider), 0);

      await record(
        app,
        const NewEvent(EventType.impression, feedItemId: 'a', isAd: true),
      );
      await record(
        app,
        const NewEvent(EventType.view2s, feedItemId: 'a', isAd: true),
      );

      expect(app.read(adsWatchedThisWeekProvider), 1);
    });
  });
}

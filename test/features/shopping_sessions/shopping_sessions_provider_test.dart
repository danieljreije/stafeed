import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/events/providers/events_provider.dart';
import 'package:stafeed/app/features/feed/data/data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_state.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/providers/feed_provider.dart';
import 'package:stafeed/app/features/ranking/shopper_taste.dart';
import 'package:stafeed/app/features/shopping_sessions/providers/shopping_sessions_provider.dart';

import '../feed/support/scripted_data_gateway.dart';

ProviderContainer newContainer({DataGateway? gateway}) {
  final container = ProviderContainer(
    overrides: [
      if (gateway != null) dataGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

ShoppingSessionsNotifier sessionsOf(ProviderContainer container) =>
    container.read(shoppingSessionsProvider.notifier);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('Shopping Sessions are kept on the device', () {
    test(
      'create, rename, change, reset and delete survive a restart',
      () async {
        var container = newContainer();
        final sneakers = await sessionsOf(container).create(
          goal: 'white sneakers',
          category: 'sneakers',
          maxPrice: const Money(15000, 'USD'),
        );
        final lamps = await sessionsOf(container).create(goal: 'lamp');
        await sessionsOf(container).rename(sneakers.id, 'Summer kicks');
        await sessionsOf(container).changeFilters(
          sneakers.id,
          goal: 'white sneakers',
          category: 'sneakers',
          brand: 'Northstar',
          maxPrice: const Money(20000, 'USD'),
        );
        await sessionsOf(container).delete(lamps.id);

        // A restart reads them back.
        container = newContainer();
        final stored = await container.read(shoppingSessionsProvider.future);
        expect(stored.sessions, hasLength(1));
        final kept = stored.sessions.single;
        expect(kept.id, sneakers.id);
        expect(kept.name, 'Summer kicks');
        expect(kept.goal, 'white sneakers');
        expect(kept.brand, 'Northstar');
        expect(kept.maxPrice?.minorUnits, 20000);

        // Reset keeps the name and filters but starts a fresh taste.
        await sessionsOf(container).reset(kept.id);
        container = newContainer();
        final afterReset = (await container.read(
          shoppingSessionsProvider.future,
        )).sessions.single;
        expect(afterReset.id, isNot(kept.id));
        expect(afterReset.name, 'Summer kicks');
        expect(afterReset.maxPrice?.minorUnits, 20000);
      },
    );

    test(
      'several are kept, one is active, and it survives a restart',
      () async {
        var container = newContainer();
        final first = await sessionsOf(container).create(goal: 'watch');
        final second = await sessionsOf(container).create(goal: 'bag');
        expect(container.read(activeShoppingSessionProvider)?.id, second.id);

        await sessionsOf(container).start(first.id);
        container = newContainer();
        await container.read(shoppingSessionsProvider.future);
        expect(container.read(activeShoppingSessionProvider)?.id, first.id);
        expect(
          container.read(shoppingSessionsProvider).value!.sessions,
          hasLength(2),
        );

        await sessionsOf(container).end();
        expect(container.read(activeShoppingSessionProvider), isNull);
      },
    );

    test('deleting the active session goes back to For You', () async {
      final container = newContainer();
      final session = await sessionsOf(container).create(goal: 'watch');

      await sessionsOf(container).delete(session.id);

      expect(container.read(activeShoppingSessionProvider), isNull);
    });

    test('a session without a name is named after its goal', () async {
      final container = newContainer();

      final session = await sessionsOf(container)
          .create(goal: '  white sneakers ');

      expect(session.name, 'white sneakers');
    });
  });

  group('session activity', () {
    test('is recorded in the active session and never feeds For You', () async {
      final container = newContainer();
      final events = container.read(eventsLogProvider.notifier);
      await container.read(eventsLogProvider.future);

      await events.record(const NewEvent(EventType.save, productId: 'p1'));
      final session = await sessionsOf(container).create(goal: 'watch');
      await events.record(const NewEvent(EventType.save, productId: 'p2'));
      await sessionsOf(container).end();
      await events.record(const NewEvent(EventType.save, productId: 'p3'));

      final recorded = container.read(eventsLogProvider).value!;
      expect(longTermSignals(recorded).map((signal) => signal.productId), [
        'p1',
        'p3',
      ]);
      expect(
        sessionSignals(recorded)[session.id]!.map((signal) => signal.productId),
        ['p2'],
      );
      expect(
        recorded.map((event) => event.type),
        containsAllInOrder([EventType.sessionStart, EventType.sessionEnd]),
      );
    });
  });

  group('the feed', () {
    test('switches to the active session and back to For You', () async {
      final gateway = ScriptedDataGateway();
      final container = newContainer(gateway: gateway);
      container.listen(feedProvider, (_, _) {});

      expect(gateway.requests.last.filter.isSession, isFalse);

      final session = await sessionsOf(container)
          .create(goal: 'watch', category: 'watches');
      await pumpEventQueue();
      expect(gateway.requests.last.filter.sessionId, session.id);
      expect(gateway.requests.last.filter.query, 'watch');

      await sessionsOf(container).end();
      await pumpEventQueue();
      expect(gateway.requests.last.filter.isSession, isFalse);
    });

    test('a filter change restarts the session feed and drops the stale '
        'page', () async {
      final gateway = ScriptedDataGateway();
      final container = newContainer(gateway: gateway);
      container.listen(feedProvider, (_, _) {});
      final session = await sessionsOf(container).create(goal: 'watch');
      await pumpEventQueue();
      final stale = gateway.requests.last;

      await sessionsOf(container).changeFilters(
        session.id,
        goal: 'watch',
        maxPrice: const Money(9000, 'USD'),
      );
      await pumpEventQueue();
      final fresh = gateway.requests.last;
      expect(fresh, isNot(same(stale)));
      expect(fresh.filter.maxPrice?.minorUnits, 9000);
      expect(container.read(feedProvider).phase, FeedPhase.loading);

      // The old page arrives late: it must not show.
      stale.succeed([feedItem('old')]);
      await pumpEventQueue();
      expect(container.read(feedProvider).phase, FeedPhase.loading);

      fresh.succeed([feedItem('new')]);
      await pumpEventQueue();
      expect(container.read(feedProvider).items.map((item) => item.id), [
        'new',
      ]);
    });

    test('renaming a session doesn\'t reload its feed', () async {
      final gateway = ScriptedDataGateway();
      final container = newContainer(gateway: gateway);
      container.listen(feedProvider, (_, _) {});
      final session = await sessionsOf(container).create(goal: 'watch');
      await pumpEventQueue();
      final asked = gateway.requests.length;

      await sessionsOf(container).rename(session.id, 'Gift');
      await pumpEventQueue();

      expect(gateway.requests, hasLength(asked));
    });
  });
}

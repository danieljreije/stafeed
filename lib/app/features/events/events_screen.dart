import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/event.dart';
import 'providers/events_provider.dart';

/// A debug screen, opened from Profile, listing the recent Events kept on
/// this phone, newest first, so tracking can be checked by hand.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  /// How many of the newest Events are listed.
  static const int shown = 200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: switch (events) {
        AsyncData(:final value) when value.isEmpty => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No Events yet. Swipe the feed and they show up here.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${value.length} '
                '${value.length == 1 ? 'Event' : 'Events'} '
                'kept on this phone, waiting to be sent.',
              ),
            ),
            for (final event in value.reversed.take(shown)) _EventTile(event),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile(this.event);

  final Event event;

  @override
  Widget build(BuildContext context) {
    final time = event.occurredAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    final when =
        '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';

    final about = [
      if (event.feedItemId != null) 'Feed Item ${event.feedItemId}',
      if (event.productId != null && event.productId != event.feedItemId)
        'Product ${event.productId}',
      if (event.offerId != null) 'Offer ${event.offerId}',
      if (event.isAd != null) event.isAd! ? 'Ad' : 'Not an Ad',
      if (event.dwell != null)
        '${(event.dwell!.inMilliseconds / 1000).toStringAsFixed(1)} s',
      for (final entry in event.details.entries) '${entry.key}: ${entry.value}',
    ].join(' · ');

    return ListTile(
      dense: true,
      title: Text(event.type.label),
      subtitle: Text([when, if (about.isNotEmpty) about, event.id].join('\n')),
      isThreeLine: true,
    );
  }
}

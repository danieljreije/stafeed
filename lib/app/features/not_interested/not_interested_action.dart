import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/models/event.dart';
import '../events/providers/events_provider.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../feed/providers/feed_provider.dart';
import 'providers/not_interested_provider.dart';

/// What the Shopper is told after marking a Product Not interested.
const notInterestedMessage = "Got it. You won't see that one again.";

/// What the Shopper is told when the device wouldn't keep it.
const notInterestedWriteFailedMessage =
    "Hidden for now, but we couldn't remember it for next time.";

/// Marks [productId] Not interested: it leaves the feed at once and never
/// comes back, and its Brand and category rank lower in For You. Records a
/// Not interested Event, keeps the mark on the device and tells the data
/// gateway.
Future<void> markNotInterested(
  BuildContext context,
  WidgetRef ref,
  String productId, {
  String? offerId,
  String? feedItemId,
  bool? isAd,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final gateway = ref.read(dataGatewayProvider);

  // The Event first: it is what lowers the Brand and category in the pages
  // still to come.
  final recorded = ref
      .read(eventsLogProvider.notifier)
      .record(
        NewEvent(
          EventType.notInterested,
          feedItemId: feedItemId,
          productId: productId,
          offerId: offerId,
          isAd: isAd,
        ),
      );
  ref.read(feedProvider.notifier).hideProduct(productId);
  unawaited(gateway.markNotInterested(productId).catchError((Object _) {}));

  var stored = true;
  try {
    await ref.read(notInterestedProvider.notifier).mark(productId);
  } on NotInterestedWriteException {
    stored = false;
  }
  await recorded;

  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          stored ? notInterestedMessage : notInterestedWriteFailedMessage,
        ),
      ),
    );
}

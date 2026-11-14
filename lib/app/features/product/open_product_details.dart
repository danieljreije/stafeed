import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../events/models/event.dart';
import '../events/providers/events_provider.dart';

/// Opens a Product's details, on [offerId] when given, and records a detail
/// open. [feedItemId] is the Feed Item it was opened from, if any.
void openProductDetails(
  BuildContext context,
  WidgetRef ref,
  String productId, {
  String? offerId,
  String? feedItemId,
}) {
  unawaited(
    ref
        .read(eventsLogProvider.notifier)
        .record(
          NewEvent(
            EventType.detailOpen,
            feedItemId: feedItemId,
            productId: productId,
            offerId: offerId,
          ),
        ),
  );
  context.push(AppRoutes.productDetails(productId, offerId: offerId));
}

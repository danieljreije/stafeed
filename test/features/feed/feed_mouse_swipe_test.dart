import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/stafeed_scroll_behavior.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // On the web, people try Stafeed on a computer: dragging with a mouse
  // has to move through the feed like a finger does.
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('dragging up with a ${kind.name} moves past the first Feed '
        'Item', (tester) async {
      final page = await FixtureDataGateway().getFeedPage();
      final first = page.items.first as AffiliateAd;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            scrollBehavior: StafeedScrollBehavior(),
            home: FeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(first.product.title), findsOneWidget);

      await tester.drag(
        find.byType(PageView).first,
        const Offset(0, -400),
        kind: kind,
      );
      await tester.pumpAndSettle();

      expect(find.text(first.product.title), findsNothing);
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/providers/feed_provider.dart';

import '../support/scripted_data_gateway.dart';

/// Not interested takes a Product out of the feed that is open (#10).
void main() {
  late ScriptedDataGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = ScriptedDataGateway();
    container = ProviderContainer(
      overrides: [dataGatewayProvider.overrideWithValue(gateway)],
    );
    addTearDown(container.dispose);
    container.listen(feedProvider, (_, _) {});
  });

  List<String> ids() => [
    for (final item in container.read(feedProvider).items) item.id,
  ];
  FeedNotifier controller() => container.read(feedProvider.notifier);

  test('the hidden Product leaves the loaded Feed Items; the rest stay in '
      'place, with the cursor', () async {
    container.read(feedProvider);
    gateway.requests.last.succeed(feedItems(['a', 'b', 'c']), next: 'p2');
    await pumpEventQueue();

    controller().hideProduct('b');

    expect(ids(), ['a', 'c']);
    expect(container.read(feedProvider).nextCursor?.token, 'p2');
  });

  test('hiding the last Feed Items loaded fetches the next page instead of '
      'saying nothing matched', () async {
    container.read(feedProvider);
    gateway.requests.last.succeed(feedItems(['a']), next: 'p2');
    await pumpEventQueue();

    controller().hideProduct('a');

    expect(container.read(feedProvider).isEmpty, isFalse);
    expect(gateway.requests.last.cursor?.token, 'p2');
    gateway.requests.last.succeed(feedItems(['b']));
    await pumpEventQueue();
    expect(ids(), ['b']);
  });

  test('a page already on its way arrives without it', () async {
    container.read(feedProvider);
    gateway.requests.last.succeed(feedItems(['a', 'b']), next: 'p2');
    await pumpEventQueue();
    final loadMore = controller().loadMore();

    controller().hideProduct('d');
    gateway.requests.last.succeed(feedItems(['c', 'd', 'e']));
    await loadMore;

    expect(ids(), ['a', 'b', 'c', 'e']);
  });

  test('a Brand Ad loses the hidden Product from its chips, and goes when '
      'none is left', () async {
    final kept = BrandAd(
      id: 'ad-1',
      brand: 'Brand',
      headline: 'Two Products',
      media: const [],
      products: [sampleProduct('x'), sampleProduct('y')],
    );
    final gone = BrandAd(
      id: 'ad-2',
      brand: 'Brand',
      headline: 'One Product',
      media: const [],
      products: [sampleProduct('x')],
    );
    container.read(feedProvider);
    gateway.requests.last.succeed([kept, gone]);
    await pumpEventQueue();

    controller().hideProduct('x');

    final items = container.read(feedProvider).items;
    expect(items.map((i) => i.id), ['ad-1']);
    expect(items.single.products.map((p) => p.id), ['y']);
  });
}

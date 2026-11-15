import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/events/models/event.dart';
import 'package:stafeed/app/features/ranking/ranking.dart';
import 'package:stafeed/app/features/ranking/ranking_config.dart';
import 'package:stafeed/app/features/ranking/shopper_taste.dart';

void main() {
  const product = RankedProduct(
    id: 'p',
    title: 'Air Runner',
    brand: 'Northstar',
    category: 'sneakers',
    priceMinor: 12000,
  );

  Affinities of(List<SignalType> types) => Affinities.fromSignals([
    for (final type in types) TasteSignal(type, product),
  ], defaultRankingConfig);

  test('each signal adds its weight to the Brand, category and price band', () {
    final taste = of([SignalType.save, SignalType.notInterested]);

    expect(taste.category('sneakers'), -1);
    expect(taste.brand('Northstar'), -1);
    expect(taste.priceBand('1'), -1);
    expect(taste.category('bags'), 0);
  });

  test('a 2s view followed by a 5s view counts as one 5s view, not both', () {
    expect(of([SignalType.view2s, SignalType.view5s]).category('sneakers'), 1);
  });

  test('only Events about a Product, outside any Shopping Session, that say '
      'something about taste become signals', () {
    Event event(EventType type, {String? productId, String? sessionId}) =>
        Event(
          id: '$type$productId$sessionId',
          type: type,
          occurredAt: DateTime.utc(2026, 11, 14),
          productId: productId,
          sessionId: sessionId,
        );

    final signals = longTermSignals([
      event(EventType.save, productId: 'a'),
      event(EventType.impression, productId: 'a'),
      event(EventType.unsave, productId: 'a'),
      event(EventType.fastSkip),
      event(EventType.detailOpen, productId: 'b', sessionId: 's1'),
      event(EventType.notInterested, productId: 'c'),
    ]);

    expect(
      [for (final s in signals) '${s.type.jsonName}:${s.productId}'],
      ['save:a', 'not_interested:c'],
    );
  });
}

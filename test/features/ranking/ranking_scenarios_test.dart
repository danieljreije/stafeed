import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/ranking/ranking.dart';
import 'package:stafeed/app/features/ranking/ranking_config.dart';

/// Runs the shared, language-neutral ranking scenarios (also run by the
/// backend's TypeScript ranking, #15) against the Dart ranking.
void main() {
  final configJson = jsonDecode(
    File('shared/ranking/ranking_config.json').readAsStringSync(),
  );
  final scenariosJson = jsonDecode(
    File('shared/ranking/scenarios.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the app ranks with the weights in the shared config file', () {
    expect(RankingConfig.fromJson(configJson), defaultRankingConfig);
  });

  final config = RankingConfig.fromJson(configJson);

  for (final scenario in scenariosJson['scenarios'] as List) {
    final json = scenario as Map<String, dynamic>;

    test(json['name'], () {
      final input = rankingInputFromScenario(json);
      final ranked = rank(input, config);
      final expected = json['expected'] as Map<String, dynamic>;

      expect(
        ranked.map((candidate) => candidate.id).toList(),
        (expected['order'] as List).cast<String>(),
      );

      final linked = expected['linked_products'] as Map<String, dynamic>?;
      for (final entry in (linked ?? const {}).entries) {
        final candidate = ranked.firstWhere((c) => c.id == entry.key);
        expect(
          candidate.products.map((product) => product.id).toList(),
          (entry.value as List).cast<String>(),
          reason: entry.key,
        );
      }
    });
  }
}

/// Reads one scenario of `shared/ranking/scenarios.json` (its format is
/// described in `shared/ranking/README.md`).
RankingInput rankingInputFromScenario(Map<String, dynamic> json) {
  final products = {
    for (final entry in (json['products'] as Map<String, dynamic>).entries)
      entry.key: _product(entry.key, entry.value as Map<String, dynamic>),
  };

  List<TasteSignal> signals(Object? list) => [
    for (final signal in (list as List?) ?? const [])
      TasteSignal(
        SignalType.fromName((signal as Map)['signal'] as String),
        products[signal['product']]!,
      ),
  ];

  final session = json['session'] as Map<String, dynamic>?;

  return RankingInput(
    feed: json['feed'] == 'session' ? RankedFeed.session : RankedFeed.forYou,
    candidates: [
      for (final candidate in json['candidates'] as List)
        _candidate(candidate as Map<String, dynamic>, products),
    ],
    destinationCountry: json['destination_country'] as String?,
    interests: {...?(json['interests'] as List?)?.cast<String>()},
    longTermSignals: signals(json['long_term_signals']),
    session: session == null
        ? null
        : SessionGoal(
            query: session['query'] as String? ?? '',
            category: session['category'] as String?,
            signals: signals(session['signals']),
          ),
    recentlyShown: {...?(json['recently_shown'] as List?)?.cast<String>()},
    notInterested: {...?(json['not_interested'] as List?)?.cast<String>()},
    previousBrand: json['previous_brand'] as String?,
  );
}

RankedProduct _product(String id, Map<String, dynamic> json) => RankedProduct(
  id: id,
  title: json['title'] as String,
  brand: json['brand'] as String,
  category: json['category'] as String,
  priceMinor: json['price_minor'] as int?,
);

RankingCandidate _candidate(
  Map<String, dynamic> json,
  Map<String, RankedProduct> products,
) {
  final kind = CandidateKind.fromName(json['kind'] as String);
  final linked = kind == CandidateKind.brandAd
      ? [for (final id in json['products'] as List) products[id]!]
      : [products[json['product']]!];

  return RankingCandidate(
    id: json['id'] as String,
    kind: kind,
    brand: json['brand'] as String? ?? linked.first.brand,
    products: linked,
    relevance: (json['relevance'] as num?)?.toDouble() ?? 0,
    quality: (json['quality'] as num?)?.toDouble() ?? 0,
    freshness: (json['freshness'] as num?)?.toDouble() ?? 0,
    isAvailable: json['available'] as bool? ?? true,
    shipsTo: (json['ships_to'] as List?)?.cast<String>().toSet(),
  );
}

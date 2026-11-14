import 'package:flutter/foundation.dart';

/// How much each part of a Feed Item's score counts. The defaults are the
/// product spec's starting weights. (The spec's 5% exploration is not a
/// score: see [RankingConfig.explorationShare].)
@immutable
class ScoreWeights {
  const ScoreWeights({
    required this.sourceRelevance,
    required this.intentMatch,
    required this.sessionAffinity,
    required this.longTermAffinity,
    required this.quality,
    required this.freshness,
  });

  final double sourceRelevance;
  final double intentMatch;
  final double sessionAffinity;
  final double longTermAffinity;
  final double quality;
  final double freshness;

  factory ScoreWeights.fromJson(Map<String, dynamic> json) => ScoreWeights(
    sourceRelevance: _number(json, 'source_relevance'),
    intentMatch: _number(json, 'intent_match'),
    sessionAffinity: _number(json, 'session_affinity'),
    longTermAffinity: _number(json, 'long_term_affinity'),
    quality: _number(json, 'quality'),
    freshness: _number(json, 'freshness'),
  );

  @override
  bool operator ==(Object other) =>
      other is ScoreWeights &&
      other.sourceRelevance == sourceRelevance &&
      other.intentMatch == intentMatch &&
      other.sessionAffinity == sessionAffinity &&
      other.longTermAffinity == longTermAffinity &&
      other.quality == quality &&
      other.freshness == freshness;

  @override
  int get hashCode => Object.hash(
    sourceRelevance,
    intentMatch,
    sessionAffinity,
    longTermAffinity,
    quality,
    freshness,
  );
}

/// What each Shopper signal adds to (or takes from) the affinity of the
/// Product's Brand, category and price band.
@immutable
class SignalWeights {
  const SignalWeights({
    required this.notInterested,
    required this.fastSkip,
    required this.skip,
    required this.view2s,
    required this.view5s,
    required this.details,
    required this.share,
    required this.save,
    required this.outboundClick,
  });

  final double notInterested;
  final double fastSkip;
  final double skip;
  final double view2s;

  /// A 5s view in all. It always comes after a 2s view of the same Feed
  /// Item, so on its own it only adds the difference.
  final double view5s;
  final double details;
  final double share;
  final double save;
  final double outboundClick;

  factory SignalWeights.fromJson(Map<String, dynamic> json) => SignalWeights(
    notInterested: _number(json, 'not_interested'),
    fastSkip: _number(json, 'fast_skip'),
    skip: _number(json, 'skip'),
    view2s: _number(json, 'view_2s'),
    view5s: _number(json, 'view_5s'),
    details: _number(json, 'details'),
    share: _number(json, 'share'),
    save: _number(json, 'save'),
    outboundClick: _number(json, 'outbound_click'),
  );

  @override
  bool operator ==(Object other) =>
      other is SignalWeights &&
      other.notInterested == notInterested &&
      other.fastSkip == fastSkip &&
      other.skip == skip &&
      other.view2s == view2s &&
      other.view5s == view5s &&
      other.details == details &&
      other.share == share &&
      other.save == save &&
      other.outboundClick == outboundClick;

  @override
  int get hashCode => Object.hash(
    notInterested,
    fastSkip,
    skip,
    view2s,
    view5s,
    details,
    share,
    save,
    outboundClick,
  );
}

/// Every tunable number of the ranking. The same values live in
/// `shared/ranking/ranking_config.json`, which the backend's ranking reads;
/// a test keeps the two equal.
@immutable
class RankingConfig {
  const RankingConfig({
    required this.scoreWeights,
    required this.signalWeights,
    required this.affinitySaturation,
    required this.paidAdNearTieBonus,
    required this.explorationShare,
    required this.priceBandEdgesMinor,
  });

  final ScoreWeights scoreWeights;
  final SignalWeights signalWeights;

  /// How quickly an affinity approaches its limit: a summed affinity `a`
  /// counts as `a / (|a| + affinitySaturation)`, between -1 and 1.
  final double affinitySaturation;

  /// Added to the score of every paid Ad, so it wins near-ties against Not
  /// an Ad. Never depends on how much an Ad pays.
  final double paidAdNearTieBonus;

  /// The share of the feed kept for exploration: every `round(1 / share)`th
  /// Feed Item, counted from the top of the feed, is the best one whose
  /// Brand and category the Shopper's taste knows nothing about yet (when
  /// there is one). A bonus in the score would instead make a liked Brand
  /// rank below one never seen.
  final double explorationShare;

  /// Prices (in minor units) where one price band ends and the next
  /// begins.
  final List<int> priceBandEdgesMinor;

  factory RankingConfig.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return RankingConfig(
      scoreWeights: ScoreWeights.fromJson(
        map['score_weights'] as Map<String, dynamic>,
      ),
      signalWeights: SignalWeights.fromJson(
        map['signal_weights'] as Map<String, dynamic>,
      ),
      affinitySaturation: _number(map, 'affinity_saturation'),
      paidAdNearTieBonus: _number(map, 'paid_ad_near_tie_bonus'),
      explorationShare: _number(map, 'exploration_share'),
      priceBandEdgesMinor: [
        for (final edge in map['price_band_edges_minor'] as List) edge as int,
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RankingConfig &&
      other.scoreWeights == scoreWeights &&
      other.signalWeights == signalWeights &&
      other.affinitySaturation == affinitySaturation &&
      other.paidAdNearTieBonus == paidAdNearTieBonus &&
      other.explorationShare == explorationShare &&
      listEquals(other.priceBandEdgesMinor, priceBandEdgesMinor);

  @override
  int get hashCode => Object.hash(
    scoreWeights,
    signalWeights,
    affinitySaturation,
    paidAdNearTieBonus,
    explorationShare,
    Object.hashAll(priceBandEdgesMinor),
  );
}

/// The weights the app ranks with. Change them here and in
/// `shared/ranking/ranking_config.json` together.
const defaultRankingConfig = RankingConfig(
  scoreWeights: ScoreWeights(
    sourceRelevance: 0.40,
    intentMatch: 0.20,
    sessionAffinity: 0.15,
    longTermAffinity: 0.10,
    quality: 0.05,
    freshness: 0.05,
  ),
  signalWeights: SignalWeights(
    notInterested: -5,
    fastSkip: -2,
    skip: -1,
    view2s: 0.5,
    view5s: 1,
    details: 2,
    share: 3,
    save: 4,
    outboundClick: 5,
  ),
  affinitySaturation: 5,
  paidAdNearTieBonus: 0.02,
  explorationShare: 0.05,
  priceBandEdgesMinor: [5000, 15000, 30000],
);

double _number(Map<String, dynamic> json, String key) =>
    (json[key] as num).toDouble();

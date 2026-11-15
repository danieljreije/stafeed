/// The ranking (spec Seam 3): a pure function that orders candidate Feed
/// Items for one feed, from the Shopper's long-term taste, the active
/// Shopping Session's taste, what was already shown and the Not interested
/// set.
///
/// It knows nothing about screens, storage or sources. The same rules are
/// written in TypeScript for the backend (#15); both pass the shared
/// scenarios in `shared/ranking/scenarios.json`.
library;

import 'ranking_config.dart';

/// The two kinds of feed.
enum RankedFeed {
  /// The permanent default feed: only Ads, ranked by long-term taste.
  forYou,

  /// A Shopping Session's feed: ranked by its goal and its own taste.
  session,
}

/// What a candidate Feed Item is, as far as ranking cares.
enum CandidateKind {
  affiliateAd('affiliate_ad'),
  brandAd('brand_ad'),
  notAnAd('not_an_ad');

  const CandidateKind(this.jsonName);

  /// Its name in the shared scenario file.
  final String jsonName;

  /// Whether it earns Stafeed money.
  bool get isAd => this != notAnAd;

  static CandidateKind fromName(String name) =>
      values.firstWhere((kind) => kind.jsonName == name);
}

/// What the ranking needs to know about a Product.
class RankedProduct {
  const RankedProduct({
    required this.id,
    required this.title,
    required this.brand,
    required this.category,
    this.priceMinor,
  });

  final String id;
  final String title;
  final String brand;
  final String category;

  /// The price of the Offer shown, in minor units. Null when unknown.
  final int? priceMinor;
}

/// One Feed Item the ranking may place.
class RankingCandidate {
  const RankingCandidate({
    required this.id,
    required this.kind,
    required this.brand,
    required this.products,
    this.relevance = 0,
    this.quality = 0,
    this.freshness = 0,
    this.isAvailable = true,
    this.shipsTo,
  });

  /// The Feed Item's ID. For an Affiliate Ad or Not an Ad it is the
  /// Product's ID.
  final String id;
  final CandidateKind kind;

  /// The Brand shown: a Brand Ad's own Brand, or the Product's.
  final String brand;

  /// The Product shown, or the Products a Brand Ad links to.
  final List<RankedProduct> products;

  /// How well the source thinks it fits, from 0 to 1.
  final double relevance;

  /// Quality or popularity, from 0 to 1.
  final double quality;

  /// How new it is, from 0 to 1.
  final double freshness;

  /// False when its Offer is out of stock.
  final bool isAvailable;

  /// Countries its Offer ships to. Null means everywhere.
  final Set<String>? shipsTo;

  RankingCandidate _withProducts(List<RankedProduct> linked) =>
      RankingCandidate(
        id: id,
        kind: kind,
        brand: brand,
        products: linked,
        relevance: relevance,
        quality: quality,
        freshness: freshness,
        isAvailable: isAvailable,
        shipsTo: shipsTo,
      );
}

/// A Shopper action that tells the ranking something about their taste.
enum SignalType {
  notInterested('not_interested'),
  fastSkip('fast_skip'),
  skip('skip'),
  view2s('view_2s'),
  view5s('view_5s'),
  details('details'),
  share('share'),
  save('save'),
  outboundClick('outbound_click');

  const SignalType(this.jsonName);

  /// Its name in the shared config and scenario files.
  final String jsonName;

  static SignalType fromName(String name) =>
      values.firstWhere((type) => type.jsonName == name);
}

/// One signal about one Product.
class TasteSignal {
  const TasteSignal(this.type, this.product);

  final SignalType type;
  final RankedProduct product;
}

/// A Shopping Session as the ranking sees it: its goal and its own taste.
class SessionGoal {
  const SessionGoal({this.query = '', this.category, this.signals = const []});

  /// The goal the Shopper typed, e.g. "white sneakers".
  final String query;

  /// The category filter, if any.
  final String? category;

  /// What the Shopper did inside this session. Never used for For You.
  final List<TasteSignal> signals;
}

/// Everything one ranking call looks at.
class RankingInput {
  const RankingInput({
    required this.feed,
    required this.candidates,
    this.destinationCountry,
    this.interests = const {},
    this.longTermSignals = const [],
    this.session,
    this.recentlyShown = const {},
    this.notInterested = const {},
    this.previousBrand,
  });

  final RankedFeed feed;

  /// In the source's order, best first.
  final List<RankingCandidate> candidates;

  /// Candidates whose Offer doesn't ship here are left out. Null keeps all.
  final String? destinationCountry;

  /// Categories the Shopper picked at onboarding.
  final Set<String> interests;

  /// What the Shopper did in For You (never inside a Shopping Session).
  final List<TasteSignal> longTermSignals;

  /// The active Shopping Session. Ignored for For You.
  final SessionGoal? session;

  /// Feed Item IDs already shown in this feed; never shown again.
  final Set<String> recentlyShown;

  /// Product IDs the Shopper marked Not interested; never shown again.
  final Set<String> notInterested;

  /// The Brand of the Feed Item shown just before this page, so the Brand
  /// rule holds across pages.
  final String? previousBrand;
}

/// Summed signal weights per category, Brand and price band.
class Affinities {
  Affinities._(this._category, this._brand, this._priceBand);

  /// Adds up [signals] with the weights in [config].
  factory Affinities.fromSignals(
    Iterable<TasteSignal> signals,
    RankingConfig config,
  ) {
    final category = <String, double>{};
    final brand = <String, double>{};
    final priceBand = <String, double>{};

    for (final signal in signals) {
      final weight = _weight(signal.type, config.signalWeights);
      if (weight == 0) continue;
      final product = signal.product;
      category.update(
        product.category,
        (a) => a + weight,
        ifAbsent: () => weight,
      );
      brand.update(product.brand, (a) => a + weight, ifAbsent: () => weight);
      final band = _priceBandOf(product, config);
      if (band != null) {
        priceBand.update(band, (a) => a + weight, ifAbsent: () => weight);
      }
    }
    return Affinities._(category, brand, priceBand);
  }

  final Map<String, double> _category;
  final Map<String, double> _brand;
  final Map<String, double> _priceBand;

  double category(String id) => _category[id] ?? 0;
  double brand(String name) => _brand[name] ?? 0;
  double priceBand(String band) => _priceBand[band] ?? 0;

  static double _weight(SignalType type, SignalWeights weights) =>
      switch (type) {
        SignalType.notInterested => weights.notInterested,
        SignalType.fastSkip => weights.fastSkip,
        SignalType.skip => weights.skip,
        SignalType.view2s => weights.view2s,
        // Always preceded by a 2s view of the same Feed Item: only the
        // difference is added, so the two together count as one 5s view.
        SignalType.view5s => weights.view5s - weights.view2s,
        SignalType.details => weights.details,
        SignalType.share => weights.share,
        SignalType.save => weights.save,
        SignalType.outboundClick => weights.outboundClick,
      };
}

/// The price band of [product]'s price: "0" below the first edge, "1"
/// below the second, and so on. Null when the price is unknown.
String? _priceBandOf(RankedProduct product, RankingConfig config) {
  final price = product.priceMinor;
  if (price == null) return null;
  var band = 0;
  for (final edge in config.priceBandEdgesMinor) {
    if (price < edge) break;
    band++;
  }
  return '$band';
}

/// The candidates of [input] that may be shown, best first.
///
/// 1. Retrieval leaves out what is out of stock, doesn't ship to the
///    Destination Country, was already shown, or is Not interested (a Brand
///    Ad loses those linked Products, and goes when none is left). For You
///    only takes Ads; in a Shopping Session a Brand Ad stays only when one
///    of its Products matches the goal.
/// 2. Each candidate is scored with the weighted mix in [config].
/// 3. Best score first (the source's order breaks ties), with two rules:
///    never the same Brand twice in a row while another Brand is left, and
///    every exploration slot (see [RankingConfig.explorationShare]) goes to
///    the best novel candidate: one whose Brand and category the Shopper's
///    taste knows nothing about.
List<RankingCandidate> rank(RankingInput input, RankingConfig config) {
  final inSession = input.feed == RankedFeed.session;
  final session = inSession ? input.session : null;

  final eligible = <RankingCandidate>[];
  for (final candidate in input.candidates) {
    final kept = _retrieve(candidate, input, session, inSession);
    if (kept != null) eligible.add(kept);
  }

  final longTerm = Affinities.fromSignals(input.longTermSignals, config);
  final sessionTaste = session == null
      ? null
      : Affinities.fromSignals(session.signals, config);
  final tastes = [longTerm, ?sessionTaste];

  final scores = [
    for (final candidate in eligible)
      _score(candidate, input, session, longTerm, sessionTaste, config),
  ];
  final order = List.generate(eligible.length, (i) => i)
    ..sort((a, b) {
      final byScore = scores[b].compareTo(scores[a]);
      return byScore != 0 ? byScore : a.compareTo(b);
    });

  return _arrange(
    [for (final i in order) eligible[i]],
    previousBrand: input.previousBrand,
    shownBefore: input.recentlyShown.length,
    isNovel: (candidate) => _isNovel(candidate, tastes),
    config: config,
  );
}

RankingCandidate? _retrieve(
  RankingCandidate candidate,
  RankingInput input,
  SessionGoal? session,
  bool inSession,
) {
  if (!candidate.isAvailable) return null;
  final country = input.destinationCountry;
  final shipsTo = candidate.shipsTo;
  if (country != null && shipsTo != null && !shipsTo.contains(country)) {
    return null;
  }
  if (input.recentlyShown.contains(candidate.id)) return null;
  if (!inSession && !candidate.kind.isAd) return null;

  if (candidate.kind != CandidateKind.brandAd) {
    final product = candidate.products.first;
    if (input.notInterested.contains(product.id)) return null;
    return candidate;
  }

  final linked = [
    for (final product in candidate.products)
      if (!input.notInterested.contains(product.id)) product,
  ];
  // Gone when Not interested took every Product it had.
  if (linked.isEmpty && candidate.products.isNotEmpty) return null;
  if (inSession && !linked.any((p) => _matchesGoal(p, session))) return null;

  return linked.length == candidate.products.length
      ? candidate
      : candidate._withProducts(linked);
}

double _score(
  RankingCandidate candidate,
  RankingInput input,
  SessionGoal? session,
  Affinities longTerm,
  Affinities? sessionTaste,
  RankingConfig config,
) {
  final weights = config.scoreWeights;
  final products = candidate.products;

  final intent = switch (input.feed) {
    RankedFeed.forYou =>
      products.any((p) => input.interests.contains(p.category)) ? 1.0 : 0.0,
    RankedFeed.session =>
      _hasGoal(session) && products.any((p) => _matchesGoal(p, session))
          ? 1.0
          : 0.0,
  };

  var score =
      weights.sourceRelevance * candidate.relevance +
      weights.intentMatch * intent +
      weights.longTermAffinity * _affinity(products, longTerm, config) +
      weights.quality * candidate.quality +
      weights.freshness * candidate.freshness;
  if (sessionTaste != null) {
    score +=
        weights.sessionAffinity * _affinity(products, sessionTaste, config);
  }
  if (candidate.kind.isAd) score += config.paidAdNearTieBonus;
  return score;
}

/// How much [taste] likes [products], from -1 to 1: for each Product the
/// mean of its category, Brand and price band, then the mean over the
/// Products.
double _affinity(
  List<RankedProduct> products,
  Affinities taste,
  RankingConfig config,
) {
  if (products.isEmpty) return 0;
  double squash(double a) => a / (a.abs() + config.affinitySaturation);

  var total = 0.0;
  for (final product in products) {
    final band = _priceBandOf(product, config);
    total +=
        (squash(taste.category(product.category)) +
            squash(taste.brand(product.brand)) +
            squash(band == null ? 0 : taste.priceBand(band))) /
        3;
  }
  return total / products.length;
}

/// Whether none of [tastes] knows anything about [candidate]'s Brand or
/// its Products' Brands and categories.
bool _isNovel(RankingCandidate candidate, List<Affinities> tastes) =>
    !tastes.any(
      (taste) =>
          taste.brand(candidate.brand) != 0 ||
          candidate.products.any(
            (p) => taste.category(p.category) != 0 || taste.brand(p.brand) != 0,
          ),
    );

bool _hasGoal(SessionGoal? session) =>
    session != null &&
    (session.category != null || _words(session.query).isNotEmpty);

/// Whether [product] fits the session's goal: its category filter, and
/// every word of the goal in the Product's title, Brand or category. No
/// goal matches everything.
bool _matchesGoal(RankedProduct product, SessionGoal? session) {
  if (session == null) return true;
  if (session.category != null && product.category != session.category) {
    return false;
  }
  final text = '${product.title} ${product.brand} ${product.category}'
      .toLowerCase();
  return _words(session.query).every(text.contains);
}

List<String> _words(String query) => query
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .toList();

/// Places [ranked] slot by slot. Each slot takes the best candidate left
/// that doesn't follow its own Brand (when only one Brand is left, it
/// repeats). An exploration slot first tries the best novel candidate.
/// Slots are counted across the whole feed, so [shownBefore] Feed Items
/// came before this page.
List<RankingCandidate> _arrange(
  List<RankingCandidate> ranked, {
  required String? previousBrand,
  required int shownBefore,
  required bool Function(RankingCandidate) isNovel,
  required RankingConfig config,
}) {
  final share = config.explorationShare;
  final every = share > 0 ? (1 / share).round() : 0;

  final left = [...ranked];
  final arranged = <RankingCandidate>[];
  var previous = previousBrand;

  while (left.isNotEmpty) {
    final slot = shownBefore + arranged.length + 1;
    var pick = -1;
    if (every > 0 && slot % every == 0) {
      pick = left.indexWhere((c) => isNovel(c) && c.brand != previous);
    }
    if (pick < 0) pick = left.indexWhere((c) => c.brand != previous);
    if (pick < 0) pick = 0;

    final next = left.removeAt(pick);
    arranged.add(next);
    previous = next.brand;
  }
  return arranged;
}

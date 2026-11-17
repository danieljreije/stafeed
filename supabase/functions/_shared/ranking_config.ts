// Every tunable number of the ranking (spec Seam 3). The same values live in
// `shared/ranking/ranking_config.json` and in the app's
// `lib/app/features/ranking/ranking_config.dart`; tests keep all three equal.
// They are written out here, not imported, so the Edge Function bundle only
// needs files under `supabase/functions/`.

/** How much each part of a Feed Item's score counts. */
export interface ScoreWeights {
  readonly sourceRelevance: number;
  readonly intentMatch: number;
  readonly sessionAffinity: number;
  readonly longTermAffinity: number;
  readonly quality: number;
  readonly freshness: number;
}

/** A Shopper action that tells the ranking something about their taste. */
export type SignalType =
  | 'not_interested'
  | 'fast_skip'
  | 'skip'
  | 'view_2s'
  | 'view_5s'
  | 'details'
  | 'share'
  | 'save'
  | 'outbound_click';

/**
 * What each signal adds to (or takes from) the affinity of the Product's
 * Brand, category and price band. `view_5s` is the total for a 5s view: it
 * always follows a 2s view of the same Feed Item, so on its own it only adds
 * the difference.
 */
export type SignalWeights = Readonly<Record<SignalType, number>>;

export interface RankingConfig {
  readonly scoreWeights: ScoreWeights;
  readonly signalWeights: SignalWeights;
  /** A summed affinity `a` counts as `a / (|a| + affinitySaturation)`. */
  readonly affinitySaturation: number;
  /**
   * Added to every paid Ad's score, so it wins near-ties against Not an Ad.
   * Never depends on how much an Ad pays.
   */
  readonly paidAdNearTieBonus: number;
  /**
   * Every `round(1 / share)`th Feed Item, counted from the top of the feed,
   * is the best novel one (when there is one).
   */
  readonly explorationShare: number;
  /** Prices (minor units) where one price band ends and the next begins. */
  readonly priceBandEdgesMinor: readonly number[];
}

/** The weights the backend ranks with. Change them with the shared file. */
export const defaultRankingConfig: RankingConfig = {
  scoreWeights: {
    sourceRelevance: 0.4,
    intentMatch: 0.2,
    sessionAffinity: 0.15,
    longTermAffinity: 0.1,
    quality: 0.05,
    freshness: 0.05,
  },
  signalWeights: {
    not_interested: -5,
    fast_skip: -2,
    skip: -1,
    view_2s: 0.5,
    view_5s: 1,
    details: 2,
    share: 3,
    save: 4,
    outbound_click: 5,
  },
  affinitySaturation: 5,
  paidAdNearTieBonus: 0.02,
  explorationShare: 0.05,
  priceBandEdgesMinor: [5000, 15000, 30000],
};

/** The shape of `shared/ranking/ranking_config.json`. */
export interface RankingConfigJson {
  readonly score_weights: {
    readonly source_relevance: number;
    readonly intent_match: number;
    readonly session_affinity: number;
    readonly long_term_affinity: number;
    readonly quality: number;
    readonly freshness: number;
  };
  readonly signal_weights: SignalWeights;
  readonly affinity_saturation: number;
  readonly paid_ad_near_tie_bonus: number;
  readonly exploration_share: number;
  readonly price_band_edges_minor: readonly number[];
}

export function rankingConfigFromJson(json: RankingConfigJson): RankingConfig {
  const s = json.score_weights;
  const w = json.signal_weights;
  return {
    scoreWeights: {
      sourceRelevance: s.source_relevance,
      intentMatch: s.intent_match,
      sessionAffinity: s.session_affinity,
      longTermAffinity: s.long_term_affinity,
      quality: s.quality,
      freshness: s.freshness,
    },
    signalWeights: {
      not_interested: w.not_interested,
      fast_skip: w.fast_skip,
      skip: w.skip,
      view_2s: w.view_2s,
      view_5s: w.view_5s,
      details: w.details,
      share: w.share,
      save: w.save,
      outbound_click: w.outbound_click,
    },
    affinitySaturation: json.affinity_saturation,
    paidAdNearTieBonus: json.paid_ad_near_tie_bonus,
    explorationShare: json.exploration_share,
    priceBandEdgesMinor: [...json.price_band_edges_minor],
  };
}

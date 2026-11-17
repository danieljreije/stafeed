// The ranking (spec Seam 3): a pure function that orders candidate Feed Items
// for one feed, from the Shopper's long-term taste, the active Shopping
// Session's taste, what was already shown and the Not interested set.
//
// It knows nothing about requests, storage or sources. The same rules are
// written in Dart for the app (`lib/app/features/ranking/ranking.dart`); both
// pass the shared scenarios in `shared/ranking/scenarios.json`. Change a rule
// there first (see `shared/ranking/README.md`), then both follow.

import type { RankingConfig, SignalType } from './ranking_config.ts';

/** The permanent For You feed (only Ads), or a Shopping Session's feed. */
export type RankedFeed = 'for_you' | 'session';

/** What a candidate Feed Item is, as far as ranking cares. */
export type CandidateKind = 'affiliate_ad' | 'brand_ad' | 'not_an_ad';

/** What the ranking needs to know about a Product. */
export interface RankedProduct {
  readonly id: string;
  readonly title: string;
  readonly brand: string;
  readonly category: string;
  /** The price of the Offer shown, in minor units. Null when unknown. */
  readonly priceMinor: number | null;
}

/** One Feed Item the ranking may place. */
export interface RankingCandidate {
  /** The Feed Item's ID. For an Affiliate Ad or Not an Ad, the Product's. */
  readonly id: string;
  readonly kind: CandidateKind;
  /** The Brand shown: a Brand Ad's own Brand, or the Product's. */
  readonly brand: string;
  /** The Product shown, or the Products a Brand Ad links to. */
  readonly products: readonly RankedProduct[];
  /** How well the source thinks it fits, from 0 to 1. */
  readonly relevance: number;
  /** Quality or popularity, from 0 to 1. */
  readonly quality: number;
  /** How new it is, from 0 to 1. */
  readonly freshness: number;
  /** False when its Offer is out of stock. */
  readonly isAvailable: boolean;
  /** Countries its Offer ships to. Null means everywhere. */
  readonly shipsTo: ReadonlySet<string> | null;
}

/** One signal about one Product. */
export interface TasteSignal {
  readonly type: SignalType;
  readonly product: RankedProduct;
}

/** A Shopping Session as the ranking sees it: its goal and its own taste. */
export interface SessionGoal {
  /** The goal the Shopper typed, e.g. "white sneakers". */
  readonly query: string;
  /** The category filter, if any. */
  readonly category: string | null;
  /** What the Shopper did inside this session. Never used for For You. */
  readonly signals: readonly TasteSignal[];
}

/** Everything one ranking call looks at. */
export interface RankingInput {
  readonly feed: RankedFeed;
  /** In the source's order, best first. */
  readonly candidates: readonly RankingCandidate[];
  /** Candidates whose Offer doesn't ship here are left out. Null keeps all. */
  readonly destinationCountry: string | null;
  /** Categories the Shopper picked at onboarding. */
  readonly interests: ReadonlySet<string>;
  /** What the Shopper did in For You (never inside a Shopping Session). */
  readonly longTermSignals: readonly TasteSignal[];
  /** The active Shopping Session. Ignored for For You. */
  readonly session: SessionGoal | null;
  /** Feed Item IDs already shown in this feed; never shown again. */
  readonly recentlyShown: ReadonlySet<string>;
  /** Product IDs the Shopper marked Not interested; never shown again. */
  readonly notInterested: ReadonlySet<string>;
  /** The Brand of the Feed Item shown just before this page. */
  readonly previousBrand: string | null;
}

/** Summed signal weights per category, Brand and price band. */
class Affinities {
  private readonly categories = new Map<string, number>();
  private readonly brands = new Map<string, number>();
  private readonly priceBands = new Map<string, number>();

  constructor(signals: readonly TasteSignal[], config: RankingConfig) {
    const add = (map: Map<string, number>, key: string, weight: number) =>
      map.set(key, (map.get(key) ?? 0) + weight);

    for (const signal of signals) {
      const weight = signalWeight(signal.type, config);
      if (weight === 0) continue;
      const product = signal.product;
      add(this.categories, product.category, weight);
      add(this.brands, product.brand, weight);
      const band = priceBandOf(product, config);
      if (band !== null) add(this.priceBands, band, weight);
    }
  }

  category(id: string): number {
    return this.categories.get(id) ?? 0;
  }

  brand(name: string): number {
    return this.brands.get(name) ?? 0;
  }

  priceBand(band: string): number {
    return this.priceBands.get(band) ?? 0;
  }
}

function signalWeight(type: SignalType, config: RankingConfig): number {
  const weights = config.signalWeights;
  // A 5s view always follows a 2s view of the same Feed Item: only the
  // difference is added, so the two together count as one 5s view.
  return type === 'view_5s' ? weights.view_5s - weights.view_2s : weights[type];
}

/** "0" below the first edge, "1" below the second, ... Null when unknown. */
function priceBandOf(product: RankedProduct, config: RankingConfig): string | null {
  const price = product.priceMinor;
  if (price === null) return null;
  let band = 0;
  for (const edge of config.priceBandEdgesMinor) {
    if (price < edge) break;
    band++;
  }
  return `${band}`;
}

/**
 * The candidates of [input] that may be shown, best first.
 *
 * 1. Retrieval leaves out what is out of stock, doesn't ship to the
 *    Destination Country, was already shown, or is Not interested (a Brand
 *    Ad loses those linked Products, and goes when none is left). For You
 *    only takes Ads; in a Shopping Session a Brand Ad stays only when one of
 *    its Products matches the goal.
 * 2. Each candidate is scored with the weighted mix in [config].
 * 3. Best score first (the source's order breaks ties), with two rules: never
 *    the same Brand twice in a row while another Brand is left, and every
 *    exploration slot goes to the best novel candidate: one whose Brand and
 *    category the Shopper's taste knows nothing about.
 */
export function rank(input: RankingInput, config: RankingConfig): RankingCandidate[] {
  const inSession = input.feed === 'session';
  const session = inSession ? input.session : null;

  const eligible: RankingCandidate[] = [];
  for (const candidate of input.candidates) {
    const kept = retrieve(candidate, input, session, inSession);
    if (kept) eligible.push(kept);
  }

  const longTerm = new Affinities(input.longTermSignals, config);
  const sessionTaste = session ? new Affinities(session.signals, config) : null;
  const tastes = sessionTaste ? [longTerm, sessionTaste] : [longTerm];

  const scores = eligible.map((candidate) =>
    score(candidate, input, session, longTerm, sessionTaste, config),
  );
  const order = eligible
    .map((_, i) => i)
    .sort((a, b) => {
      const byScore = (scores[b] ?? 0) - (scores[a] ?? 0);
      return byScore !== 0 ? byScore : a - b;
    });

  return arrange(
    order.map((i) => eligible[i] as RankingCandidate),
    input.previousBrand,
    input.recentlyShown.size,
    (candidate) => isNovel(candidate, tastes),
    config,
  );
}

function retrieve(
  candidate: RankingCandidate,
  input: RankingInput,
  session: SessionGoal | null,
  inSession: boolean,
): RankingCandidate | null {
  if (!candidate.isAvailable) return null;
  const country = input.destinationCountry;
  const shipsTo = candidate.shipsTo;
  if (country !== null && shipsTo !== null && !shipsTo.has(country)) return null;
  if (input.recentlyShown.has(candidate.id)) return null;
  if (!inSession && candidate.kind === 'not_an_ad') return null;

  if (candidate.kind !== 'brand_ad') {
    const product = candidate.products[0];
    if (product && input.notInterested.has(product.id)) return null;
    return candidate;
  }

  const linked = candidate.products.filter((p) => !input.notInterested.has(p.id));
  // Gone when Not interested took every Product it had.
  if (linked.length === 0 && candidate.products.length > 0) return null;
  if (inSession && !linked.some((p) => matchesGoal(p, session))) return null;

  return linked.length === candidate.products.length
    ? candidate
    : { ...candidate, products: linked };
}

function score(
  candidate: RankingCandidate,
  input: RankingInput,
  session: SessionGoal | null,
  longTerm: Affinities,
  sessionTaste: Affinities | null,
  config: RankingConfig,
): number {
  const weights = config.scoreWeights;
  const products = candidate.products;

  const intent =
    input.feed === 'for_you'
      ? products.some((p) => input.interests.has(p.category))
        ? 1
        : 0
      : hasGoal(session) && products.some((p) => matchesGoal(p, session))
        ? 1
        : 0;

  // Summed in the same order as the Dart ranking, so floating-point ties
  // break the same way.
  let total =
    weights.sourceRelevance * candidate.relevance +
    weights.intentMatch * intent +
    weights.longTermAffinity * affinity(products, longTerm, config) +
    weights.quality * candidate.quality +
    weights.freshness * candidate.freshness;
  if (sessionTaste) {
    total += weights.sessionAffinity * affinity(products, sessionTaste, config);
  }
  if (candidate.kind !== 'not_an_ad') total += config.paidAdNearTieBonus;
  return total;
}

/**
 * How much [taste] likes [products], from -1 to 1: for each Product the mean
 * of its category, Brand and price band, then the mean over the Products.
 */
function affinity(
  products: readonly RankedProduct[],
  taste: Affinities,
  config: RankingConfig,
): number {
  if (products.length === 0) return 0;
  const squash = (a: number) => a / (Math.abs(a) + config.affinitySaturation);

  let total = 0;
  for (const product of products) {
    const band = priceBandOf(product, config);
    total +=
      (squash(taste.category(product.category)) +
        squash(taste.brand(product.brand)) +
        squash(band === null ? 0 : taste.priceBand(band))) /
      3;
  }
  return total / products.length;
}

/** Whether no taste knows anything about [candidate]'s Brands or categories. */
function isNovel(candidate: RankingCandidate, tastes: readonly Affinities[]): boolean {
  return !tastes.some(
    (taste) =>
      taste.brand(candidate.brand) !== 0 ||
      candidate.products.some((p) => taste.category(p.category) !== 0 || taste.brand(p.brand) !== 0),
  );
}

function hasGoal(session: SessionGoal | null): boolean {
  return session !== null && (session.category !== null || words(session.query).length > 0);
}

/**
 * Whether [product] fits the session's goal: its category filter, and every
 * word of the goal in the Product's title, Brand or category. No goal matches
 * everything.
 */
function matchesGoal(product: RankedProduct, session: SessionGoal | null): boolean {
  if (session === null) return true;
  if (session.category !== null && product.category !== session.category) return false;
  const text = `${product.title} ${product.brand} ${product.category}`.toLowerCase();
  return words(session.query).every((word) => text.includes(word));
}

function words(query: string): string[] {
  return query
    .toLowerCase()
    .split(/\s+/)
    .filter((word) => word.length > 0);
}

/**
 * Places [ranked] slot by slot. Each slot takes the best candidate left that
 * doesn't follow its own Brand (when only one Brand is left, it repeats). An
 * exploration slot first tries the best novel candidate. Slots are counted
 * across the whole feed, so [shownBefore] Feed Items came before this page.
 */
function arrange(
  ranked: readonly RankingCandidate[],
  previousBrand: string | null,
  shownBefore: number,
  isNovelCandidate: (candidate: RankingCandidate) => boolean,
  config: RankingConfig,
): RankingCandidate[] {
  const share = config.explorationShare;
  const every = share > 0 ? Math.round(1 / share) : 0;

  const left = [...ranked];
  const arranged: RankingCandidate[] = [];
  let previous = previousBrand;

  while (left.length > 0) {
    const slot = shownBefore + arranged.length + 1;
    let pick = -1;
    if (every > 0 && slot % every === 0) {
      pick = left.findIndex((c) => isNovelCandidate(c) && c.brand !== previous);
    }
    if (pick < 0) pick = left.findIndex((c) => c.brand !== previous);
    if (pick < 0) pick = 0;

    const [next] = left.splice(pick, 1) as [RankingCandidate];
    arranged.push(next);
    previous = next.brand;
  }
  return arranged;
}

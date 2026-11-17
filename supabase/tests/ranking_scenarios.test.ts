// Runs the shared, language-neutral ranking scenarios (also run by the Dart
// ranking in test/features/ranking/ranking_scenarios_test.dart), and checks
// the backend's built-in weights equal the shared config.

import { describe, expect, it } from 'vitest';

import {
  type CandidateKind,
  rank,
  type RankedProduct,
  type RankingCandidate,
  type RankingInput,
  type TasteSignal,
} from '../functions/_shared/ranking.ts';
import {
  defaultRankingConfig,
  rankingConfigFromJson,
  type RankingConfigJson,
  type SignalType,
} from '../functions/_shared/ranking_config.ts';
import configJson from '../../shared/ranking/ranking_config.json' with { type: 'json' };
import scenariosJson from '../../shared/ranking/scenarios.json' with { type: 'json' };

/** One scenario, as `shared/ranking/README.md` describes it. */
interface Scenario {
  name: string;
  feed: 'for_you' | 'session';
  products: Record<string, { title: string; brand: string; category: string; price_minor?: number }>;
  candidates: {
    id: string;
    kind: CandidateKind;
    product?: string;
    brand?: string;
    products?: string[];
    relevance?: number;
    quality?: number;
    freshness?: number;
    available?: boolean;
    ships_to?: string[];
  }[];
  destination_country?: string;
  interests?: string[];
  long_term_signals?: { signal: SignalType; product: string }[];
  session?: {
    query?: string;
    category?: string;
    signals?: { signal: SignalType; product: string }[];
  };
  recently_shown?: string[];
  not_interested?: string[];
  previous_brand?: string;
  expected: { order: string[]; linked_products?: Record<string, string[]> };
}

const config = rankingConfigFromJson(configJson as RankingConfigJson);
const scenarios = (scenariosJson as unknown as { scenarios: Scenario[] }).scenarios;

function inputFrom(scenario: Scenario): RankingInput {
  const products = new Map<string, RankedProduct>();
  for (const [id, p] of Object.entries(scenario.products)) {
    products.set(id, {
      id,
      title: p.title,
      brand: p.brand,
      category: p.category,
      priceMinor: p.price_minor ?? null,
    });
  }
  const productOf = (id: string): RankedProduct => {
    const product = products.get(id);
    if (!product) throw new Error(`${scenario.name}: unknown product ${id}`);
    return product;
  };
  const signals = (list?: { signal: SignalType; product: string }[]): TasteSignal[] =>
    (list ?? []).map((s) => ({ type: s.signal, product: productOf(s.product) }));

  const candidates: RankingCandidate[] = scenario.candidates.map((c) => {
    const linked =
      c.kind === 'brand_ad' ? (c.products ?? []).map(productOf) : [productOf(c.product ?? '')];
    return {
      id: c.id,
      kind: c.kind,
      brand: c.brand ?? linked[0]?.brand ?? '',
      products: linked,
      relevance: c.relevance ?? 0,
      quality: c.quality ?? 0,
      freshness: c.freshness ?? 0,
      isAvailable: c.available ?? true,
      shipsTo: c.ships_to ? new Set(c.ships_to) : null,
    };
  });

  const session = scenario.session;
  return {
    feed: scenario.feed === 'session' ? 'session' : 'for_you',
    candidates,
    destinationCountry: scenario.destination_country ?? null,
    interests: new Set(scenario.interests ?? []),
    longTermSignals: signals(scenario.long_term_signals),
    session: session
      ? {
          query: session.query ?? '',
          category: session.category ?? null,
          signals: signals(session.signals),
        }
      : null,
    recentlyShown: new Set(scenario.recently_shown ?? []),
    notInterested: new Set(scenario.not_interested ?? []),
    previousBrand: scenario.previous_brand ?? null,
  };
}

describe('shared ranking scenarios', () => {
  it('has scenarios to run', () => {
    expect(scenarios.length).toBeGreaterThan(0);
  });

  for (const scenario of scenarios) {
    it(scenario.name, () => {
      const ranked = rank(inputFrom(scenario), config);

      expect(ranked.map((c) => c.id)).toEqual(scenario.expected.order);
      for (const [id, expected] of Object.entries(scenario.expected.linked_products ?? {})) {
        const brandAd = ranked.find((c) => c.id === id);
        expect(brandAd?.products.map((p) => p.id)).toEqual(expected);
      }
    });
  }
});

describe('ranking config', () => {
  it("the backend's built-in weights equal shared/ranking/ranking_config.json", () => {
    expect(defaultRankingConfig).toEqual(config);
  });
});

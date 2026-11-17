// For You, assembled from every source and ordered by the ranking
// (ranking.ts, the same rules as the app's), a page at a time.

import type { CandidateQuery } from './ad_source.ts';
import type { FeedItem, Offer, Product } from './domain.ts';
import { isAdOffer, summarise } from './domain.ts';
import { readCursor, writeCursor } from './cursor.ts';
import { rank, type RankedFeed, type RankedProduct, type RankingCandidate } from './ranking.ts';
import { defaultRankingConfig } from './ranking_config.ts';
import type { GuardedSource } from './source_guard.ts';

export interface FeedPage {
  readonly items: readonly FeedItem[];
  /** Null on the last page. */
  readonly nextCursor: string | null;
}

/**
 * One page of For You for [query]. Throws `InvalidCursorError` when [cursor]
 * wasn't issued for this same feed.
 */
export async function getForYouPage(
  sources: readonly GuardedSource[],
  query: CandidateQuery,
  cursor: string | null,
  pageSize: number,
): Promise<FeedPage> {
  const fingerprint = [query.destinationCountry, query.category ?? '', searchWords(query.query).join(' ')].join(
    '|',
  );
  const start = cursor === null ? 0 : readCursor(cursor, fingerprint);

  // The whole feed is ranked at once and paged by position. That is the
  // same order the ranking gives page by page (it counts slots and the Brand
  // rule across pages), as long as nothing it ranks with changes between
  // pages. Anonymous Shoppers have no taste on the backend yet (#17); once
  // they do, the cursor must carry what was shown instead, like the app's.
  const items = await rankedFeed('for_you', sources, query);
  const end = Math.min(start + pageSize, items.length);

  return {
    items: items.slice(start, end),
    nextCursor: end < items.length ? writeCursor(end, fingerprint) : null,
  };
}

/** A Feed Item the sources offer, with what the ranking knows about it. */
interface Entry {
  readonly item: FeedItem;
  readonly candidate: RankingCandidate;
}

/**
 * Every Feed Item of [feed], ranked. The ranking decides what may show: For
 * You only takes Ads (ADR-0002), never out of stock. A Brand Ad keeps only the
 * Products that are Ads there. The same Feed Item from two sources shows
 * once, preferring a copy that can show here.
 */
async function rankedFeed(
  feed: RankedFeed,
  sources: readonly GuardedSource[],
  query: CandidateQuery,
): Promise<FeedItem[]> {
  const entries: Entry[] = [];
  const indexById = new Map<string, number>();
  const add = (entry: Entry) => {
    const index = indexById.get(entry.item.id);
    if (index === undefined) {
      indexById.set(entry.item.id, entries.length);
      entries.push(entry);
    } else if (!canShowAsAd(entries[index]) && canShowAsAd(entry)) {
      entries[index] = entry;
    }
  };

  for (const source of sources) {
    for (const candidate of await source.searchCandidates(query)) {
      if (candidate.kind === 'product') {
        const entry = productEntry(candidate.product);
        if (entry) add(entry);
        continue;
      }

      const { brandAd } = candidate;
      const products = brandAd.products.flatMap((p) => {
        const offer = adOffer(p);
        return offer ? [{ product: p, offer }] : [];
      });
      if (products.length === 0) continue;
      add({
        item: {
          kind: 'brand_ad',
          id: brandAd.id,
          label: 'AD',
          sponsored: true,
          brand: brandAd.brand,
          headline: brandAd.headline,
          media: brandAd.media,
          products: products.map(({ product }) => summarise(product)),
        },
        candidate: {
          ...candidateDefaults,
          id: brandAd.id,
          kind: 'brand_ad',
          brand: brandAd.brand,
          products: products.map(({ product, offer }) => rankedProduct(product, offer)),
          isAvailable: true,
          shipsTo: null,
        },
      });
    }
  }

  const byId = new Map(entries.map((entry) => [entry.item.id, entry.item]));
  const ranked = rank(
    {
      feed,
      candidates: entries.map((entry) => entry.candidate),
      destinationCountry: query.destinationCountry,
      interests: new Set(),
      longTermSignals: [],
      session: null,
      recentlyShown: new Set(),
      notInterested: new Set(),
      previousBrand: null,
    },
    defaultRankingConfig,
  );
  return ranked.flatMap((candidate) => {
    const item = byId.get(candidate.id);
    return item ? [item] : [];
  });
}

/**
 * [product] as a Feed Item: an Affiliate Ad with its first in-stock Offer
 * that earns; otherwise, with its first in-stock Offer (or first Offer), a
 * Not an Ad or an out-of-stock Affiliate Ad the ranking leaves out of For You.
 */
function productEntry(product: Product): Entry | null {
  const ad = adOffer(product);
  const offer =
    ad ?? product.offers.find((o) => o.availability === 'in_stock') ?? product.offers[0];
  if (!offer) return null;

  const summary = summarise(product);
  const item: FeedItem =
    offer.monetisation === 'none'
      ? { kind: 'not_an_ad', id: product.id, label: 'NOT AN AD', sponsored: false, product: summary, offer }
      : { kind: 'affiliate_ad', id: product.id, label: 'AD', sponsored: false, product: summary, offer };

  return {
    item,
    candidate: {
      ...candidateDefaults,
      id: product.id,
      kind: item.kind,
      brand: product.brand,
      products: [rankedProduct(product, offer)],
      isAvailable: offer.availability === 'in_stock',
      shipsTo: new Set(offer.shipsTo),
    },
  };
}

/**
 * Sources don't score their candidates yet: every one counts as fully
 * relevant, so the source's order breaks ties (as in the app).
 */
const candidateDefaults = { relevance: 1, quality: 0, freshness: 0 } as const;

function canShowAsAd(entry: Entry | undefined): boolean {
  return entry !== undefined && entry.candidate.kind !== 'not_an_ad' && entry.candidate.isAvailable;
}

function rankedProduct(product: Product, offer: Offer): RankedProduct {
  return {
    id: product.id,
    title: product.title,
    brand: product.brand,
    category: product.category,
    priceMinor: offer.price.minorUnits,
  };
}

function adOffer(product: Product): Offer | undefined {
  return product.offers.find(isAdOffer);
}

/** The search words in [query], lower case. */
export function searchWords(query: string): string[] {
  return query.toLowerCase().split(/\s+/).filter((w) => w.length > 0);
}

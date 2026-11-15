// For You, assembled from every source: ranked-ready candidates (ranking in
// TypeScript is a later ticket), in source order, a page at a time.

import type { CandidateQuery } from './ad_source.ts';
import type { FeedItem, Offer, Product } from './domain.ts';
import { isAdOffer, summarise } from './domain.ts';
import { readCursor, writeCursor } from './cursor.ts';
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

  const items = await forYou(sources, query);
  const end = Math.min(start + pageSize, items.length);

  return {
    items: items.slice(start, end),
    nextCursor: end < items.length ? writeCursor(end, fingerprint) : null,
  };
}

/**
 * Every Feed Item For You holds, in order. Only Ads (ADR-0002): a Product
 * shows as an Affiliate Ad with its first in-stock Offer that earns, and is
 * left out without one. A Brand Ad keeps only the Products that are Ads
 * there. The same Feed Item from two sources shows once.
 */
async function forYou(
  sources: readonly GuardedSource[],
  query: CandidateQuery,
): Promise<FeedItem[]> {
  const items: FeedItem[] = [];
  const seen = new Set<string>();
  const add = (item: FeedItem) => {
    if (seen.has(item.id)) return;
    seen.add(item.id);
    items.push(item);
  };

  for (const source of sources) {
    for (const candidate of await source.searchCandidates(query)) {
      if (candidate.kind === 'product') {
        const offer = adOffer(candidate.product);
        if (offer) {
          add({
            kind: 'affiliate_ad',
            id: candidate.product.id,
            label: 'AD',
            sponsored: false,
            product: summarise(candidate.product),
            offer,
          });
        }
        continue;
      }

      const { brandAd } = candidate;
      const products = brandAd.products.filter((p) => adOffer(p) !== undefined);
      if (products.length === 0) continue;
      add({
        kind: 'brand_ad',
        id: brandAd.id,
        label: 'AD',
        sponsored: true,
        brand: brandAd.brand,
        headline: brandAd.headline,
        media: brandAd.media,
        products: products.map(summarise),
      });
    }
  }

  return items;
}

function adOffer(product: Product): Offer | undefined {
  return product.offers.find(isAdOffer);
}

/** The search words in [query], lower case. */
export function searchWords(query: string): string[] {
  return query.toLowerCase().split(/\s+/).filter((w) => w.length > 0);
}

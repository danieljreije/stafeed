// Seam 2: the one interface every ad source sits behind (Fixtures now;
// Brand Ads, Awin and Shopify later). The feed never talks to a source
// directly: it goes through `guardSource` (source_guard.ts), which applies
// Destination Country and prohibited-category filtering at this boundary.

import type {
  BrandAd,
  Monetisation,
  Product,
  SupportedFilters,
} from './domain.ts';

/** What the feed asks a source for. */
export interface CandidateQuery {
  /** ISO 3166-1 alpha-2, upper case. */
  readonly destinationCountry: string;
  /** A category ID from the source's supported filters, or null for all. */
  readonly category: string | null;
  /** Free-text search; empty for none. */
  readonly query: string;
}

/** Something a source offers to show, before it becomes a Feed Item. */
export type Candidate =
  | { readonly kind: 'product'; readonly product: Product }
  | { readonly kind: 'brand_ad'; readonly brandAd: BrandAd };

export interface AdSource {
  /** Stable name, e.g. `fixtures`. */
  readonly id: string;
  /** True for Fixtures: sample data, never real commercial inventory. */
  readonly servesSampleData: boolean;
  /** Every way this source's candidates earn (or don't) for Stafeed. */
  readonly monetisation: readonly Monetisation[];

  supportedFilters(): Promise<SupportedFilters>;

  /** Candidates matching [query], in the source's own order. */
  searchCandidates(query: CandidateQuery): Promise<readonly Candidate[]>;

  /**
   * A fresh copy of one Product with today's prices and availability, or
   * null when the source doesn't know it.
   */
  getProduct(productId: string): Promise<Product | null>;
}

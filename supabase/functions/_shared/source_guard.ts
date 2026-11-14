// The adapter boundary (Seam 2). Whatever a source returns, nothing in a
// prohibited category and no Offer that doesn't ship to the Destination
// Country gets past here. Sources may filter too; this is the guarantee.

import type { AdSource, Candidate, CandidateQuery } from './ad_source.ts';
import type { Product, SupportedFilters } from './domain.ts';
import { isProhibitedCategory } from './prohibited.ts';

export interface GuardedSource {
  readonly source: AdSource;
  supportedFilters(): Promise<SupportedFilters>;
  searchCandidates(query: CandidateQuery): Promise<readonly Candidate[]>;
  getProduct(productId: string, destinationCountry: string): Promise<Product | null>;
}

export function guardSource(source: AdSource): GuardedSource {
  return {
    source,

    async supportedFilters() {
      const filters = await source.supportedFilters();
      return { categories: filters.categories.filter((c) => !isProhibitedCategory(c.id)) };
    },

    async searchCandidates(query) {
      const allowed: Candidate[] = [];
      for (const candidate of await source.searchCandidates(query)) {
        if (candidate.kind === 'product') {
          const product = allow(candidate.product, query.destinationCountry);
          if (product) allowed.push({ kind: 'product', product });
          continue;
        }

        const products = candidate.brandAd.products
          .map((p) => allow(p, query.destinationCountry))
          .filter((p): p is Product => p !== null);
        if (products.length > 0) {
          allowed.push({ kind: 'brand_ad', brandAd: { ...candidate.brandAd, products } });
        }
      }
      return allowed;
    },

    async getProduct(productId, destinationCountry) {
      const product = await source.getProduct(productId);
      return product ? allow(product, destinationCountry) : null;
    },
  };
}

/** [product] with only the Offers shipping to [country], or null. */
function allow(product: Product, country: string): Product | null {
  if (isProhibitedCategory(product.category)) return null;

  const offers = product.offers.filter((o) => o.shipsTo.includes(country));
  if (offers.length === 0) return null;
  return offers.length === product.offers.length ? product : { ...product, offers };
}

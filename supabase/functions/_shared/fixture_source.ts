// The server-side Fixture source: the app's Fixtures (sample Products and
// Brand Ads, never real commercial inventory), served through Seam 2 for
// development and tests. fixtures/fixtures.json is a copy of the app's
// Fixtures; a Flutter test (test/features/feed/data/server_fixtures_test.dart)
// fails when the two drift apart.

import type { AdSource, Candidate, CandidateQuery } from './ad_source.ts';
import type {
  BrandAd,
  Category,
  Monetisation,
  Offer,
  Product,
  SupportedFilters,
} from './domain.ts';
import { isAdOffer } from './domain.ts';
import { searchWords } from './feed.ts';
import fixtures from './fixtures/fixtures.json' with { type: 'json' };

interface FixtureData {
  categories: Category[];
  products: Product[];
  brandAds: (Omit<BrandAd, 'products'> & { productIds: string[] })[];
}

const data = fixtures as FixtureData;

export class FixtureSource implements AdSource {
  readonly id = 'fixtures';
  readonly servesSampleData = true;
  readonly monetisation: readonly Monetisation[] = ['affiliate', 'none', 'sponsored'];

  readonly #products: readonly Product[];
  readonly #brandAds: readonly BrandAd[];
  readonly #categories: readonly Category[];

  constructor() {
    this.#products = data.products;
    this.#categories = data.categories;
    this.#brandAds = data.brandAds.map(({ productIds, ...ad }) => ({
      ...ad,
      products: productIds.map((id) => {
        const product = this.#products.find((p) => p.id === id);
        if (!product) throw new Error(`Fixture Brand Ad ${ad.id} links unknown ${id}`);
        return product;
      }),
    }));
  }

  async supportedFilters(): Promise<SupportedFilters> {
    return { categories: this.#categories };
  }

  /**
   * Like the app's Fixture gateway: each Product with an Offer shipping to the
   * Destination Country, in Fixture order, and each Brand Ad (linking only
   * those of its Products with an Ad Offer shipping there) right after the
   * last of its linked Products. Then the category and search filters.
   */
  async searchCandidates(query: CandidateQuery): Promise<readonly Candidate[]> {
    const country = query.destinationCountry;
    const ships = (offer: Offer) => offer.shipsTo.includes(country);

    const candidates: Candidate[] = [];
    for (const product of this.#products) {
      const offers = product.offers.filter(ships);
      if (offers.length > 0) candidates.push({ kind: 'product', product: { ...product, offers } });
    }

    for (const ad of this.#brandAds) {
      const products = ad.products.filter((p) =>
        p.offers.some((o) => ships(o) && isAdOffer(o)),
      );
      if (products.length === 0) continue;

      const linked = new Set(products.map((p) => p.id));
      const last = candidates.findLastIndex(
        (c) => c.kind === 'product' && linked.has(c.product.id),
      );
      const brandAd: BrandAd = { ...ad, products };
      candidates.splice(last < 0 ? candidates.length : last + 1, 0, {
        kind: 'brand_ad',
        brandAd,
      });
    }

    return candidates.filter((c) => this.#matches(c, query));
  }

  async getProduct(productId: string): Promise<Product | null> {
    return this.#products.find((p) => p.id === productId) ?? null;
  }

  /** A Brand Ad matches through its own Brand and headline, and its Products. */
  #matches(candidate: Candidate, query: CandidateQuery): boolean {
    const products = candidate.kind === 'product' ? [candidate.product] : candidate.brandAd.products;

    if (query.category !== null && !products.some((p) => p.category === query.category)) {
      return false;
    }

    const words = searchWords(query.query);
    if (words.length === 0) return true;

    const haystack = [
      ...(candidate.kind === 'brand_ad'
        ? [candidate.brandAd.brand, candidate.brandAd.headline]
        : []),
      ...products.flatMap((p) => [
        p.title,
        p.brand,
        this.#categoryLabel(p.category),
        ...Object.values(p.attributes),
      ]),
    ]
      .join(' ')
      .toLowerCase();

    return words.every((word) => haystack.includes(word));
  }

  #categoryLabel(id: string): string {
    return this.#categories.find((c) => c.id === id)?.label ?? id;
  }
}

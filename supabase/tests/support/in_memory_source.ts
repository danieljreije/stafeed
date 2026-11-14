import type { AdSource, Candidate } from '../../functions/_shared/ad_source.ts';
import type {
  BrandAd,
  Category,
  Monetisation,
  Offer,
  Product,
} from '../../functions/_shared/domain.ts';

/** A source that hands back exactly what the test gave it, ignoring the query. */
export function inMemorySource(options: {
  products?: Product[];
  brandAds?: BrandAd[];
  categories?: Category[];
  monetisation?: Monetisation[];
  servesSampleData?: boolean;
  id?: string;
}): AdSource {
  const products = options.products ?? [];
  const brandAds = options.brandAds ?? [];

  return {
    id: options.id ?? 'in-memory',
    servesSampleData: options.servesSampleData ?? false,
    monetisation: options.monetisation ?? ['affiliate'],
    supportedFilters: async () => ({ categories: options.categories ?? [] }),
    searchCandidates: async () => {
      const candidates: Candidate[] = [
        ...products.map((product) => ({ kind: 'product' as const, product })),
        ...brandAds.map((brandAd) => ({ kind: 'brand_ad' as const, brandAd })),
      ];
      return candidates;
    },
    getProduct: async (id) => products.find((product) => product.id === id) ?? null,
  };
}

export function offer(overrides: Partial<Offer> & { id: string }): Offer {
  return {
    merchant: 'Test Merchant',
    price: { minorUnits: 1000, currency: 'USD' },
    shipsTo: ['US', 'GB', 'AE', 'LB'],
    url: `https://example.com/${overrides.id}`,
    monetisation: 'affiliate',
    availability: 'in_stock',
    ...overrides,
  };
}

export function product(id: string, overrides: Partial<Product> = {}): Product {
  return {
    id,
    title: `Product ${id}`,
    description: `Test product ${id}`,
    brand: 'Test Brand',
    category: 'sneakers',
    attributes: {},
    media: [{ kind: 'image', url: `https://example.com/${id}.jpg` }],
    offers: [offer({ id: `offer-${id}` })],
    ...overrides,
  };
}

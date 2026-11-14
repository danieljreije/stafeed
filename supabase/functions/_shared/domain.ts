// The catalog as the backend sees it. Words follow CONTEXT.md: a Product is
// a thing someone can buy, an Offer is one Merchant's terms for it, and a
// Feed Item is one full-screen card.

/** How Stafeed earns from something it shows (spec, Seam 2). */
export type Monetisation = 'sponsored' | 'affiliate' | 'pay_per_click' | 'none';

/** An amount in integer minor units (e.g. cents) plus an ISO 4217 code. */
export interface Money {
  readonly minorUnits: number;
  readonly currency: string;
}

/** One picture or clip, shown in order. */
export type Media =
  | { readonly kind: 'image'; readonly url: string }
  | { readonly kind: 'video'; readonly url: string; readonly posterUrl?: string };

export type Availability = 'in_stock' | 'out_of_stock';

/** One Merchant's terms for a Product. */
export interface Offer {
  readonly id: string;
  /** The seller the Shopper is handed off to. */
  readonly merchant: string;
  readonly price: Money;
  /** ISO 3166-1 alpha-2 codes of the countries this Offer ships to. */
  readonly shipsTo: readonly string[];
  /** Where the Merchant Handoff goes, exactly as the source gave it. */
  readonly url: string;
  /** `none` means the Offer earns nothing: Not an Ad. */
  readonly monetisation: Monetisation;
  readonly availability: Availability;
}

/** A thing someone can buy, independent of who sells it. */
export interface Product {
  readonly id: string;
  readonly title: string;
  readonly description: string;
  /** The maker, not the Merchant. */
  readonly brand: string;
  /** Category ID, as listed in the source's supported filters. */
  readonly category: string;
  readonly attributes: Readonly<Record<string, string>>;
  readonly media: readonly Media[];
  readonly offers: readonly Offer[];
}

/** An ad creative supplied by a Brand with permission. Always Sponsored. */
export interface BrandAd {
  readonly id: string;
  readonly brand: string;
  /** The ad's own words, shown unedited. */
  readonly headline: string;
  readonly media: readonly Media[];
  /** The Products it links to, shown as chips. */
  readonly products: readonly Product[];
}

export interface Category {
  readonly id: string;
  readonly label: string;
}

/** The filters a source actually supports, so the app only offers real ones. */
export interface SupportedFilters {
  readonly categories: readonly Category[];
}

/** A Product as a Feed Item shows it: without the Offers it didn't choose. */
export type ProductSummary = Omit<Product, 'offers'>;

/**
 * One full-screen card. For You only holds Ads (ADR-0002): Affiliate Ads and
 * Brand Ads. Not an Ad exists for Shopping Sessions and is never in For You.
 */
export type FeedItem =
  | {
      readonly kind: 'affiliate_ad';
      readonly id: string;
      readonly label: 'AD';
      readonly sponsored: false;
      readonly product: ProductSummary;
      readonly offer: Offer;
    }
  | {
      readonly kind: 'brand_ad';
      readonly id: string;
      readonly label: 'AD';
      readonly sponsored: true;
      readonly brand: string;
      readonly headline: string;
      readonly media: readonly Media[];
      readonly products: readonly ProductSummary[];
    }
  | {
      readonly kind: 'not_an_ad';
      readonly id: string;
      readonly label: 'NOT AN AD';
      readonly sponsored: false;
      readonly product: ProductSummary;
      readonly offer: Offer;
    };

/** An Offer that earns Stafeed money and can be bought today. */
export function isAdOffer(offer: Offer): boolean {
  return offer.monetisation !== 'none' && offer.availability === 'in_stock';
}

export function summarise(product: Product): ProductSummary {
  return {
    id: product.id,
    title: product.title,
    description: product.description,
    brand: product.brand,
    category: product.category,
    attributes: product.attributes,
    media: product.media,
  };
}

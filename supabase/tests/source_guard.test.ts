import { describe, expect, it } from 'vitest';

import { PROHIBITED_CATEGORIES } from '../functions/_shared/prohibited.ts';
import { guardSource } from '../functions/_shared/source_guard.ts';
import { inMemorySource, offer, product } from './support/in_memory_source.ts';

const query = { destinationCountry: 'GB', category: null, query: '' };

describe('ad source boundary', () => {
  it("lists the spec's prohibited categories", () => {
    expect([...PROHIBITED_CATEGORIES].sort()).toEqual([
      'adult',
      'counterfeits',
      'dangerous-goods',
      'drugs',
      'gambling',
      'tobacco',
      'weapons',
    ]);
  });

  it('drops Products in a prohibited category, whatever the source says', async () => {
    const guarded = guardSource(
      inMemorySource({
        products: [product('ok'), product('knife', { category: 'weapons' })],
        categories: [
          { id: 'sneakers', label: 'Sneakers' },
          { id: 'weapons', label: 'Weapons' },
        ],
      }),
    );

    const candidates = await guarded.searchCandidates(query);
    expect(candidates.map((c) => (c.kind === 'product' ? c.product.id : ''))).toEqual(['ok']);
    expect(await guarded.getProduct('knife', 'GB')).toBeNull();
    expect((await guarded.supportedFilters()).categories.map((c) => c.id)).toEqual(['sneakers']);
  });

  it('keeps only Offers that ship to the Destination Country, even if the source forgot', async () => {
    const guarded = guardSource(
      inMemorySource({
        products: [
          product('mixed', {
            offers: [offer({ id: 'us', shipsTo: ['US'] }), offer({ id: 'gb', shipsTo: ['GB'] })],
          }),
          product('us-only', { offers: [offer({ id: 'us2', shipsTo: ['US'] })] }),
        ],
      }),
    );

    const candidates = await guarded.searchCandidates(query);
    expect(candidates).toHaveLength(1);
    const [first] = candidates;
    expect(first?.kind === 'product' && first.product.offers.map((o) => o.id)).toEqual(['gb']);
    expect(await guarded.getProduct('us-only', 'GB')).toBeNull();
    expect((await guarded.getProduct('mixed', 'GB'))?.offers.map((o) => o.id)).toEqual(['gb']);
  });

  it('trims a Brand Ad to its allowed Products and drops it when none are left', async () => {
    const guarded = guardSource(
      inMemorySource({
        brandAds: [
          {
            id: 'kept',
            brand: 'B',
            headline: 'h',
            media: [],
            products: [product('a'), product('gun', { category: 'weapons' })],
          },
          {
            id: 'gone',
            brand: 'B',
            headline: 'h',
            media: [],
            products: [product('u', { offers: [offer({ id: 'u', shipsTo: ['US'] })] })],
          },
        ],
      }),
    );

    const candidates = await guarded.searchCandidates(query);
    expect(candidates).toHaveLength(1);
    const [kept] = candidates;
    expect(kept?.kind === 'brand_ad' && kept.brandAd.products.map((p) => p.id)).toEqual(['a']);
  });
});

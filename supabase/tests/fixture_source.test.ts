import { describe, expect, it } from 'vitest';

import type { Candidate } from '../functions/_shared/ad_source.ts';
import { FixtureSource } from '../functions/_shared/fixture_source.ts';

const all = { destinationCountry: 'US', category: null, query: '' };

const ids = (candidates: readonly Candidate[]) =>
  candidates.map((c) => (c.kind === 'product' ? c.product.id : c.brandAd.id));

describe('Fixture source', () => {
  const source = new FixtureSource();

  it('is labelled as sample data and declares how its candidates earn', () => {
    expect(source.servesSampleData).toBe(true);
    expect([...source.monetisation].sort()).toEqual(['affiliate', 'none', 'sponsored']);
  });

  it('mirrors the app Fixtures: 56 Products in 5 categories and 3 Brand Ads', async () => {
    const filters = await source.supportedFilters();
    expect(filters.categories.map((c) => c.id)).toEqual([
      'sneakers',
      'bags',
      'watches',
      'tech-accessories',
      'home-decor',
    ]);

    // Every Fixture ships somewhere among the onboarding countries.
    const products = new Set<string>();
    const brandAds = new Set<string>();
    for (const destinationCountry of ['US', 'GB', 'AE', 'LB']) {
      for (const c of await source.searchCandidates({ ...all, destinationCountry })) {
        if (c.kind === 'product') products.add(c.product.id);
        else brandAds.add(c.brandAd.id);
      }
    }
    expect(products.size).toBe(56);
    expect(brandAds.size).toBe(3);
  });

  it('puts each Brand Ad right after the last of its linked Products', async () => {
    const order = ids(await source.searchCandidates(all));
    const northstar = order.indexOf('fixture-brand-ad-northstar');
    // Northstar links snk-01 and snk-04; both ship to the US.
    expect(order[northstar - 1]).toBe('fixture-snk-04');
  });

  it('only offers candidates with an Offer shipping to the Destination Country', async () => {
    const gb = await source.searchCandidates({ ...all, destinationCountry: 'GB' });
    for (const candidate of gb) {
      const products =
        candidate.kind === 'product' ? [candidate.product] : candidate.brandAd.products;
      for (const p of products) {
        expect(p.offers.some((o) => o.shipsTo.includes('GB'))).toBe(true);
      }
    }
    expect(ids(gb)).not.toContain('fixture-snk-04'); // US only
    expect(ids(gb)).toContain('fixture-snk-03'); // UK only
  });

  it('filters by category and by search words across title, Brand, category and style', async () => {
    const watches = await source.searchCandidates({ ...all, category: 'watches' });
    expect(watches.length).toBeGreaterThan(0);
    for (const c of watches) {
      const products = c.kind === 'product' ? [c.product] : c.brandAd.products;
      expect(products.some((p) => p.category === 'watches')).toBe(true);
    }

    const running = ids(await source.searchCandidates({ ...all, query: 'northstar RUNNING' }));
    expect(running).toEqual(['fixture-snk-01', 'fixture-snk-04', 'fixture-brand-ad-northstar']);

    // A Brand Ad matches through its own headline.
    const dawn = ids(await source.searchCandidates({ ...all, query: 'dawn' }));
    expect(dawn).toEqual(['fixture-brand-ad-northstar']);
  });

  it('returns a fresh copy of a Product, or null when it is unknown', async () => {
    const p = await source.getProduct('fixture-snk-01');
    expect(p?.title).toBe('Air Runner');
    expect(p?.offers[0]?.price).toEqual({ minorUnits: 12900, currency: 'USD' });
    expect(await source.getProduct('nope')).toBeNull();
  });
});

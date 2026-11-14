// API tests for GET /v1/feed: they call the real Edge Function handler with
// the Fixture source plugged in, the way Supabase would.

import { describe, expect, it } from 'vitest';

import type { AdSource } from '../functions/_shared/ad_source.ts';
import type { FeedItem } from '../functions/_shared/domain.ts';
import { createFeedHandler } from '../functions/_shared/feed_handler.ts';
import { FixtureSource } from '../functions/_shared/fixture_source.ts';
import fixtures from '../functions/_shared/fixtures/fixtures.json' with { type: 'json' };
import { inMemorySource, product } from './support/in_memory_source.ts';

interface FeedBody {
  items: FeedItem[];
  nextCursor: string | null;
  servesSampleData: boolean;
}

interface ErrorBody {
  error: { code: string; message: string };
}

function feed(sources: AdSource[] = [new FixtureSource()], pageSize = 10) {
  return createFeedHandler({ sources, pageSize });
}

async function get(
  handler: (request: Request) => Promise<Response>,
  params: Record<string, string>,
): Promise<{ status: number; body: FeedBody & ErrorBody; response: Response }> {
  const url = new URL('https://project.supabase.co/functions/v1/feed');
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value);
  const response = await handler(new Request(url));
  return { status: response.status, body: await response.json(), response };
}

/** Every Feed Item of a feed, following cursors to the end. */
async function allItems(
  handler: (request: Request) => Promise<Response>,
  params: Record<string, string>,
): Promise<FeedItem[]> {
  const items: FeedItem[] = [];
  let cursor: string | null = null;
  for (let page = 0; page < 50; page++) {
    const { status, body } = await get(handler, cursor ? { ...params, cursor } : params);
    expect(status).toBe(200);
    items.push(...body.items);
    cursor = body.nextCursor;
    if (cursor === null) return items;
  }
  throw new Error('feed never ended');
}

/** Fixture Product IDs with an in-stock, earning Offer shipping to [country]. */
function adProductIds(country: string): string[] {
  return fixtures.products
    .filter((p) =>
      p.offers.some(
        (o) =>
          o.monetisation !== 'none' &&
          o.availability === 'in_stock' &&
          o.shipsTo.includes(country),
      ),
    )
    .map((p) => p.id);
}

const productIdsOf = (items: FeedItem[]) =>
  items.flatMap((item) => (item.kind === 'brand_ad' ? [] : [item.product.id]));

describe('GET /v1/feed', () => {
  it('serves the first page of For You with an opaque cursor', async () => {
    const { status, body, response } = await get(feed(), { country: 'US' });

    expect(status).toBe(200);
    expect(response.headers.get('content-type')).toContain('application/json');
    expect(body.items).toHaveLength(10);
    expect(body.servesSampleData).toBe(true);
    expect(typeof body.nextCursor).toBe('string');
    expect(body.nextCursor).not.toMatch(/^\d+$/);
  });

  it('pages through every Ad once, then ends', async () => {
    const items = await allItems(feed(), { country: 'US' });

    const ids = items.map((item) => item.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(productIdsOf(items).sort()).toEqual(adProductIds('US').sort());
    expect(items.filter((item) => item.kind === 'brand_ad').map((item) => item.id)).toEqual([
      'fixture-brand-ad-northstar',
      'fixture-brand-ad-orbitline',
      'fixture-brand-ad-brightmoor',
    ]);
  });

  it('only holds Ads, each labelled AD; Not an Ad and out-of-stock Products never show', async () => {
    const items = await allItems(feed(), { country: 'US' });

    for (const item of items) {
      expect(item.label).toBe('AD');
      expect(item.kind).not.toBe('not_an_ad');
      expect(item.sponsored).toBe(item.kind === 'brand_ad');
      if (item.kind === 'affiliate_ad') {
        expect(item.offer.monetisation).not.toBe('none');
        expect(item.offer.availability).toBe('in_stock');
        // The Feed Item shows one chosen Offer, not the Product's list.
        expect(item.product).not.toHaveProperty('offers');
      }
    }
    const ids = productIdsOf(items);
    expect(ids).not.toContain('fixture-snk-06'); // Not an Ad
    expect(ids).not.toContain('fixture-wat-08'); // out of stock
  });

  it('never serves an Offer that does not ship to the Destination Country', async () => {
    for (const country of ['US', 'GB', 'AE', 'LB']) {
      const items = await allItems(feed(), { country });
      expect(productIdsOf(items).sort()).toEqual(adProductIds(country).sort());
      for (const item of items) {
        if (item.kind === 'affiliate_ad') expect(item.offer.shipsTo).toContain(country);
      }
    }
  });

  it('accepts a lower-case country code', async () => {
    const lower = await allItems(feed(), { country: 'gb' });
    const upper = await allItems(feed(), { country: 'GB' });
    expect(lower).toEqual(upper);
  });

  it('links a Brand Ad only to the Products that are in the feed there', async () => {
    const items = await allItems(feed(), { country: 'GB' });
    const northstar = items.find((item) => item.id === 'fixture-brand-ad-northstar');

    expect(northstar?.kind).toBe('brand_ad');
    if (northstar?.kind !== 'brand_ad') return;
    // snk-04 only ships to the US.
    expect(northstar.products.map((p) => p.id)).toEqual(['fixture-snk-01']);
    expect(northstar.headline).toBe('Lace up. The sample run club leaves at dawn.');
  });

  it('filters by category and search, and keeps the filter across pages', async () => {
    const watches = await allItems(feed([new FixtureSource()], 2), {
      country: 'US',
      category: 'watches',
    });
    expect(watches.length).toBeGreaterThan(2);
    for (const item of watches) {
      if (item.kind !== 'brand_ad') expect(item.product.category).toBe('watches');
    }

    const search = await allItems(feed(), { country: 'US', q: 'northstar running' });
    expect(search.map((item) => item.id)).toEqual([
      'fixture-snk-01',
      'fixture-snk-04',
      'fixture-brand-ad-northstar',
    ]);
  });

  it('serves an empty feed with no cursor when nothing matches', async () => {
    const { status, body } = await get(feed(), { country: 'US', q: 'zzzz nothing' });
    expect(status).toBe(200);
    expect(body.items).toEqual([]);
    expect(body.nextCursor).toBeNull();
  });

  it('refuses a cursor issued for another feed, or one it never issued', async () => {
    const first = await get(feed(), { country: 'US' });
    const cursor = first.body.nextCursor ?? '';

    for (const params of [
      { country: 'GB', cursor },
      { country: 'US', category: 'bags', cursor },
      { country: 'US', q: 'tote', cursor },
      { country: 'US', cursor: 'not-a-cursor' },
      { country: 'US', cursor: `${cursor}x` },
    ]) {
      const { status, body } = await get(feed(), params);
      expect(status).toBe(400);
      expect(body.error.code).toBe('invalid_cursor');
    }
  });

  it('asks for a valid Destination Country', async () => {
    for (const params of [{}, { country: 'USA' }, { country: '1' }]) {
      const { status, body } = await get(feed(), params);
      expect(status).toBe(400);
      expect(body.error.code).toBe('invalid_country');
    }
  });

  it('refuses a category the sources do not support', async () => {
    const { status, body } = await get(feed(), { country: 'US', category: 'weapons' });
    expect(status).toBe(400);
    expect(body.error.code).toBe('unsupported_filter');
  });

  it('says Shopping Sessions are not served yet instead of ignoring sessionId', async () => {
    const { status, body } = await get(feed(), { country: 'US', sessionId: 'abc' });
    expect(status).toBe(400);
    expect(body.error.code).toBe('sessions_not_supported');
  });

  it('filters prohibited categories out of every source', async () => {
    const source = inMemorySource({
      products: [product('ok'), product('vape', { category: 'tobacco' })],
      categories: [{ id: 'sneakers', label: 'Sneakers' }],
    });
    const items = await allItems(feed([source]), { country: 'US' });
    expect(items.map((item) => item.id)).toEqual(['ok']);
  });

  it('merges several sources in order without repeating a Feed Item', async () => {
    const a = inMemorySource({ id: 'a', products: [product('one'), product('two')] });
    const b = inMemorySource({ id: 'b', products: [product('two'), product('three')] });
    const items = await allItems(feed([a, b], 2), { country: 'US' });
    expect(items.map((item) => item.id)).toEqual(['one', 'two', 'three']);
  });

  it('answers a failing source with the usual JSON error shape', async () => {
    const broken: AdSource = {
      ...inMemorySource({}),
      searchCandidates: async () => {
        throw new Error('source down');
      },
    };
    const { status, body, response } = await get(feed([broken]), { country: 'US' });
    expect(status).toBe(500);
    expect(body.error.code).toBe('internal_error');
    expect(response.headers.get('access-control-allow-origin')).toBe('*');
  });

  it('only answers GET, plus CORS preflight', async () => {
    const handler = feed();
    const post = await handler(
      new Request('https://project.supabase.co/functions/v1/feed?country=US', { method: 'POST' }),
    );
    expect(post.status).toBe(405);
    expect(((await post.json()) as ErrorBody).error.code).toBe('method_not_allowed');

    const preflight = await handler(
      new Request('https://project.supabase.co/functions/v1/feed', { method: 'OPTIONS' }),
    );
    expect(preflight.status).toBe(204);
    expect(preflight.headers.get('access-control-allow-origin')).toBe('*');
  });
});

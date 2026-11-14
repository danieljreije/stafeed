// API tests for GET /v1/config: the real Edge Function handler with the
// Fixture source plugged in.

import { describe, expect, it } from 'vitest';

import { createConfigHandler } from '../functions/_shared/config_handler.ts';
import { FixtureSource } from '../functions/_shared/fixture_source.ts';
import { inMemorySource } from './support/in_memory_source.ts';

const url = 'https://project.supabase.co/functions/v1/config';

describe('GET /v1/config', () => {
  it('tells the app what it can offer the Shopper', async () => {
    const handler = createConfigHandler({ sources: [new FixtureSource()], feedPageSize: 10 });
    const response = await handler(new Request(url));

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('application/json');
    expect(await response.json()).toEqual({
      apiVersion: 1,
      servesSampleData: true,
      destinationCountries: ['US', 'GB', 'AE', 'LB'],
      currencies: ['USD', 'GBP', 'EUR', 'AED'],
      supportedFilters: {
        query: true,
        categories: [
          { id: 'sneakers', label: 'Sneakers' },
          { id: 'bags', label: 'Bags' },
          { id: 'watches', label: 'Watches' },
          { id: 'tech-accessories', label: 'Tech accessories' },
          { id: 'home-decor', label: 'Home decor' },
        ],
      },
      feedPageSize: 10,
    });
  });

  it('only lists real, allowed categories across all sources, once each', async () => {
    const handler = createConfigHandler({
      sources: [
        inMemorySource({
          categories: [
            { id: 'bags', label: 'Bags' },
            { id: 'weapons', label: 'Weapons' },
          ],
        }),
        inMemorySource({
          categories: [
            { id: 'bags', label: 'Bags' },
            { id: 'watches', label: 'Watches' },
          ],
        }),
      ],
      feedPageSize: 10,
    });
    const body = (await (await handler(new Request(url))).json()) as {
      servesSampleData: boolean;
      supportedFilters: { categories: { id: string }[] };
    };

    expect(body.servesSampleData).toBe(false);
    expect(body.supportedFilters.categories.map((c) => c.id)).toEqual(['bags', 'watches']);
  });

  it('only answers GET, plus CORS preflight', async () => {
    const handler = createConfigHandler({ sources: [new FixtureSource()], feedPageSize: 10 });

    const post = await handler(new Request(url, { method: 'POST' }));
    expect(post.status).toBe(405);

    const preflight = await handler(new Request(url, { method: 'OPTIONS' }));
    expect(preflight.status).toBe(204);
  });
});

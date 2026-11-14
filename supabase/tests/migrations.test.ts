// The versioned migrations apply cleanly to an empty Postgres (PGlite, an
// in-process Postgres, so no live Supabase project is needed), and the
// schema holds the whole Fixture catalog.

/// <reference types="node" />

import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { PGlite } from '@electric-sql/pglite';
import { beforeEach, describe, expect, it } from 'vitest';

import fixtures from '../functions/_shared/fixtures/fixtures.json' with { type: 'json' };
import { PROHIBITED_CATEGORIES } from '../functions/_shared/prohibited.ts';

const migrationsDir = fileURLToPath(new URL('../migrations/', import.meta.url));

function migrationFiles(): string[] {
  return readdirSync(migrationsDir)
    .filter((name) => name.endsWith('.sql'))
    .sort();
}

async function migratedDb(): Promise<PGlite> {
  const db = new PGlite();
  for (const name of migrationFiles()) {
    await db.exec(readFileSync(join(migrationsDir, name), 'utf8'));
  }
  return db;
}

async function loadFixtures(db: PGlite): Promise<void> {
  for (const category of fixtures.categories) {
    await db.query('insert into categories (id, label) values ($1, $2)', [
      category.id,
      category.label,
    ]);
  }
  for (const p of fixtures.products) {
    await db.query('insert into brands (id, name) values ($1, $1) on conflict do nothing', [
      p.brand,
    ]);
    await db.query(
      `insert into products (id, source, title, description, brand_id, category_id, attributes)
       values ($1, 'fixtures', $2, $3, $4, $5, $6)`,
      [p.id, p.title, p.description, p.brand, p.category, JSON.stringify(p.attributes)],
    );
    for (const [position, media] of p.media.entries()) {
      await db.query(
        `insert into media_assets (product_id, position, kind, url, source, rights)
         values ($1, $2, $3, $4, 'fixtures', 'Sample image from picsum.photos')`,
        [p.id, position, media.kind, media.url],
      );
    }
    for (const o of p.offers) {
      await db.query('insert into merchants (id, name) values ($1, $1) on conflict do nothing', [
        o.merchant,
      ]);
      await db.query(
        `insert into offers (id, product_id, merchant_id, price_minor, currency, availability,
                             ships_to, destination_url, monetisation)
         values ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          o.id,
          p.id,
          o.merchant,
          o.price.minorUnits,
          o.price.currency,
          o.availability,
          o.shipsTo,
          o.url,
          o.monetisation,
        ],
      );
    }
  }
}

describe('migrations', () => {
  let db: PGlite;

  beforeEach(async () => {
    db = await migratedDb();
  });

  it('are named so they apply in order', () => {
    const files = migrationFiles();
    expect(files.length).toBeGreaterThan(0);
    for (const name of files) expect(name).toMatch(/^\d{14}_[a-z0-9_]+\.sql$/);
  });

  it('create the catalog tables, each with row level security on', async () => {
    const { rows } = await db.query<{ relname: string; relrowsecurity: boolean }>(
      `select relname, relrowsecurity from pg_class
       where relnamespace = 'public'::regnamespace and relkind = 'r' order by relname`,
    );
    expect(rows.map((r) => r.relname)).toEqual([
      'brands',
      'categories',
      'media_assets',
      'merchants',
      'offers',
      'products',
    ]);
    for (const row of rows) expect(row.relrowsecurity).toBe(true);
  });

  it('mark the prohibited categories', async () => {
    const { rows } = await db.query<{ id: string }>(
      'select id from categories where prohibited order by id',
    );
    expect(rows.map((r) => r.id)).toEqual([...PROHIBITED_CATEGORIES].sort());
  });

  it('hold the whole Fixture catalog', async () => {
    await loadFixtures(db);

    const count = async (table: string) =>
      (await db.query<{ n: number }>(`select count(*)::int as n from ${table}`)).rows[0]?.n;
    expect(await count('products')).toBe(56);
    expect(await count('offers')).toBe(56);
    expect(await count('media_assets')).toBe(56);

    const { rows } = await db.query<{ ships_to: string[]; price_minor: number }>(
      "select ships_to, price_minor from offers where id = 'fixture-offer-snk-02'",
    );
    expect(rows[0]).toEqual({ ships_to: ['US', 'GB'], price_minor: 14500 });
  });

  it('refuse Offers that would break the domain rules', async () => {
    await loadFixtures(db);
    const insert = (overrides: Record<string, unknown>) => {
      const row = {
        id: 'bad',
        product_id: 'fixture-snk-01',
        merchant_id: 'Sample Outfitters',
        price_minor: 100,
        currency: 'USD',
        availability: 'in_stock',
        ships_to: ['US'],
        destination_url: 'https://example.com/x',
        monetisation: 'affiliate',
        ...overrides,
      };
      return db.query(
        `insert into offers (id, product_id, merchant_id, price_minor, currency, availability,
                             ships_to, destination_url, monetisation)
         values ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        Object.values(row),
      );
    };

    await expect(insert({ price_minor: -1 })).rejects.toThrow();
    await expect(insert({ currency: 'usd' })).rejects.toThrow();
    await expect(insert({ currency: 'DOLLAR' })).rejects.toThrow();
    await expect(insert({ ships_to: ['USA'] })).rejects.toThrow();
    await expect(insert({ ships_to: [] })).rejects.toThrow();
    await expect(insert({ monetisation: 'free' })).rejects.toThrow();
    await expect(insert({ availability: 'maybe' })).rejects.toThrow();
    await expect(insert({ destination_url: 'ftp://example.com' })).rejects.toThrow();
    await expect(insert({ product_id: 'missing' })).rejects.toThrow();
    await expect(insert({})).resolves.toBeDefined();
  });

  it('keep updated_at current when a row changes', async () => {
    await loadFixtures(db);
    await db.query("update offers set updated_at = now() - interval '1 day' where id = 'fixture-offer-snk-01'");
    await db.query("update offers set price_minor = 1 where id = 'fixture-offer-snk-01'");
    const { rows } = await db.query<{ fresh: boolean }>(
      "select updated_at > now() - interval '1 minute' as fresh from offers where id = 'fixture-offer-snk-01'",
    );
    expect(rows[0]?.fresh).toBe(true);
  });

  it('remove a Product’s Offers and media with it', async () => {
    await loadFixtures(db);
    await db.query("delete from products where id = 'fixture-snk-01'");
    const { rows } = await db.query<{ n: number }>(
      `select (select count(*) from offers where product_id = 'fixture-snk-01')
            + (select count(*) from media_assets where product_id = 'fixture-snk-01') as n`,
    );
    expect(Number(rows[0]?.n)).toBe(0);
  });
});

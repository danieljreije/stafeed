-- Catalog: Brands, Merchants, categories, Products, Offers and media assets
-- (ticket #15). Words follow CONTEXT.md. Prices are integer minor units plus
-- an ISO 4217 code, never floating point.
--
-- Row level security is on for every table with no policies yet, so the
-- public (anon) key reads nothing directly; the Edge Functions read the
-- catalog server-side. Shopper-owned tables and their policies come with #17.

create table brands (
  id text primary key,
  name text not null,
  created_at timestamptz not null default now()
);

create table merchants (
  id text primary key,
  name text not null,
  created_at timestamptz not null default now()
);

create table categories (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  label text not null,
  -- Never shown (spec user story 80). Keep in step with
  -- functions/_shared/prohibited.ts.
  prohibited boolean not null default false
);

insert into categories (id, label, prohibited) values
  ('adult', 'Adult', true),
  ('weapons', 'Weapons', true),
  ('tobacco', 'Tobacco', true),
  ('drugs', 'Drugs', true),
  ('counterfeits', 'Counterfeits', true),
  ('gambling', 'Gambling', true),
  ('dangerous-goods', 'Dangerous goods', true);

create table products (
  -- Stable ID from the source.
  id text primary key,
  -- The ad source it came from, e.g. 'fixtures', 'awin'.
  source text not null,
  title text not null,
  description text not null default '',
  brand_id text not null references brands (id),
  category_id text not null references categories (id),
  attributes jsonb not null default '{}'::jsonb
    check (jsonb_typeof(attributes) = 'object'),
  status text not null default 'active'
    check (status in ('active', 'hidden', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_category_idx on products (category_id) where status = 'active';

create table offers (
  id text primary key,
  product_id text not null references products (id) on delete cascade,
  merchant_id text not null references merchants (id),
  price_minor bigint not null check (price_minor >= 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  availability text not null check (availability in ('in_stock', 'out_of_stock')),
  -- ISO 3166-1 alpha-2 codes. An Offer that ships nowhere is never shown,
  -- so it isn't stored either.
  ships_to text[] not null
    check (cardinality(ships_to) > 0 and array_to_string(ships_to, ',') ~ '^[A-Z]{2}(,[A-Z]{2})*$'),
  -- Where the Merchant Handoff goes, kept exactly as the source gave it.
  destination_url text not null check (destination_url ~ '^https?://'),
  -- 'none' earns nothing: Not an Ad.
  monetisation text not null
    check (monetisation in ('sponsored', 'affiliate', 'pay_per_click', 'none')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index offers_product_idx on offers (product_id);
create index offers_ships_to_idx on offers using gin (ships_to);

create table media_assets (
  id bigint generated always as identity primary key,
  product_id text not null references products (id) on delete cascade,
  -- Shown in this order.
  position integer not null check (position >= 0),
  kind text not null check (kind in ('image', 'video')),
  url text not null check (url ~ '^https?://'),
  -- A still shown in place of a video.
  poster_url text check (poster_url is null or kind = 'video'),
  -- Where it came from and on what terms it may be shown.
  source text not null,
  rights text not null,
  unique (product_id, position)
);

-- Keeps updated_at true on every change (imports rely on it to spot stale
-- Products and Offers).
create function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger products_updated_at before update on products
  for each row execute function set_updated_at();
create trigger offers_updated_at before update on offers
  for each row execute function set_updated_at();

alter table brands enable row level security;
alter table merchants enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table offers enable row level security;
alter table media_assets enable row level security;

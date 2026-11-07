# Stafeed — Project Status

_Last updated: 2026-11-07_

Spec: `docs/STAFEED_PRODUCT_SPEC.md` · Plan: `docs/STAFEED_ROADMAP.md`

## Current milestone
**M1 — Reliable fixture feed** (not started)

## Completed
- Prototype: vertical PageView feed, product card, debounced search, category chips, offset pagination with retry, saved IDs persisted locally.
- Repository audit and roadmap written (code reading only).

## Blocked / needs you
- Shopify Global Catalog MCP access (agent profile / eligibility): not applied — blocks real inventory.
- Awin publisher approval: not applied — blocks affiliate inventory and revenue.
- Launch country/currency: undecided.

## Not yet verified
- `flutter analyze`, `flutter test`, Android build: NOT RUN.
- Git status/history: not inspected.

## Data sources
| Source | Status |
|---|---|
| Fixtures | Present but unusable (3 items, mismatched categories) — fix in M1 |
| DummyJSON | Active default — **demo data only**, not commercial inventory |
| Shopify Catalog MCP | Not integrated — access unverified |
| Awin feeds | Not integrated — access unverified |

## Remaining (ordered)
M1 fixture feed → M2 product actions & saved snapshots → M3 app shell & onboarding → M4 sessions, events, ranking → M5 backend (Supabase) → M7 Android beta. M6 provider access runs in parallel.

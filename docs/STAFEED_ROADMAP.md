# Stafeed — Current State, Target Architecture, Roadmap

**Date:** 2026-11-07
**Primary spec:** `docs/STAFEED_PRODUCT_SPEC.md` (product vision & handoff)
**Basis:** Line-by-line read of every file in `lib/` and `test/`, plus `pubspec.yaml` and `docs/`.
**Not done yet:** `flutter analyze`, `flutter test`, and builds have **not** been run (no Flutter toolchain was reachable from the review environment). Git status/history not inspected. Treat runtime claims below as code-reading findings until verified on a device.

---

## 1. Current application state

### Stack (from pubspec.yaml)
Flutter/Dart, `flutter_riverpod ^3.4.3`, `http ^1.6.0`, `shared_preferences ^2.5.5`. Platforms scaffolded: android, ios, web, windows, macos, linux. Navigation: plain `Navigator.push`.

### What exists and works (by code reading)

| Area | Status | Notes |
|---|---|---|
| App root | Works | `StafeedApp` lives in `main.dart`; `app/stafeed_app.dart` is an empty file. |
| Home screen | Works | Landing page with "Start Exploring" and "Saved Products" buttons. Not the spec's tab navigation. |
| Vertical feed | Works | `PageView.builder` vertical, one product per page. |
| Product card | Partial | Image, brand, category, name, price, Save. Image error fallback present. |
| Pagination | Works, with gaps | Page size 10, offset-based, `isLoadingMore` gate, de-dupe by ID, next offset uses raw count (correct), inline "Retry loading". Trigger `index >= length - 3`. |
| Search | Works | Debounced 500 ms, synced with filter state. |
| Category chips | Works on DummyJSON only | Hard-coded DummyJSON slugs (`mens-shoes`, `smartphones`, …). |
| Saved | Partial | Saved IDs persist across restarts (SharedPreferencesAsync). |
| Data source | **Demo inventory** | `productRepositoryProvider` is hard-wired to **DummyJSON** (public demo API). Fixture repo exists but is not selectable. |
| Tests | Minimal | One widget test for the home screen. |

Earlier course-review bugs that are now **fixed**: `Positioned` inside `Column`, duplicate `@override`, `==` pagination threshold.

### Broken or non-compliant vs the spec

| # | Problem | Where | Spec ref |
|---|---|---|---|
| B1 | Empty result replaces the whole screen with a bare `Scaffold` → search field and chips disappear; user is stuck. | `feed_screen.dart` | §5.3, §5.5 |
| B2 | Initial load error shows raw `error.toString()` with **no retry** and no filters. | `feed_screen.dart` | §5.3 |
| B3 | Saved screen only shows saved items that are in the **currently loaded feed page**; after restart or filter change, saved items vanish. | `saved_screen.dart` | §5.7 |
| B4 | Fixture repo unusable: 3 items, categories `Shoes`/`Watches` don't match chip slugs, so every chip returns empty. Can't test pagination. | `fixture_product_repository.dart`, `sample_products.dart` | §10 "deterministic fixture mode" |
| B5 | Price always shows `$`, ignores `currencyCode`. | `product_card.dart` | §3.6, §13 |
| B6 | Stale-write guard uses `identical(filter)`. Works for filter changes, but a future refresh/retry with the same filter instance lets an old `loadMore` overwrite fresh data. No refresh exists yet. | `paginated_products_provider.dart` | §5.5 |
| B7 | `toggleProduct` uses `requireValue` (throws while loading) and has no error handling on write. | `saved_products_provider.dart` | — |
| B8 | Nested `Scaffold`s inside the feed; duplicate `import 'dart:async'` (analyzer warning); unused `productsProvider`. | various | hygiene |

### Missing vs the consumer MVP (§10)

Product model has no merchant, merchant URL, description, multiple images/video, offers, sponsored/affiliate flags. Missing entirely: product details, View at merchant, Share, Not interested, Report, Sponsored label, onboarding (country/currency/interests), tab navigation (Feed/Search/Saved/Profile), shopping sessions, settings, event tracking, ranking, backend, auth.

### Demo vs real inventory

- **DummyJSON** = public demo data. Not commercial inventory, no merchant links, no rights. Keep only as an optional dev source, clearly labelled.
- **Fixtures** = the required deterministic mode (§10, §17). Needs rebuilding around sneakers.
- **Real sources** (Shopify Global Catalog MCP, Awin) = **not verified, no credentials**. Nothing is integrated.

---

## 2. Target product architecture

Keep Flutter + Riverpod + `lib/app/features/`. Add only what the MVP needs.

### Mobile (lib/)

```text
lib/
  main.dart                     # ProviderScope + StafeedApp only
  app/
    stafeed_app.dart            # MaterialApp, theme, bottom-nav shell
    config/
      app_config.dart           # DataSourceMode: fixture | dummyjson | api
    core/
      money.dart                # minor units + ISO currency formatting
      failures.dart             # typed, user-safe failure categories
    features/
      catalog/                  # shared domain: no UI
        models/                 # Product, Offer, Merchant, MediaAsset, FeedQuery, FeedPage
        data/
          catalog_repository.dart        # the seam: search(query, cursor) -> FeedPage; getProduct(id)
          fixture_catalog_repository.dart
          dummyjson_catalog_repository.dart   # dev-only, labelled demo
          api_catalog_repository.dart          # later: Stafeed backend
        fixtures/sneakers.dart  # ~40 deterministic items incl. 1–2 "sponsored"
      feed/                     # For You feed screen, card, pagination controller
      search/                   # filters + shopping sessions
      product_detail/           # bottom sheet / page, merchant handoff, share, report
      saved/                    # SavedProduct = id + snapshot; independent of feed
      onboarding/               # country, currency, interests (no sign-up)
      settings/                 # profile/settings, clear history
      events/                   # EventLogger interface; local impl first
      ranking/                  # rule-based reranker (fixture mode first)
```

**The key seam:** `CatalogRepository.search(FeedQuery, cursor) → FeedPage{items, nextCursor}` with an **opaque cursor**. DummyJSON encodes its offset inside the cursor; the future backend returns its own. The UI and pagination controller never see offsets, so swapping sources later is a one-line config change (§11 "opaque feed cursors").

**Pagination controller:** keeps `AsyncNotifier`; adds a generation counter captured per request so stale success/error/finally are dropped (fixes B6), and a refresh that keeps the old list until the new first page arrives.

**Navigation:** a bottom-nav shell (Feed / Search / Saved / Profile) with `IndexedStack`, details via `Navigator`/bottom sheet. Defer `go_router` until deep links are needed (§11 allows this).

**Persistence now:** `shared_preferences` for settings, saved snapshots, not-interested IDs and a local event buffer. Moves to the backend in Phase C.

### Backend (Phase C, not now)
`services/api/`: Node + TypeScript + Fastify + Zod; provider adapters server-side; Supabase Postgres + anonymous Auth + RLS; endpoints as in spec §11. No secrets in the app.

### New packages, add only when the milestone needs them
`url_launcher` (merchant handoff), `share_plus` (share), `cached_network_image` (feed performance), `video_player` (later). Nothing else.

---

## 3. Prioritized roadmap

| Milestone | Goal | Spec phase | Needs credentials? |
|---|---|---|---|
| **M1 — Reliable fixture feed** | Deterministic sneaker fixtures, source switch, cursor-based repo seam, stale-safe pagination, controls survive loading/empty/error, retry, currency formatting, tests. | A | No |
| **M2 — Core product actions** | Richer Product model (merchant, URL, description, images, sponsored/affiliate flags); details sheet; View at merchant (`url_launcher`); Share; Not interested (hidden + persisted); Report (local); Sponsored + affiliate labels; Saved with snapshots, independent of feed. | B | No |
| **M3 — App shell & onboarding** | Bottom nav (Feed/Search/Saved/Profile); first-launch intro, country/currency/interests, no sign-up; settings persisted; clear history. | B | No |
| **M4 — Shopping sessions, events, ranking** | Create/reset/resume intent sessions ("white sneakers under $150") with price/brand/color filters; local event log (`impression`, `view_2s`, `save`, `not_interested`, `outbound_click`…); rule-based reranker with session vs long-term affinities. Passes spec §17 demo 1–13 in fixture mode. | B + E (local) | No |
| **M5 — Backend foundation** | `services/api` + Supabase migrations, anon auth, RLS; feed/saved/events/sessions endpoints with a server fixture adapter; app switches to `api` mode. | C | Supabase project (free tier) |
| **M6 — Provider access spike (start now, in parallel)** | Business tasks for you: apply for Shopify Catalog agent profile / UCP access; apply as Awin publisher; confirm launch country. Engineering: a throwaway adapter against Shopify Catalog MCP once access is granted. | D | **Yes — blocked until approved** |
| **M7 — Personalization & Android beta** | Tune ranking with real events, performance on mid-range Android, privacy/account deletion, closed beta. | E | Play Console |

Phases F (merchant ads) and G (creators) stay out of scope until M7 validates the product.

---

## 4. Next concrete milestone: M1 — Reliable fixture feed

**Outcome:** The app runs fully offline in fixture mode with a believable sneaker feed; filters, search, pagination and errors behave correctly and are covered by tests. No new packages.

### Tasks (in order)
1. **Fixtures:** create ~40 sneaker products (brands, prices $60–$250, categories `sneakers`, `running`, `casual`, `boots`; 2 marked sponsored for later) with stable IDs and placeholder images. Label them clearly as fixtures.
2. **Source switch:** `DataSourceMode` read from `--dart-define=STAFEED_SOURCE=fixture|dummyjson` (default `fixture`). `productRepositoryProvider` picks the implementation. Show a small "Demo data" badge when not on real inventory.
3. **Repository seam:** introduce `FeedQuery` (category, query) and `FeedPage{items, nextCursor}`; fixture and DummyJSON implementations both return opaque cursors. Category chips come from the active source, not hard-coded DummyJSON slugs.
4. **Pagination controller:** generation token per load; drop stale success/error; keep list on load-more failure; `refresh()` keeps old list until success. Typed, user-safe error messages.
5. **Feed screen:** one Scaffold; search + chips always visible; loading, empty ("No matches — clear filters" button) and error ("Couldn't load — Retry") states rendered *under* the controls; pull-to-refresh.
6. **Money:** format with `currencyCode` (intl is bundled with Flutter via `flutter_localizations`; otherwise a small formatter).
7. **Hygiene:** move `StafeedApp` into `stafeed_app.dart`, remove duplicate import and unused `productsProvider`, safe `toggleProduct`.
8. **Tests:** fixture repository (filter, paging, cursor); controller (first page, append, de-dupe, end of list, load-more failure keeps data, retry, filter change mid-append is dropped, refresh mid-append is dropped); widget (empty state keeps controls, error retry works, chips switch feed).

### Done when
- `dart format`, `flutter analyze`, `flutter test` all pass locally; app runs on an Android emulator in fixture mode.
- Swiping 40 items: no duplicates, no double fetches, a quiet end-of-feed.
- Searching nonsense shows an empty state with controls still usable.
- Airplane mode in `dummyjson` mode shows a retry, not a crash.
- `PROJECT_STATUS.md` updated with what ran and what didn't.

### Open questions for you (don't block M1)
1. Launch country / currency for the beta (spec says ask, don't assume).
2. Keep DummyJSON as a dev option, or delete it once fixtures exist?
3. Have you applied to Shopify Catalog access or Awin yet? Approvals are the longest lead time.

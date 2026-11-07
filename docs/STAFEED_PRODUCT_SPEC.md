# STAFEED — PRODUCT VISION & IMPLEMENTATION HANDOFF FOR CLAUDE CODE

**Date:** November 7, 2026  
**Product name:** Stafeed (working name; use `stafeed` in code)  
**Audience:** Claude Code acting as product-minded lead engineer  
**Document type:** Product requirements, system design direction, phased delivery, and acceptance criteria  
**Scope:** The consumer product and future business model. **This is not a Flutter course or lesson plan.**

---

## 0. Instructions to Claude Code

You are joining an existing project named **Stafeed**. Your goal is to help turn the existing Flutter prototype into a credible, production-oriented shopping-discovery product. Treat this document as the intended product vision and high-level functional specification, not proof that any feature or third-party integration already exists.

1. **Inspect the actual repository first.** Identify what exists, what works, what is unfinished, and what differs from this specification. Do not assume previous tutorial examples match local code. Preserve valuable working Flutter/Riverpod code and the real `lib/app/features/` folder structure unless a change has a clear justification.
2. **Implement incrementally**, beginning with a reliable fixture-backed end-to-end experience and then authentic provider integrations. Do not replace the entire codebase without a compelling reason.
3. Distinguish **confirmed requirements**, **product hypotheses**, **future possibilities**, and **external API access still requiring validation**. Never fake provider credentials, API responses, merchant permissions, affiliate earnings, or working tests.
4. Never make scraping or unlicensed republishing of Meta/TikTok/Google ad creatives a dependency. Use only approved/authorized feeds and provider-supported APIs.
5. Secure all keys server-side. The Flutter app must not contain secret advertising, Shopify, affiliate, or Supabase service-role credentials.
6. Prefer simple, maintainable systems. No premature microservices, ML platform, Kafka, Kubernetes, payment gateway, creator payout system, or custom ad auction in the MVP.
7. Before substantial changes, produce a concise implementation plan, an inventory of existing code, a list of access blockers, and an ordered backlog. As work proceeds, execute automated checks and maintain a short `PROJECT_STATUS.md` with completed, blocked, and remaining items.
8. When requirements conflict with actual current provider terms or APIs, prioritize the provider's official, current documentation and flag the deviation.

**Core goal:** Create the fastest useful way for someone to discover products they might buy by swiping through personalized, visually rich product cards, without requiring Stafeed to process the purchase.

---

## 1. One-sentence vision

> **Stafeed is TikTok/Reels-style vertical discovery for shopping intent: tell it what you want to buy, swipe through relevant products and ads, save what you like, and visit the seller to purchase.**

Alternative internal positioning: **“Google for product discovery, with results presented as a personalized vertical feed.”**

The original idea was a feed of *only advertisements* sourced from Meta or Google. Exploration showed that public ad libraries are not general commercial ad redistribution APIs. The evolved product keeps the essence—**the entire feed is commercial discovery, not entertainment interrupted by advertisements**—while sourcing most initial inventory from licensed/authorized product catalogs, affiliate feeds, and participating merchants. Traditional paid ads can become a deliberate part of the experience later.

Do **not** change the product into a generic social network, video entertainment service, or full checkout marketplace.

---

## 2. Problem and hypothesis

A shopper often knows approximately what they want (“white sneakers, roughly $100–$180,” “a stylish desk lamp,” “a gift for a coffee lover”) but does not know which exact product to search for. Current workflows jump among Google, marketplace search grids, brand stores, Instagram/TikTok, reviews, and product links.

**Hypothesis:** When people already have buying intent, a focused, fast, personalized, one-product-at-a-time feed can be more enjoyable and useful than repetitive search-grid browsing.

The core product questions to validate:

- Do people intentionally open an app to browse products, rather than accidentally encounter them amid entertainment?
- How many items do they willingly view per shopping session?
- Can 10–30 interactions meaningfully improve relevance within a single session?
- Do people save items, open details, or visit a merchant without being prompted?
- Can Stafeed earn revenue from attributable commerce before it has enough traffic to sell its own ad campaigns?

These are hypotheses, **not proven claims**. The MVP is for testing them.

---

## 3. Product identity and operating principles

1. **Shopping-first, not entertainment-first.** Every feed item is a real product, an authorized product demo/creator video, or a properly marked sponsored product/ad.
2. **Intent-first discovery.** Users can start an explicit shopping session (“I need running shoes”). Temporary interests in that session should not permanently overwhelm the user's general taste profile.
3. **Universal merchant handoff.** The user should be able to visit a Nike store, small Shopify merchant, affiliate retailer, or regional seller. Stafeed normally does not process the transaction.
4. **Cross-brand and cross-store.** Discover large and small brands in the same feed, subject to catalog access and relevance.
5. **Simple, visual, and fast.** Media dominates the screen; UI controls stay minimal.
6. **Trust and transparency.** Clear prices, merchant identities, availability, affiliate disclosures, and sponsored labels; no disguised promotions.
7. **Respect local availability.** Never assume every product ships to every user; support country/currency and source limitations.
8. **Personalization without an opaque black box at launch.** Start with transparent rules using explicit interests, product metadata, and behavior; evolve toward ML when there is sufficient data.
9. **Build a destination, not another ad interruption.** The user should choose to browse because the feed helps them discover things worth buying.

---

## 4. Primary audiences and roles

### 4.1 Consumer / shopper — launch user

- Browse a For You feed.
- Search or describe a shopping goal in natural language.
- Filter category, budget, brand, color, size, and availability where supported.
- Swipe to discover; save, dismiss, compare later, open details, share, visit merchant.
- Maintain a saved collection and resume past sessions.

### 4.2 Merchant / advertiser — future supply-side user

- Connect a product catalog or upload product data.
- Create/promote shoppable media and product campaigns.
- Select budget, target product/category audiences, and measure impressions, clicks, and attributable outcomes.
- Eventually install a Shopify integration to sync catalog and inventory.

### 4.3 Creator — future supply-side user

- Create product demos/reviews and tag products.
- Participate in brand campaigns and affiliate programs.
- Eventually earn approved commissions or fees.

**Do not build merchant dashboards, creators, or payouts in the first consumer MVP.** Preserve sensible extensibility for them.

---

## 5. Signature user experience

### 5.1 First launch

1. Show concise introduction: “Discover products worth buying. One swipe at a time.”
2. Confirm destination country, preferred currency, and language.
3. Select a few interests/categories, or skip.
4. Enter the feed immediately. **No forced sign-up to browse.**
5. Prefer anonymous authenticated sessions so saved items and behavior have a stable identity; allow optional account upgrade later.

### 5.2 Main navigation

A straightforward structure:

- **Feed** — personalized recommendations.
- **Search / Shop** — shopping sessions, category browsing, filter controls.
- **Saved** — collection of products to revisit.
- **Profile / Settings** — country, currency, preferences, privacy, account.

Keep the navigation and visual identity distinctive from TikTok; do not copy its brand or social engagement mechanics.

### 5.3 Full-screen vertical feed

One product or commercial creative per vertical swipe. The item should display:

- High-quality hero image, image carousel, or approved video when available.
- Brand and product name.
- Price and currency; former price/discount when valid.
- Merchant name and short shipping/availability summary when known.
- **Save**, **Not interested**, **Share**, **Product details**, **View at merchant**.
- **Sponsored** indicator if a placement is paid.
- Affiliate disclosure according to applicable terms/law.

Behavior:

- Swipe up/down to move between products.
- Product media remains responsive and doesn't block scrolling.
- Only the active video's audio may play; default mute/autoplay behavior is configurable.
- Preload only nearby media to avoid memory/performance issues.
- Pagination starts before the final loaded item.
- Product cards do not need comments, follower counts, engagement counters, or invented “likes.”
- Empty/error/loading states remain navigable; filters must not vanish when the request changes.

**Important media principle:** Many product feeds contain *images but not videos*. Stafeed must look compelling with still images, motion templates or image carousels. Video is an enhancement, not a hard dependency. Rights to modify/display source images and media must be respected.

### 5.4 Shopping sessions — key differentiator

The user can create a **temporary intent-specific feed**:

- “I want white casual sneakers under $150.”
- “I need a birthday gift for my wife.”
- “Show me mechanical watches, $500–$1,500.”
- “I'm furnishing a modern living room.”

Session stores query, category/attributes, region, budget, interaction history, paging/cursor state, and date. A session must be easy to reset, pause, resume, or archive.

**Crucial logic:** A temporary gift-search session should not cause the person's permanent For You feed to be dominated by gift products. Keep **session profile** separate from **long-term profile**.

### 5.5 Search and filters

- Search using product terms or natural language.
- Category and subcategory chips.
- Price range, brand, colors, sizes, target gender, condition, in-stock, ships-to (as supported by providers).
- Debounce text queries and cancel/ignore stale results.
- Changing a filter resets feed pagination and scroll position.
- Preserve search controls during loading/empty/error states.
- Show only filters meaningful for the category and actually supported by the source.
- When no results exist, suggest useful filter relaxation; never silently ignore shipping or availability requirements.

### 5.6 Product details

Open a page or bottom sheet containing media, description, attributes, variants, merchant, current price/availability, affiliate disclosure, seller link, save, share, and report action. For providers with freshness constraints, refresh price/availability before critical merchant handoff when appropriate.

### 5.7 Saved products

- Save/unsave across any product feed.
- Saved list/grid works even if the product is not currently present in the first page of the feed.
- Preserve a minimal authorized product reference/snapshot and refresh product details as needed.
- Work across app restarts and account upgrade.
- Handle removed/unavailable products gracefully.

### 5.8 Profile/settings

- Destination country, currency, language.
- Interests and autoplay settings.
- Clear behavioral history, end shopping sessions, delete account/data.
- Privacy, terms, affiliate disclosure, support details.
- English initially, localization-ready for Arabic/French later.

---

## 6. Product/data sourcing — MOST IMPORTANT STRATEGIC AREA

There is no general, unrestricted API for downloading all ads from Meta, Google, and TikTok and publishing them as Stafeed's commercial feed. Treat each source as a distinct integration with permission and business requirements.

### 6.1 Shopify Global Catalog — primary source to validate

**As of November 7, 2026**, Shopify documents a **Global Catalog MCP** interface at `https://catalog.shopify.com/api/ucp/mcp` under the Universal Commerce Protocol (UCP). It supports cross-merchant product searches, buyer context, filters, images/media, products and offers, and cursor pagination. An agent profile is required. Use the current UCP/MCP interface, **not** the obsolete Global Catalog REST API, which Shopify says stopped serving traffic on **November 2, 2026**.

Use `search_catalog` for relevant on-demand products; `lookup_catalog` and `get_product` for known products, variants, and fresh details. Include user destination, language/currency, shopping intent, and supported filters. Keep the provider request/response behind a backend adapter.

**Critical restrictions:** Shopify catalogs are for buyer-facing shopping experiences, not for harvesting all stores into Stafeed's permanent master database or selling/exporting the feed. Current Shopify catalog guidance allows caching product metadata and Shopify CDN images only up to **24 hours**, price/availability up to **15 minutes**, and **no caching of commission values**. Respect license terms, attribution, source URLs, eligibility, and any future access changes. Do not claim every Shopify store or product will be discoverable or available to every destination.

Official references:
- https://shopify.dev/docs/agents/catalog
- https://shopify.dev/docs/agents/catalog/global-catalog
- https://shopify.dev/changelog/posts/global-catalog-rest-api-stops-serving-traffic-on-november-2-2026

**Commercial distinction:** Shopify Global Catalog does not automatically entitle Stafeed to affiliate commissions on every product. Shopify's promoted-placement program is currently documented as limited / invite-led. Treat this as an **optional paid-placement integration**, not assured monetization.

### 6.2 Awin affiliate product feeds — affiliate inventory and launch monetization

Awin publisher product feeds provide advertiser-supplied product names, images, descriptions, prices, category and affiliate deep links. Access requires an approved publisher relationship and appropriate advertiser/feed availability.

Integration requirements:
- Securely configure publisher identity and data-feed key (not the ordinary Publisher API key).
- Discover allowed feeds and their last-updated time.
- Import selected feeds only (initially shoe/fashion merchants and a few compatible categories).
- Stream CSV/GZIP safely and normalize data in batches.
- Map price, currency, product ID, brand, category, availability, images and exact affiliate deep links.
- Refresh only changed feeds; mark stale or removed items.
- Track source and permitted-use metadata, preserve affiliate parameters, and disclose affiliate links.

Official references:
- https://help.awin.com/developers/docs/product-feed-publisher-guide-intro
- https://help.awin.com/developers/docs/downloading-a-list-of-your-product-feeds

Other potential affiliate partners to assess later, **not assumed to provide identical APIs/rights**: CJ Affiliate, impact.com, Rakuten Advertising, regional networks.

### 6.3 Merchant-supplied catalogs

A participating merchant can provide a structured JSON/CSV feed or a supported merchant commerce integration (including a future Shopify app). This is separate from querying Shopify Global Catalog. Permissioned feeds can support more control over media, custom campaigns, availability and attribution.

Later, a self-service merchant setup can be:

**Connect shop → authorize catalog → select products → upload/associate creative → choose campaign → publish.**

Possible platforms: Shopify, WooCommerce, BigCommerce, Adobe Commerce/Magento, PrestaShop. Prioritize based on actual merchant demand.

### 6.4 Direct advertisers and creator-supplied media — later

Authorized brands/creators supply their own videos, photos, product data and destination links. Stafeed creates labeled feed placements and tracks engagement/clicks. Paid boosts and campaign billing are later-phase functionality.

### 6.5 Automatic vertical creatives — optional future enhancement

When a product has only images, Stafeed may display a well-designed image-first product card or generate a simple animation from permitted images, text and transitions. Generative AI ads/videos are **not necessary for MVP**. Never imply a generated demo is an authentic creator review, never invent product features, and verify media transformation rights.

### 6.6 Google/Meta/TikTok ad sources — separate from product catalog

- **Meta Ad Library / Google Ads Transparency / TikTok Commercial Content APIs:** transparency and research mechanisms; **do not** scrape or commercially republish their creatives without explicit rights.
- **Google AdMob/Google Ad Manager native ads:** technically possible to serve approved ad inventory in a mobile UI, but format/publisher policy and an app centered entirely on ads need separate validation. Consider only as a controlled, clearly labeled experiment; not required for MVP and not a searchable merchant product catalog.
- **Direct ad network/exchange partnerships:** a future business-development option requiring contracts, allowed placements, quality controls and reporting.

**Source priorities:** fixture mode → authentic Shopify catalog access → authorized Awin product feeds → direct merchant feeds → merchant paid ads/creators when the consumer product proves usage.

---

## 7. Data model — separate products, offers, media, creatives

Avoid assuming one product equals one advertisement or one store offer.

```text
Canonical Product
  ├── Merchant Offer A (price, currency, availability, URL, variants)
  ├── Merchant Offer B (optional)
  ├── Media assets (images/videos)
  └── Creatives (official, merchant, creator, future paid campaigns)
```

This separation supports the original vision: the same shoe may have an official brand ad, a creator demo, a template-based card, multiple merchant prices, and different attributed destination URLs.

Core entities, introduce as needed:

- **User/profile**: anonymous/authenticated ID, country, currency, language, interests, settings.
- **ShoppingSession**: query, structured filters, temporary affinities, timestamps, cursors.
- **Category**: taxonomy ID/slug/name/parent; provider mappings.
- **Provider**: Shopify/Awin/direct/fixture and capabilities.
- **Merchant**: seller ID, provider, name, domain, region/status.
- **Product**: canonical ID, provider references, title, description, brand, category, searchable attributes, status.
- **Offer/Variant**: merchant, price in minor currency units, currency, inventory/availability, destination country, exact product/checkout URLs, attribution, promotion metadata.
- **Media/Creative**: image/video URLs or owned creative assets, format, poster, rights/source, sequence.
- **SavedProduct**: user + product reference; optionally chosen offer and permitted snapshot.
- **InteractionEvent**: impression, dwell, skip, details, save, unsave, not interested, share, outbound click, session start/end.
- **Affinity**: user/session preference scores by category, brand, attribute, price bracket.
- **ProductReport**: reason, item, user, review state.
- **Campaign/AdPlacement/CreatorAsset**: reserved for later phases; do not implement prematurely.

Catalog data may be externally queried rather than permanently stored. Storage schemas must respect each provider's licensing/caching restrictions. Prices must use integer minor units + ISO currency code. Keep stable provider IDs and avoid duplicate products or consecutive near-identical variants.

---

## 8. Recommendation and ranking strategy

### MVP: transparent rule-based ranking, not a custom ML model

**Candidate retrieval:** obtain relevant products from providers according to query, category, filters and locale; remove unavailable, blocked, non-shipping, restricted, stale, repeated and duplicate products.

**Rerank:** combine provider relevance, intent match, session interactions, long-term tastes, product quality, freshness, and a little exploration. Candidate starting weights (tunable, not proven):

- 40% provider relevance
- 20% explicit intent/category match
- 15% temporary shopping-session affinities
- 10% long-term user affinities
- 5% quality/popularity
- 5% freshness
- 5% exploration

Behavioral signals (configurable examples):

| Event | Example effect |
|---|---:|
| Not interested | -5 |
| Very fast skip | -2 |
| Normal skip | -1 |
| View ≥2 seconds | +0.5 |
| View ≥5 seconds | +1 |
| Open details | +2 |
| Share | +3 |
| Save | +4 |
| Outbound click | +5 |
| Verified purchase | Future only |

These values are illustrative starting points. A passive impression is not proof of interest. Track dwell time carefully and avoid double-counting exposures.

**Diversity:** no repeat canonical product in one active session, avoid successive near-identical cards, limit brand/merchant repetition, and allocate a small portion of the feed to related novel products.

**Cold start:** explicit category selection, session query, destination, provider ranking, and reasonable exploration must work for a user with zero history.

**Later:** embeddings, visual similarity, product-content understanding, collaborative filtering, real conversion feedback, and an ad/creative-level ranking model—only after sufficient valid data.

---

## 9. Monetization and business phases

### Early stage: commerce referrals

- Affiliate earnings from eligible Awin or other approved advertiser programs.
- Shopify promoted placement commissions only when account eligibility and program terms allow them.
- Attribution and exact destination links must be preserved. Do not assume every product generates revenue.

### Growth stage: own merchant advertising marketplace

Self-service merchant flow:

1. Register / connect authorized catalog.
2. Select a product or collection.
3. Upload media or create a permitted simple product creative.
4. Choose relevant categories, country/region and campaign budget.
5. Publish a **clearly labeled sponsored placement** into a relevance-constrained feed.
6. View impressions, dwell, clicks and attributable results.

Potential business models: CPM, CPC, CPA/affiliate, fixed product boosts, merchant subscriptions, later brand/creator marketplace fees. Pricing, bidding and billing must be designed with real traffic and commercial agreements—not assumed now.

### Future creator marketplace

Creators collaborate with merchants to make product videos/reviews; Stafeed attributes performance and can share approved commissions/fees. Authenticity, disclosures and permissions are required.

### What Stafeed is NOT at launch

- Not the merchant of record.
- Not the payment processor.
- Not a universal multi-merchant cart.
- Not an entertainment network where ads interrupt ordinary videos.
- Not an unauthorized mirror of Meta/TikTok/Google advertisements.

---

## 10. Recommended release scope

### Initial beta niche

Start with **shoes/sneakers** to test the concept because they are visual, lend themselves to swiping, and have understandable price, style, size and brand filters. Keep architecture multi-category, and optionally expose fashion accessories, tech accessories, home/decor, beauty and sports when permitted inventory is good.

### Must-have consumer MVP

- Flutter iOS/Android codebase; verify Android first and iOS as signing/devices permit.
- Anonymous onboarding, country/currency, simple interests.
- For You feed and intent-specific shopping sessions.
- Full-screen vertical image/video-capable product pages.
- Server-backed catalog, search, category and relevant filters.
- Infinite pagination, loading/empty/error/retry states.
- Product details.
- Save/unsave + independently retrievable saved products.
- Not interested and product reporting.
- Merchant handoff with exact authorized URLs.
- Event tracking and initial rule-based personalization.
- Good media loading, scrolling performance, source attribution and privacy controls.
- Working deterministic fixture mode even when third-party credentials are absent.

### Explicitly defer until after consumer validation

- Merchant self-service ad dashboard/billing and ad auctions.
- Creator uploads, social profiles, comments, likes/follows, livestreams and payouts.
- Generative video advertising.
- Internal checkout/universal cart.
- Complex neural recommendation engine.
- Full-web consumer product.
- Bulk Shopify catalog ingestion or scraping.

---

## 11. Technical direction

These are **preferred design decisions**, subject to existing repo compatibility, not instructions to rewrite everything.

### Mobile

- Flutter + Dart, stable compatible versions.
- Riverpod for application state and dependencies.
- Feature-first organization; **existing project uses `lib/app/features/`**.
- `PageView.builder` for vertical swipe feed.
- `go_router` for routing as navigation grows; preserve existing Navigator flows until migration adds value.
- `http` already used in prototype; Dio is optional for advanced production networking, not mandatory.
- `shared_preferences` already used for prototype saves; production saves ultimately sync through backend/auth.
- Suitable `video_player`, image caching, URL opening and sharing packages when actually required.

### Backend

- Small Node.js + TypeScript service (e.g. Fastify + Zod), or another simple maintainable equivalent if justified.
- Provider adapters called server-side; normalize responses into common product/offer/media shapes.
- API endpoints for feed, shopping sessions, products, saved items, event batching, outbound clicks and reports.
- Validate auth, rate-limit, use structured logging/timeouts/retries, and avoid leaking private provider responses.

### Data and authentication

- Supabase PostgreSQL + Auth (anonymous initially, optional email upgrade) + Row Level Security.
- Persist user profiles, shopping sessions, saved references, event history, merchant/provider metadata, and permitted catalog records.
- Keep sensitive provider keys and service-role credentials server-side.
- Apply SQL migrations under version control.
- Scheduled jobs for permitted affiliate-feed imports, freshness checks and cleanup.
- Provider-specific cache TTLs, especially Shopify restrictions.

### Repository organization

Existing mobile app is the starting point; do not blindly move folders. A future monorepo could be:

```text
stafeed/
  apps/mobile/              # migrated existing Flutter app, if justified
  services/api/             # backend/provider adapters
  supabase/migrations/
  docs/
  fixtures/
  PROJECT_STATUS.md
  README.md
```

No mandatory migration to this structure until there is enough code to warrant it.

### Typical backend contracts (conceptual)

```text
GET  /v1/config
POST /v1/shopping-sessions
PATCH /v1/shopping-sessions/:id
GET  /v1/feed?sessionId=...&cursor=...
GET  /v1/products/:id
GET  /v1/saved
PUT  /v1/saved/:productId
DELETE /v1/saved/:productId
POST /v1/events/batch
POST /v1/outbound-clicks
POST /v1/reports
```

Use opaque feed cursors for a merged multi-provider feed, not the DummyJSON offset as a permanent system-wide pagination strategy.

---

## 12. Existing prototype: what Claude should expect, not assume

There has been an ongoing Flutter prototype for Stafeed with these pieces introduced:

- App root/home screen and navigation.
- Product model and fixture data.
- Reusable ProductCard with save callback.
- Vertical feed via PageView.
- Shared saved state in Riverpod and local persistence using SharedPreferencesAsync.
- DummyJSON API product repository and fixture repository implementing a common contract.
- Paginated products state and AsyncNotifier with load-more logic.
- Feed filter Notifier, category selection and search.
- Saved screen based on loaded catalog products.
- A search debounce / persistent-search-UI refactor was proposed, but its actual completion is **unknown**.

Previous expected path pattern:

```text
lib/
  main.dart
  app/
    stafeed_app.dart
    features/
      home/
      feed/
        data/
        models/
        providers/
        widgets/
        feed_screen.dart
      saved/
```

This is **not** a guarantee about current source. Examine actual code and tests. The prototype uses **DummyJSON as placeholder inventory**, not the final commercial catalog. Known issues to check include pagination races, loading/error UI, independent saved-item hydration, stale filter results, search debounce, missing tests, and provider lifecycle cleanup.

The product brief is **not** an instruction to retain educational scaffolding forever. Refactor incrementally into production-quality code when it is genuinely necessary.

---

## 13. Performance, accessibility and behavior

- Smooth vertical swiping on normal mid-range Android hardware, not only a flagship device.
- Limit active video controllers; pause/dispose off-screen media, prevent simultaneous audio.
- Preload only nearby media; cache appropriately under provider terms.
- Use progressive image fallback for failed videos; avoid blank cards.
- Avoid jarring screen resets when loading subsequent pages.
- Avoid rebuilding all cards after a single save action if it creates performance issues.
- Support screen readers, labeled controls, dynamic text, contrast and reduced-motion settings.
- Localize prices/currency, account for right-to-left support later.
- Handle offline/no network, unsupported locale, stale item, merchant link error, provider outage, authentication expiry, and app background/resume.

---

## 14. Trust, privacy, rights, and data integrity

- Show `Sponsored` / `Promoted` labels unambiguously when content is paid.
- Provide affiliate disclosure where needed.
- Preserve source/affiliate URL attribution and merchant identity.
- Do not cache/rehost or bulk-export third-party content beyond granted rights.
- Do not scrape ad transparency libraries or merchant websites as a shortcut.
- Restrict and moderate adult products, weapons, tobacco, controlled drugs, counterfeits, gambling and dangerous goods from the initial catalog.
- Avoid unsupported medical or misleading product claims.
- Don't fabricate reviews, ratings, conversion events, buyer interest or creator endorsements.
- User controls for personalization, history deletion, account deletion and privacy links.
- RLS ensures users cannot read one another's saved lists/sessions/events.
- Validate outbound URLs and sanitize input. Respect HTTPS and domain trust.
- Do not store secrets or token payloads in client logs.

---

## 15. Product metrics and beta validation

Track on-device and/or server-side events with idempotent IDs:

`impression`, `view_2s`, `view_5s`, `swipe_skip`, `detail_open`, `save`, `unsave`, `not_interested`, `share`, `outbound_click`, `filter_apply`, `session_start`, `session_end`, `report`.

Core product questions/metrics:

- Products viewed per session and session duration.
- Percentage who browse at least 10/20 items.
- Save rate, detail-open rate, merchant outbound-click rate.
- Return rate within 7 days.
- Relevance improvement across a shopping session.
- Feed availability/fill rate by category/country/source.
- Provider latency, stale prices and failed handoffs.
- Attributable affiliate conversions/revenue where the network reports them.

Suggested early indicators are **experiments**, not guarantees: meaningful sessions of 15–20 browsed products; organic saves and merchant clicks; noticeable improvement in relevance; repeat use. Validate with real people, not only synthetic analytics.

---

## 16. Delivery roadmap for Claude Code

### Phase A — Audit and stabilize current prototype

- Inspect current Flutter code, provider versions, tests and git status.
- Fix functional issues; keep scrolling, filtering and saved state stable.
- Add widget/provider/repository tests and deterministic fixtures.
- Document existing architecture and run the app on Android.
- No third-party credentials necessary.

### Phase B — Complete consumer fixture-backed flow

- Product details, saved independent of feed pagination, not interested, report, share, merchant handoff mock.
- Search/category/filter UX, proper loading/empty/error screens, on-device performance.
- Shopping sessions and country/currency selection.
- Instrument events.

### Phase C — Backend/data foundation

- Minimal API, Supabase migrations/auth/RLS, shopping sessions/events/saves.
- Server-side adapter abstraction and a full fixture adapter.
- Contract tests, auth and secrets management.

### Phase D — Real commercial catalog sources

- Confirm Shopify Global Catalog MCP eligibility and terms; integrate search/lookup/get-product with correct caching and cursor behavior.
- Confirm Awin publisher approval/feed rights; implement allowed feed imports and authorized affiliate links.
- Merge/de-duplicate candidates; maintain allowed source provenance and filter capabilities.
- Retain fixture demo mode when external access is unavailable.

### Phase E — Initial personalization and beta

- Capture behavioral signals; rule-based session/global affinity scoring and diversity reranking.
- Tune feed performance, source disclosures, privacy/security and account deletion.
- Android beta and iOS preparation when practical.
- Recruit testers and measure hypotheses before adding ad marketplace features.

### Phase F — Merchant advertising platform (post-validation)

- Merchant onboarding/connectors, direct product feeds and creatives.
- Campaign creation, budgets, sponsored placement logic, reporting and billing.
- Relevance guardrails and sponsored disclosures.

### Phase G — Creator and advanced discovery (future)

- Creators, shoppable videos, commission-sharing agreements, permitted automatic creatives, richer AI similarity and optional checkout integrations.

**Do not expand phases F/G just because they are documented.** They are the long-term business vision, not MVP requirements.

---

## 17. Test and acceptance requirements

At minimum, demonstrate in fixture mode:

1. Open Stafeed without email registration.
2. Choose country and a few categories.
3. Start “white sneakers under $150.”
4. See an appropriate vertical feed with smooth image/video transitions.
5. Change filters without old category results contaminating the new feed.
6. Swipe through multiple pages without repeated cards or duplicate fetches.
7. Save an item; restart the app; find it reliably in Saved.
8. Dismiss another as not interested; its feedback affects subsequent ranking.
9. Open product details, then a mocked/authorized merchant link.
10. Produce event records that accurately reflect impressions, swipes and clicks.
11. Show honest sponsored labels where fixtures simulate a paid placement.
12. Handle slow network, empty results, stale data, no internet, failed media and failed provider gracefully.
13. Pass Flutter formatting/analyze/tests and relevant Android build; backend/API/database tests when those components exist.

For real providers, additionally verify authorized access, source terms, pricing/currency correctness, shipping region, fresh availability and exact attribution URLs. Report blockers clearly if a provider account has not yet been approved.

---

## 18. Current decisions vs open questions

### Agreed direction

- Name: **Stafeed** (working brand).
- Flutter mobile first, Android development now, iOS later.
- Full-screen vertical product-discovery feed.
- User intends to shop; feed items are commercial/product-oriented.
- Strong search/category controls and temporary shopping intent sessions.
- Save, not interested, details and merchant-outbound actions.
- External merchant checkout, not Stafeed as seller.
- Affiliate and Shopify catalog sources ahead of an original ad auction.
- Shopify Global Catalog **query integration**, not bulk replication.
- Future direct advertisers, merchants and creator ads.
- Simple transparent recommendation system first.
- Incremental work that reuses the existing Flutter prototype.

### Validation required / not yet guaranteed

- Shopify Global Catalog program eligibility, implementation compatibility and commercial terms for the intended use case.
- Which Shopify products/regions/fields Stafeed can actually present.
- Whether any promoted-placement payouts are available to this project.
- Awin publisher approval, advertiser participation, permitted feed/display rights, region-specific commission availability.
- Exact launch country/region and regional merchant coverage.
- Final brand name and domain.
- Actual consumer demand and retention.
- Video coverage/creative rights across inventory sources.
- Best final recommendation weights and sponsored placement mix.
- iOS release/signing arrangements.

Default initial beta category should be shoes/sneakers unless new research or user instructions change it. Do not assume a launch country without asking or configuring it explicitly.

---

## 19. Immediate action for Claude Code

1. Read this entire document.
2. Inspect the repository (including `lib/app/features/`, tests, pubspec, README and any existing spec/architecture documents).
3. Produce a **brief current-state audit**: working features, missing features, broken flows and potential high-risk dependencies.
4. Compare actual code to the requirements. Preserve correct existing implementations.
5. Propose the **shortest credible path to a fixture-backed, testable consumer MVP**, plus a separate provider-access spike for Shopify Global Catalog MCP and Awin.
6. Then implement the next incremental product milestone with tests, while reporting which features are fixtures, which are real, and which require credentials or approval.

**Final north star:** Stafeed should feel like scrolling a dedicated, personalized feed of things worth buying—across brands and merchants—with shopping intent, not entertainment, at the center.
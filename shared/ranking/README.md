# Shared ranking scenarios

The ranking (spec Seam 3) is written twice: in Dart for the Fixture data gateway (`lib/app/features/ranking/ranking.dart`, ticket #10) and in TypeScript for the backend (ticket #15). Both must pass every scenario in `scenarios.json`, with the weights in `ranking_config.json`. Change a rule here first; then both implementations follow.

- Dart runs them in `test/features/ranking/ranking_scenarios_test.dart`, which also checks that the app's built-in weights (`defaultRankingConfig`) equal `ranking_config.json`.

## `ranking_config.json`

| Key | Meaning |
|---|---|
| `score_weights` | How much each part of the score counts: source relevance, intent match, session affinity, long-term affinity, quality, freshness. Starting values from the product spec. |
| `signal_weights` | What each Shopper signal adds to the affinity of the Product's Brand, category and price band. `view_5s` is the total for a 5s view: it always follows a 2s view of the same Feed Item, so on its own it adds `view_5s - view_2s`. |
| `affinity_saturation` | A summed affinity `a` counts as `a / (|a| + affinity_saturation)`, between -1 and 1. |
| `paid_ad_near_tie_bonus` | Added to every paid Ad's score, so a paid Ad beats a Not an Ad that scores within this much of it. Never depends on how much an Ad pays. |
| `exploration_share` | The spec's 5% exploration, as a share of the feed: every `round(1 / share)`th Feed Item (counted from the top of the feed) is the best novel one, if any. |
| `price_band_edges_minor` | Price band edges in minor units: band `"0"` below the first edge, `"1"` below the second, and so on. |

## The rules

1. **Retrieval** leaves out a candidate that is out of stock (`available: false`), doesn't ship to `destination_country` (`ships_to` absent means everywhere), was already shown (`recently_shown`), or whose Product is Not interested. A Brand Ad loses its Not interested Products and goes when none is left (one that never had any stays). For You leaves out Not an Ad. In a Shopping Session a Brand Ad stays only when one of its Products matches the goal.
2. **Score** = `source_relevance × relevance + intent_match × intent + long_term_affinity × long-term affinity + quality × quality + freshness × freshness`, plus `session_affinity × session affinity` in a Shopping Session, plus `paid_ad_near_tie_bonus` for a paid Ad.
   - *Intent*: For You: 1 when a Product's category is one of the Shopper's `interests`. Session: 1 when the session has a goal and a Product matches it. Otherwise 0.
   - *A Product matches the goal* when it is in the session's `category` (if set) and every word of `query` (lower-cased, split on spaces) appears in its title, Brand or category (lower-cased). No goal matches everything.
   - *Affinity* of a candidate: for each of its Products, the mean of the squashed affinities of its category, Brand and price band; then the mean over its Products. Long-term affinity sums `long_term_signals`; session affinity sums the session's `signals`. For You never looks at the session.
3. **Order**: best score first; equal scores keep the candidates' order. Then slot by slot: each slot takes the best candidate left whose Brand differs from the one before it (`previous_brand` for the first slot), or the best one left when only that Brand remains. When the slot number (`recently_shown` count + position, from 1) is a multiple of `round(1 / exploration_share)`, it first tries the best *novel* candidate with a different Brand: one whose own Brand and whose Products' Brands and categories have zero affinity in every taste used.

## `scenarios.json`

Each scenario:

| Field | |
|---|---|
| `name` | What it pins down. |
| `feed` | `"for_you"` or `"session"`. |
| `products` | Product ID → `title`, `brand`, `category`, `price_minor`. Candidates and signals refer to these IDs. |
| `candidates` | In the source's order. `id`, `kind` (`affiliate_ad`, `brand_ad`, `not_an_ad`), `product` (one ID) or, for a Brand Ad, `brand` and `products` (IDs). Optional: `relevance`, `quality`, `freshness` (0 to 1, default 0), `available` (default true), `ships_to`. |
| `destination_country`, `interests`, `recently_shown`, `not_interested` (Product IDs), `previous_brand` | Optional. |
| `long_term_signals` | Optional. `[{ "signal": "<signal_weights key>", "product": "<ID>" }]`. |
| `session` | Optional. `query`, `category`, `signals`. |
| `expected.order` | The candidate IDs, in order, that the ranking returns. |
| `expected.linked_products` | Optional. Brand Ad ID → the Product IDs it still links to. |

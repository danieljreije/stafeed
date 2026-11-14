# Stafeed — Project Status

_Last updated: 2026-11-14_ · "Stafeed" is a working name.

- Spec: [#1](https://github.com/danieljreije/stafeed/issues/1) — tickets are its sub-issues (#2–#30), with native "blocked by" links
- Glossary: `CONTEXT.md` · Decisions: `docs/adr/` · Background vision: `docs/STAFEED_PRODUCT_SPEC.md`
- Superseded by the spec: `docs/STAFEED_ROADMAP.md` (kept for history)

## Done
- #2 — 01 Data gateway + Fixtures; DummyJSON removed (2026-11-11)
- #3 — 02 Reliable feed: paging, stale results, retry, refresh, states (2026-11-13, built by the orchestrator)
- #4 — 03 Feed Item kinds & labels: AD label, Brand Ads, Not an Ad (2026-11-13, built by the orchestrator)
- #6 — 05 App shell, onboarding & Destination Country (2026-11-13, built by the orchestrator)
- #7 — 06 Product details, Merchant Handoff, Share, Report (2026-11-14, built by the orchestrator)
- #8 — 07 Saved Products independent of the feed (2026-11-14, built by the orchestrator)
- #9 — 08 Events log, debug screen & ad counter (2026-11-14, built by the orchestrator)
- #10 — 09 Ranking + Not interested (2026-11-14, built by the orchestrator)

## Start now (no blockers)
| Ticket | Who |
|---|---|
| #5 — 04 Video-feed prototype | Local agent (Flutter) + real Android phone |
| #15 — 14 Backend first slice | Cloud agent |
| #26 — 25 Research: pay-per-click networks | Cloud agent |
| #14 — 13 Create Supabase project | You |
| #24 — 23 Apply to Awin; launch country | You |
| #27 — 26 Apply for Shopify Catalog access | You |
| #30 — 29 Final name & store IDs | You (before first store upload) |

## Reliable feed (#3)
- The feed controller (`lib/app/features/feed/providers/feed_provider.dart`) gives every list a generation number. A new filter, a retry of the first page or a successful refresh starts a new generation, and any answer asked for by an older one is dropped. So a slow request can't overwrite a newer feed, add to it, or switch off its spinner, including when the Shopper goes from filter A to B and back to A.
- Only one load-more runs at a time. When it fails, the Feed Items and the place in the feed are kept and a **Retry loading** button shows over the feed; one tap asks once for the same page.
- Pull down at the top of the feed to refresh. The old list stays until the new first page arrives; if the refresh fails the old list stays and a short message says so.
- After the last Feed Item there is one quiet page ("You've seen everything for now"): no spinner, no error, no more requests.
- Empty feed: **No matches** with a **Clear filters** button. First page failed: **Couldn't load the feed.** with **Retry**. Both show under the search box and chips, which never go away.
- Tests: `test/features/feed/providers/feed_provider_test.dart` (controller rules) and `test/features/feed/feed_reliability_test.dart` (the screen), both on a scripted fake gateway (`test/features/feed/support/scripted_data_gateway.dart`) where the test decides the order answers arrive in.
- Changed on purpose, because #3 asks for it: the empty-state wording ("No products available." → "No matches" + "Clear filters") in one widget test and in the web end-to-end test, and the golden images for the empty and error states.
- Not done here: load-more only starts when the Shopper swipes (three Feed Items before the end), so a first page shorter than that waits for the first swipe.

## Feed Item kinds & labels (#4)
- A Feed Item is now exactly one of three kinds (`lib/app/features/feed/models/feed_item.dart`): **Affiliate Ad** (one Product + one Offer), **Brand Ad** (its own media and words, linked Products) or **Not an Ad** (a Product whose Offer earns Stafeed nothing). The code can't add a fourth kind without deciding how it is labelled.
- Labels on the cards:
  - Every Ad has a bold **AD** badge. A Brand Ad also says **Sponsored**.
  - An Affiliate Ad says "Stafeed may earn a commission" under the price.
  - Not an Ad has a **NOT AN AD** badge and "Stafeed earns nothing on this one".
- A Brand Ad shows its Brand, its headline and one chip per linked Product. Tapping a chip shows a short message naming that Product. Product details (#7) will open there instead. A Brand Ad has no Save button.
- Media: each Feed Item has a list of images and videos (`models/media.dart`). Several pictures are swiped through sideways, with dots showing the place. Video isn't played yet: its poster image stands in, or a video icon when there is none. A picture that fails to load shows a broken-image icon.
- Fixtures: 3 image-only Brand Ads (`data/fixtures/fixture_brand_ads.dart`), by the invented Brands Northstar, Orbitline and Brightmoor. In the Fixture feed each comes right after the last of its linked Products, so For You still opens on Affiliate Ads. A category filter or a search finds a Brand Ad through its Brand, its headline or its linked Products.
- Not an Ad never appears in For You. It has a card and tests, ready for Shopping Sessions (#11).
- Tests: `test/features/feed/widgets/feed_item_cards_test.dart` (labels, chips, carousel, fallbacks, each kind inside the feed), `test/features/feed/models/feed_item_test.dart` (the kinds and their media), new Brand Ad tests in `test/features/feed/data/fixture_data_gateway_test.dart`, and golden images for the Brand Ad and Not an Ad cards.
- Changed on purpose, because #4 changes what a Feed Item is:
  - Existing tests that read `item.product` or `item.offer` off any Feed Item now say which kind they mean (Affiliate Ad), or ask for the Feed Item's Products. They check the same things as before.
  - The web end-to-end test also checks the AD label and the commission note on the first card.
  - The Affiliate Ad golden image is regenerated (it gains the AD badge and the note).
- Choices made by the orchestrator: the wording of the Not an Ad note; white AD badge; chips show the Product's title; where Brand Ads sit in the Fixture feed.

## App shell, onboarding & Destination Country (#6)
- **Four tabs** at the bottom: Feed, Search, Saved, Profile (`lib/app/features/shell/app_shell.dart`). Each keeps its place while you are on another one: the Feed stays on the Feed Item you were on, Search keeps what you typed, Saved keeps its scroll position. Routes are in `lib/app/router/app_router.dart` (`go_router`, new package).
- **The old Home landing screen is gone**, with its test (`test/widget_test.dart`). The app opens on onboarding the first time and on the Feed every time after.
- **Onboarding** (`lib/app/features/onboarding/`), three steps:
  1. "Welcome to Stafeed. It's all ads. We're not hiding it."
  2. Destination Country (United States, United Kingdom, United Arab Emirates, Lebanon) and currency. The country's usual currency is suggested; USD, GBP, EUR and AED can be picked.
  3. Interests (the feed's categories). **Skip** leaves them empty.

  The choices are stored on the device (`lib/app/features/shopper/`). Closing the app before the last step shows onboarding again from the start.
- **Destination Country filtering**: the data gateway knows the Shopper's Destination Country and never serves an Offer that doesn't ship there. On Fixtures (`fixture_data_gateway.dart`):
  - an Affiliate Ad shows the Product's first Offer that ships there, and a Product with none is left out;
  - search, category chips and paging all stay inside the country;
  - a Brand Ad only links the Products that are in the feed there, and is left out when none is. Its own words and pictures are never changed.
- **App name in one place**: `lib/app/app_name.dart`. The window title, the welcome line and the "Stafeed may earn a commission" / "Stafeed earns nothing on this one" notes read it from there.
- **Tone-of-voice guide**: `docs/TONE_OF_VOICE.md`.
- **Product-detail route** exists (`/product/<id>`) with a bare screen (title, Brand, description). Nothing links to it yet; #7 builds the real screen and opens it from the feed.
- Tests: `test/app/app_shell_test.dart` (whole app: onboarding once, tabs keeping their place, country filtering), new "Destination Country" tests in `test/features/feed/data/fixture_data_gateway_test.dart`, `test/features/shopper/shopper_config_storage_test.dart`. The web end-to-end test now starts with onboarding and moves between tabs.
- Changed on purpose, because #6 asks for it:
  - `test/widget_test.dart` (the Home screen test) is deleted with the Home screen.
  - The golden tests no longer tap "Start Exploring": they start the app for a Shopper who has finished onboarding. All six golden images are regenerated (each gains the tab bar).
  - The web end-to-end test goes through onboarding instead of Home, uses the Saved and Feed tabs instead of Back, and expects the Feed to still be on the saved Feed Item when the Shopper returns to it (before, the feed opened again at the top).
- Fixed on the way: a Saved Product whose picture failed to load broke the layout of its row in Saved. The picture now sits in a fixed box with a broken-image icon as fallback.
- Not done here, for you to know:
  - **Currency is stored but prices aren't converted.** Each price still shows in its Offer's own currency (USD or GBP on Fixtures). Converting needs exchange rates, which no ticket covers yet.
  - **Interests are stored** and, since #10, lead For You (see below).
  - **Profile is read-only**: it shows the country, currency and interests. Changing them is #13.
  - **Search tab is simple**: a search box and the category list; either one filters the Feed and takes you there. The search box and chips on the Feed are still there too. Shopping Sessions (#11) will take over this tab.
  - The launcher label and browser tab title still say "stafeed" in `android/`, `ios/` and `web/`; those files can't read the Dart name. They change with the final name (#30).
- Choices made by the orchestrator: the wording of the onboarding questions and buttons; the currency list; the tab icons (Saved is a bookmark, because the heart is the Save button); trimming a Brand Ad's linked Products by country instead of hiding the whole ad.

## Product details, Merchant Handoff, Share, Report (#7)
- **Opening details**: tap an Affiliate Ad's card (anywhere but the Save button) or a Brand Ad's Product chip. The route is `/product/<id>?offer=<offer id>`, so the details show the Offer the Shopper saw in the feed. Back returns to the same Feed Item: the details open over the tabs, which keep their place.
- **Details screen** (`lib/app/features/product/product_details_screen.dart`): pictures (swiped sideways), Brand, title, price, In stock / Out of stock, "Sold by <Merchant>", the commission note (or "earns nothing" for an Offer that doesn't earn), **View at <Merchant>**, description and attributes. Sample-data marker on Fixtures. Share and Report are in the top bar.
- **Fresh fetch**: each open asks the data gateway again (`DataGateway.getProduct`), so price and availability are today's. The gateway only returns Offers that ship to the Destination Country. Loading spinner; a failed fetch shows **Retry**; a Product that's gone (or no longer ships there) says "This Product isn't available any more."
- **Merchant Handoff**: records an **Outbound Click** through the gateway (`recordOutboundClick`), then opens the Offer's link outside the app (`url_launcher`, new package). On Fixtures it opens an in-app page instead, saying the real app would open that Merchant and that Stafeed never takes payment. The Shopper never waits for the click to be recorded, and a failed record doesn't stop the handoff. If the link won't open, a short message says so.
- **Share**: the phone's share sheet (`share_plus`, new package). A real Offer shares name, Brand, price, Merchant and link; a Fixture shares only "<name> by <Brand>, found on Stafeed".
- **Report**: Wrong price, Misleading, Prohibited item, Broken link, Other, plus an optional note. Stored through the gateway (`submitReport`); "Send report" stays off until a reason is picked. A failed send says so.
- **On Fixtures, Outbound Clicks and Reports are kept in memory only** (`FixtureDataGateway.outboundClicks` / `.reports`), and are lost when the app closes or the Destination Country changes. They reach a real store with the backend (#19, #20). The Events log (#9) can read them from the gateway.
- The share sheet and link opener sit behind providers (`lib/app/features/product/platform/product_platform.dart`), so tests use fakes.
- Tests: `test/features/product/product_details_screen_test.dart` (details, fresh fetch, loading/error/gone, each action and its failure), `test/features/product/product_details_flow_test.dart` (whole app on Fixtures: open from an Affiliate Ad and a Brand Ad chip, Save still saves, Back lands on the same Feed Item), `test/features/feed/data/fixture_product_actions_test.dart` (gateway).
- Changed on purpose, because #7 asks for it: the Brand Ad chip test in `test/features/feed/widgets/feed_item_cards_test.dart` used to expect a short message naming the Product; it now expects that Product's details to open. The test fake gateways (`scripted_data_gateway.dart`, the golden test's fake) gained the three new gateway methods. No golden images change: the cards look the same.
- Not done here: Saved Products don't open details yet (#8 gives Saved its own snapshots). The plugin registrant files under `linux/`, `macos/` and `windows/` changed locally with the new packages and are not committed, as agreed; Flutter regenerates them on build.
- Choices made by the orchestrator: the wording on the details, Fixture Merchant and Report screens; Report as a full-screen page with an optional note for every reason; tapping the whole card (not a new button) opens details, so the cards and their golden images stay as they were.

## Saved Products (#8)
- **Snapshots**: saving keeps the Product with what the Shopper saw: title, Brand, first picture, price and currency, Merchant, the Offer's ID and when it was saved (`lib/app/features/saved/models/saved_product.dart`). Stored on the device as JSON under `saved_products` (`lib/app/features/saved/data/saved_products_storage.dart`). An entry that can't be read is skipped; the others are kept.
- **Saved tab** (`lib/app/features/saved/saved_screen.dart`) shows every Saved Product from those snapshots, newest first: picture, title, saved price · Merchant. It never needs the feed, so it works offline, after a restart and when the feed holds something else. Tapping a row opens the Product's details on the Offer that was saved; the red heart removes it. Nothing saved: "Nothing saved yet. …". Storage that can't be read: **Retry**.
- **Unavailable marked**: each row asks the data gateway about its Product (`getProduct`). Gone, or no longer shipping to the Destination Country: **Not available any more**. Still there but no Offer in stock: **Out of stock**. When the check fails (offline) the row just shows, unmarked.
- **Save from details**: a heart in the details screen's top bar (tooltip "Save" / "Remove from Saved"). The feed card, details and Saved all read the same state (`lib/app/features/saved/providers/saved_products_provider.dart`), so a change in one shows in the others.
- **Safe while loading, honest on failure**: a save before the Saved Products are read waits for them instead of throwing or overwriting them. A change shows at once and is stored in order; if the device won't store it, it is undone and a message says "Couldn't update your Saved Products. Try again." The feed no longer waits for the Saved Products to load: until then its hearts show as not saved.
- Tests (in-memory shared-preferences mode): `test/features/saved/saved_products_storage_test.dart`, `saved_products_provider_test.dart` (loading, restart, quick saves, write and read failures, availability), `saved_screen_test.dart` (snapshots without the feed, marks, offline, removal, errors) and `saved_products_flow_test.dart` (whole app on Fixtures: save from details and see it on the feed card and in Saved, unsave from details, restart, a feed without the Product, a Product that no longer ships after the country changes).
- Moved: the Saved provider and storage left `lib/app/features/feed/` for `lib/app/features/saved/`. No existing test changed; no golden image changes.
- For you to know: Products saved by an earlier build (bare IDs under `saved_product_ids`) can't be shown without a snapshot, so they are dropped on the first save. Saved Products stay on this device only until the backend's Saved endpoints (#17). The price shown in Saved is the price when saved; details shows today's.
- Choices made by the orchestrator: the empty-state and mark wording; the heart in the details top bar rather than a new button in the page; one generic "Not available any more" for both "gone" and "doesn't ship to you" (the gateway doesn't tell them apart).

## Events log, debug screen & ad counter (#9)
- **Events** (`lib/app/features/events/models/event.dart`): impression, 2s view, 5s view, Skip, fast Skip, details opened, save, unsave, Not interested, share, Outbound Click, filter change, Shopping Session start/end, report. Each has a random unique ID (a UUID, so the backend can drop duplicates), its time in UTC, and what it was about: Feed Item, Product, Offer, whether the Feed Item is an Ad, dwell, and details (the new filter, the report reason, the Merchant).
- **Buffered on the phone** (`lib/app/features/events/data/events_storage.dart`, `providers/events_provider.dart`): kept as JSON under `events_buffer`, oldest first, and still there after a restart. An entry that can't be read is skipped. Recording never gets in the Shopper's way: it never throws, and an Event the device won't store stays in memory and is stored with the next one. At most 5,000 are kept; beyond that the oldest go.
- **What the feed records** (`lib/app/features/events/feed_watch.dart`, a pure class the feed screen drives):
  - an **impression** each time a Feed Item comes on screen (swiping back to it, a refresh that puts a new one there, or coming back to the Feed tab counts again);
  - a **2s view** and a **5s view** while it stays, once each;
  - a **fast Skip** when swiped past in under 1 second, a **Skip** under 2 seconds, unless the Shopper acted on it (opened details, saved, shared, …, including through a Brand Ad's Product chips). Swiping past after 2 seconds is just a view.
  - A new filter or another tab is never a Skip.
- **Actions recorded**: details opened (from a feed card, a Brand Ad chip or Saved), save and unsave (once stored on the device; a failed save records nothing), share, Outbound Click (alongside the gateway's own record), report (once sent), filter change (only when the filter really changes).
- **Profile** shows "You've watched {n} ads this week. Advertisers thank you." ("1 ad" for one), counted from this week's impressions of Ads, since Monday 00:00 local time.
- **Debug Events screen**: Profile → **Events (debug)** (`/events`). Shows how many Events are kept and lists the newest 200: type, time, Feed Item / Product / Offer, Ad or not, dwell, details and ID.
- Tests: `test/features/events/feed_watch_test.dart` (impression, dwell and Skip rules), `events_log_test.dart` (unique IDs and times, restart, recording while loading, failed writes, unreadable entries, the weekly counter and the Profile line), `events_flow_test.dart` (whole app on Fixtures: impression on open, 2s/5s views, Skip on a quick swipe, no Skip after saving, details/share/handoff/report recorded once, filter change, tabs, restart, Profile count, the debug screen).
- No existing test changed; no golden image changes.
- For you to know:
  - **Not wired yet**, because that feature doesn't exist: Shopping Session start/end (#11). Not interested is recorded since #10. The Event types are there; Events have an empty session reference until #11.
  - **Nothing is sent yet.** Sending in batches to `POST /v1/events/batch` comes with #18/#19. When sent Events leave the buffer, Profile's weekly count will need its own small store, since it counts from the buffer today.
  - Views keep counting while Product details are open over the feed (the Shopper acted on that Feed Item anyway, so it is never a Skip).
  - The whole buffer is written on every Event. Fine at today's sizes; sending (#19) will keep it short.
  - The debug screen is visible to everyone for now. Hide it before the first store release.
- Choices made by the orchestrator: the Skip thresholds (fast under 1s, Skip under 2s, nothing after a 2s view); a calendar week from Monday for "this week"; a return to the Feed tab counting as a new impression; "1 ad" in the Profile line; the 5,000-Event cap; the debug screen's wording.

## Ranking + Not interested (#10)
- **Ranking module** (`lib/app/features/ranking/ranking.dart`, spec Seam 3): a pure function. Input: candidate Feed Items, the Shopper's interests, long-term taste signals, the active Shopping Session (goal and its own signals), Feed Items already shown, the Not interested set, the Destination Country and the Brand shown just before. Output: the order to show them in.
  - Leaves out what is out of stock, doesn't ship there, was already shown or is Not interested (a Brand Ad loses those Products from its chips). For You only takes Ads. In a Shopping Session a Brand Ad only shows when one of its Products matches the goal.
  - Score: source relevance 40%, intent match 20% (For You: one of the Shopper's interests; session: the goal), session taste 15% (sessions only, never For You), long-term taste 10%, quality 5%, freshness 5%, plus a small bonus for paid Ads so they win near-ties against Not an Ad.
  - Taste: each signal adds its weight to the Product's Brand, category and price band (Not interested −5, fast skip −2, skip −1, 2s view +0.5, 5s view +1 in all, details +2, share +3, save +4, Outbound Click +5).
  - Then never the same Brand twice in a row, and every 20th Feed Item is the best one whose Brand and category the taste knows nothing about (the spec's 5% exploration).
- **Weights live in config**: `shared/ranking/ranking_config.json`, mirrored in `lib/app/features/ranking/ranking_config.dart` (a test keeps them equal).
- **Shared scenarios** for #15's TypeScript ranking: `shared/ranking/scenarios.json` (12 scenarios: cold start, Not interested demotion, session vs For You, no same Brand twice in a row, paid Ads before Not an Ad on near-ties, no repeats in a session, Brand Ad goal matching, save and skip, exploration), format and rules in `shared/ranking/README.md`. Dart runs them in `test/features/ranking/ranking_scenarios_test.dart`.
- **Fixture gateway ranks For You** (`fixture_data_gateway.dart`). Each page is ranked afresh from the Shopper's taste at that moment, so a save or a Not interested changes the pages still to come, never the ones on screen. The cursor carries what was already shown (nothing repeats) and the last Brand. Fixtures have no relevance of their own: they count as equally relevant and their order breaks ties, so a brand-new Shopper who skipped interests still sees the Fixtures in their usual order, except that each Brand Ad now comes one Feed Item later when its last linked Product is by its own Brand.
- **Where the taste comes from** (`data_gateway_provider.dart`, `ranking/shopper_taste.dart`): interests from onboarding, the Not interested set, and the long-term signals in the Events log (Events outside a Shopping Session that say something about taste; impressions, unsaves, reports and filter changes don't).
- **Not interested**: a button under Save on every Product card ("Nope", tooltip "Not interested"), and in the details screen's top bar (which then goes back to the feed). It records a Not interested Event, takes the Product out of the feed at once (and out of any page already on its way; a Brand Ad loses it from its chips), keeps it on the device (`lib/app/features/not_interested/`, key `not_interested_products`) and tells the gateway (`DataGateway.markNotInterested`). It never comes back in any feed, also after a restart. "Got it. You won't see that one again." If the device won't keep it, it is hidden until the app closes and the Shopper is told.
- Tests: `test/features/ranking/` (scenarios, config equality, signals and Events), `test/features/feed/data/fixture_ranking_test.dart` (Brand rule in every country and filter, interests first, Not interested hidden and demoted, taste read per page with no repeats), `test/features/feed/providers/feed_hide_product_test.dart`, `test/features/not_interested/` (storage, and the whole app: from the feed card, from details, restart, a failed write, interests leading For You, demotion through the real Events log).
- Changed on purpose, because #10 asks for it:
  - `fixture_data_gateway_test.dart`: "each Brand Ad comes right after the last of its linked Products" now allows one Feed Item more when that Product is by the Brand Ad's own Brand (never the same Brand twice in a row); "holds exactly the Fixtures that ship there" now compares in any order (the Brand rule reorders a few).
  - The web end-to-end test: after the Shopper swipes and saves, the search, Watches and All steps check for a card from that feed instead of its first one (see "Web end-to-end test" below).
  - The two test fake gateways gained `markNotInterested`.
  - The Affiliate Ad and Not an Ad golden images change: they gain the Not interested button.
- For you to know:
  - Not interested only hides a Product from feeds. Its details still open (from Saved, say), and it stays in Saved if it was saved.
  - Not interested lowers the Brand and category through the Events log, which keeps the newest 5,000 Events; the hiding itself is kept separately and for good.
  - Price bands ignore the currency (edges at 50, 150 and 300 in the price's own currency).
  - Shopping Sessions (#11) will call the same ranking with the session's goal and signals; nothing in the app uses the session part yet.
  - "Already shown" means already shown in this feed: a refresh or a new filter starts again from the top, ranked with the latest taste.
- Choices made by the orchestrator: exploration as every 20th Feed Item rather than a score bonus (a bonus made one save rank similar Products lower); affinities squashed as `a / (|a| + 5)`; a 0.02 near-tie bonus for paid Ads; price band edges; equal relevance for every Fixture; the "Nope" label and block icon; the wording of the two messages.

## CI gate (#32)
- Workflow: `.github/workflows/ci.yml` (`CI`), runs on every PR to `main` on `ubuntu-latest`, Flutter pinned to 3.47.2 stable.
- Required checks on `main` (branch protection, #37): **`format, analyze, test`** and **`goldens`** (#35, required since 2026-11-13). The first is shown in the PR checks list as `CI / format, analyze, test (pull_request)`.
- Steps inside that check: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --exclude-tags golden` (goldens have their own check, below). Analyze and test still run when format fails, so one run reports every problem.
- Proven 2026-11-12: green on PR #46 ([run](https://github.com/danieljreije/stafeed/actions/runs/43303624382)); red on deliberately broken PR #47 (format error + failing test, both caught; [run](https://github.com/danieljreije/stafeed/actions/runs/43303652959)), closed unmerged.
- **`web end-to-end`** (#36) also runs on every PR. It becomes required once PR #53 merges. Each check has its own section below.

## Golden check (#35)
- Golden (screenshot) tests: `test/goldens/feed_goldens_test.dart`, images in `test/goldens/goldens/`. They start the whole app on Fixtures (through `dataGatewayProvider`), for a Shopper who has finished onboarding, and cover each Feed Item kind (Affiliate Ad, Brand Ad, Not an Ad) plus the loading, empty and error feed states, with the search field, chips, sample-data marker and tab bar visible.
- Required check name: **`goldens`** — a second job in `.github/workflows/ci.yml`, shown as `CI / goldens (pull_request)`. Required on `main` since 2026-11-13.
- Goldens only run on Linux (tag `golden`); on Windows `flutter test` skips them. Text uses real Roboto/Material Icons kept in `test/goldens/fonts/`.
- When the check fails, the run's **Artifacts** has `golden-failures` with before/after/diff pictures.
- **Intended UI change?** Add the label **`update goldens`** to the PR (or Actions → "Update goldens" → Run workflow on the PR branch). It regenerates the images on Linux, commits them to the PR branch, removes the label and re-runs CI. Look at the new images in "Files changed" before merging.
  - GitHub doesn't start checks for commits the workflow pushes itself, so it starts CI by hand (a `workflow_dispatch` run). An extra "CI" run marked "action required" also appears for that commit, and **the PR stays blocked from merging even when all checks are green**, because GitHub doesn't attach checks to the bot's commit. Fix: push one more commit to the branch (an empty one is fine: `git commit --allow-empty -m "ci: run checks on the updated golden images"`). That starts the PR's normal checks, and auto-merge goes through. The orchestrator run prompt does this itself (found in #41's first live run, PR #56).
- Proven 2026-11-13: on PR #48 the first images were made by the label workflow, and the layout fix in that PR turned `goldens` red until the label regenerated them. Proof PR #52 (deliberate visual change: big yellow price) failed `goldens` ([run](https://github.com/danieljreije/stafeed/actions/runs/43327235490/job/131562670341)), then passed after the label regenerated the images ([run](https://github.com/danieljreije/stafeed/actions/runs/43327585924/job/131563861631)); closed unmerged.

## Main protection & auto-merge (#37)
- `main` is the default branch; the old `master` template branch is deleted (2026-11-13).
- The repo is **public** (2026-11-13). GitHub's free plan only allows branch protection and auto-merge on public repos. Making it private again without GitHub Pro silently switches protection off.
- Repo settings: auto-merge **on**, delete-branch-after-merge **on**.
- Classic branch protection on `main`:
  - Required check: `format, analyze, test`, pinned to the GitHub Actions app, so only the real CI run counts.
  - "Require branches to be up to date" is **off**. Parallel agent PRs then don't stall each time `main` moves. CI already tests each PR merged onto `main` as it was when CI ran.
  - A PR is required (no direct pushes), but **0 approvals** (ADR-0003).
  - Applies to admins too. Force-pushes and deleting `main` are blocked.
- Agent flow: open a PR to `main`, then `gh pr merge <n> --auto --merge`. It merges by itself once the checks are green. Never use admin or bypass merges.
- **Adding a required check (later tickets):** add the job to CI and get it green on a PR first. Then add its check name to the `checks` list. Put back **all** existing checks, because this call replaces the whole list:
  `gh api -X PATCH repos/danieljreije/stafeed/branches/main/protection/required_status_checks --input checks.json`
  where `checks.json` is `{"strict": false, "checks": [{"context": "format, analyze, test", "app_id": 15368}, {"context": "<new check name>", "app_id": 15368}]}`.
  Check the result with `gh api repos/danieljreije/stafeed/branches/main/protection/required_status_checks`, then list the new name under "CI gate" above.
- Proven 2026-11-13: red PR #50 (bad formatting, auto-merge on) failed CI ([run](https://github.com/danieljreije/stafeed/actions/runs/43324828504)) and stayed blocked, then was closed unmerged. Green: this PR merged itself through auto-merge.

## Web end-to-end test (#36)
- Check name: **`web end-to-end`** — shown as `CI / web end-to-end (pull_request)`. Separate job in `.github/workflows/ci.yml`, runs on every PR to `main`.
- Test: `integration_test/shopper_journey_test.dart`. Starts the whole app from `main()` on the Fixture data gateway (no backend, no credentials) in headless Chrome, then acts like a new Shopper: goes through onboarding (United States, interests skipped), swipes through For You, saves a Product and finds it in the Saved tab, returns to the Feed tab where it left off, searches, gets the empty state from a no-match search, and recovers with the category chips.
- Run it locally: start chromedriver (matching your Chrome version) with `chromedriver --port=4444`, then
  `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/shopper_journey_test.dart -d web-server --browser-name=chrome --browser-dimension=430x932 --headless`
- It found two real feed bugs: the feed card was only as tall as the search box and chips (~155px; fixed in #35, which found it too), and the Save heart sat under the search box where it couldn't be tapped (fixed in #36).
- Not required yet: it becomes a required check on `main` once PR #53 merges.
- Saved Products now come from stored snapshots (#8); the journey still finds the saved Product in the Saved tab the same way.
- Since #10 For You is ranked from what the Shopper did, and this journey swipes and saves, so the order of a later feed depends on timing. The first three cards are still checked exactly (they load before any Event); the search, the Watches chip and All are checked for showing a card from that feed.

## Nightly Android check (#39)
- Workflow: `.github/workflows/nightly-android.yml` (`Nightly Android check`). Runs every night at 03:00 UTC on `main`, and by hand (Actions → "Nightly Android check" → Run workflow). **Not a PR check**: never add it to the required checks.
- Runs the same test as `web end-to-end` (`integration_test/shopper_journey_test.dart`) on an Android emulator (API 34, Pixel 6) on GitHub's Linux runner. Takes roughly 15–25 minutes.
- On failure it opens an issue titled **"Nightly Android check failed"**, labelled `ready-for-agent`, with the failing test name and a link to the run log, so the orchestrator picks it up. If that issue is already open, it adds a comment instead of opening a second one. Test results are attached to each run as `android-e2e-results`.
- Proof switch: the manual run has a **force_failure** box. It makes the test fail on purpose and opens a separate issue ("... (deliberate test failure)"), assigned to the owner so the orchestrator leaves it alone. It can't fire on the nightly schedule (it only counts when the run was started by hand).
- Only failures on `main`, or forced failures, open an issue. A manual run on another branch just shows red.
- Proven 2026-11-13: its first run (from this ticket's branch) found a real Android-only problem. The test tapped "Saved Products" while Android was still sliding the page in, so the tap missed. The run opened [#55](https://github.com/danieljreije/stafeed/issues/55) correctly ([run](https://github.com/danieljreije/stafeed/actions/runs/43331392758)). The test now waits until a button is fully on screen and still before tapping it, and passes on Android ([run](https://github.com/danieljreije/stafeed/actions/runs/43435394818)). The manual passing run and the forced-failure run on `main` are linked in [#39](https://github.com/danieljreije/stafeed/issues/39).

## Orchestrator (#38 dry run, #41 live)
- Run prompt: `docs/agents/orchestrator-run.md`, with a `DRY_RUN` switch (missing switch = dry run). Picks the first ticket in spec order (#31's sub-issues, then #1's) that is open, `ready-for-agent`, unassigned, has no open blockers and no PR; claims it, builds it test-first in a worktree off `main` (under `.claude/worktrees/`), opens a PR with `PROJECT_STATUS.md` updated, turns on auto-merge and follows CI. It never weakens, skips or deletes a test to get green.
- Give-up path: after two red attempts, any permission block, or a ticket that can't be done as written, it comments on the ticket (`Stafeed orchestrator gave up: ...`), unassigns itself, swaps `ready-for-agent` for `ready-for-human`, sends you a push notification and stops. The next run skips that ticket and takes the next one.
- Scheduled task: `stafeed-orchestrator` (Claude desktop app, on this PC), prompt in `docs/agents/orchestrator-scheduled-task.md`. Auto mode, never bypass-permissions; `.claude/settings.json` allows `flutter`, `dart`, `git`, `gh`. It only runs while the PC is on and the Claude app is open.
- **Live since 2026-11-13**: every two hours (cron `0 */2 * * *`, local time, plus a few minutes' delay), one ticket per run.
- Proven 2026-11-13:
  - Live run: took #3 with no human action, built it test-first, opened PR #56, which merged itself on green CI. #3 closed. The run had to push one more commit after the golden images were regenerated (GitHub doesn't count checks on the bot's commit); the run prompt now does this on purpose (PR #57).
  - Give-up run: on test ticket #58 (impossible on purpose), it commented, unassigned itself, switched the label to `ready-for-human`, sent a notification and stopped without building anything. #58 was then closed.
- Notifications reach the Windows desktop. They don't reach your phone yet: scheduled sessions aren't connected to Remote Control.
- The orchestrator uses your `gh` login, so a ticket it claims shows as assigned to you.
- To keep the loop off a ticket (e.g. you or another session is working on it), assign it to someone: assigned tickets are skipped.
- Tickets whose PR merged before `main` became the default branch (#32, #34) stayed open; the first live run closed them on 2026-11-13. A live run closes such "done but still open" tickets itself.

### Pause and resume the loop
- **Pause:** Claude desktop app → **Scheduled** (left sidebar) → `Stafeed orchestrator` → switch it **off**. No new runs start. A run already going finishes by itself; to stop it now, open its session (it shows under the task's runs) and press stop.
- **Resume:** same place, switch it back **on**. The next run starts at the next even hour.
- **Run once now:** same place → **Run now** (only while it is switched on).
- **Back to dry runs** (reports only, writes nothing): replace the task's prompt with the dry-run prompt in `docs/agents/orchestrator-scheduled-task.md`.
- Pausing never loses work: an open orchestrator PR is picked up again by the next run (step 0 of the run prompt).

## Daily summary (#43)
- Workflow: `.github/workflows/daily-summary.yml` (`Daily summary`). Runs every day at 06:00 UTC on `main` and posts **one comment on spec [#1](https://github.com/danieljreije/stafeed/issues/1)**, written by `github-actions[bot]`. **Not a PR check**: never add it to the required checks.
- The comment lists, since the last summary (or the last 24 hours when there is none yet):
  - **Merged**: PRs merged, newest first.
  - **Failed**: failed workflow runs, one line per workflow and PR (or branch), with the count and a link to the latest run. This covers red CI on PRs and a failed Nightly Android check; a run that timed out or could not start counts as failed. A run counts on the day it finished.
  - **Handed to you**: tickets that got the `ready-for-human` label and are still open with it. "(the orchestrator gave up)" marks the ones it handed back.
  - **Next**: the ticket the orchestrator takes next (same rules as step 1 of the run prompt), or the PR it continues.
- A day with nothing merged, failed or handed back gets one short line: "No activity since …. Next: …".
- Each comment records (in a hidden first line) the moment it covers up to, and the next one starts exactly there. So nothing falls between two summaries, and a missed day (GitHub skipped the schedule, or the run failed) is caught up by the next one.
- It only reads the tracker. Its one write is the comment; nothing is labelled, assigned, closed or edited.
- **Trial run:** Actions → "Daily summary" → Run workflow, with **post** left off: the summary is printed in the run log and nothing is posted. With **post** on (only from `main`) it posts a comment, and the next daily one then starts from there. Locally: `dart run tool/daily_summary.dart` (set `GH_EXE` when `gh` is not on `PATH`); add `--post` to post.
- Code: `tool/daily_summary/daily_summary.dart` (what goes in the summary) and `tool/daily_summary.dart` (talks to GitHub through `gh`). Tests: `test/tool/daily_summary_test.dart`, on an in-memory GitHub (`test/tool/support/fake_github.dart`).
- Known limits: "Failed" only knows about failed runs on GitHub; when the orchestrator gives up before pushing anything (local checks, a blocked command), the ticket shows under "Handed to you" only. A ticket handed back and already closed again by the time of the summary isn't listed. After a give-up that leaves a draft PR open, "Next" says the orchestrator continues that PR, because that is what the run prompt's step 0 does today.
- Choice made by the orchestrator: spec #31 says "a once-a-day scheduled run". This is a GitHub Actions schedule, not a second Claude scheduled task on your PC, so it also runs while the PC is off and needs no setup from you.
- Proven 2026-11-13: a local trial run against the real tracker printed the right merges, failed runs, hand-backs and next ticket (#4) and posted nothing. Not proven before merge: the workflow itself on GitHub (a new workflow can only be started once it is on `main`); see #43 for the first run.

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (302 passing, 6 golden tests skipped off Linux): passing on Windows as of #10.
- Android: built and tested every night by the Nightly Android check (#39).

## Known gaps carried forward
- The Save button on a Feed Item sits under the search bar (visible in `test/goldens/goldens/feed_item_affiliate_ad.png`).
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Prices aren't converted to the Shopper's currency (see #6 above).

## Launch country
Undecided (decided in #24 based on Awin approvals).

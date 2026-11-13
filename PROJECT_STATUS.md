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

## Start now (no blockers)
| Ticket | Who |
|---|---|
| #8 — 07 Saved Products independent of the feed | Local agent (Flutter) |
| #9 — 08 Events log, debug screen & ad counter | Local agent (Flutter) |
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
  - **Interests are stored but don't change the feed yet.** Ranking (#10) uses them.
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
- Not covered because the app doesn't have it yet: the Saved screen only lists Saved Products that are in the feed currently loaded (no stored snapshot yet, #8).

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
- `dart format`, `flutter analyze` (no issues), `flutter test` (198 passing, 6 golden tests skipped off Linux): passing on Windows as of #7.
- Android: built and tested every night by the Nightly Android check (#39).

## Known gaps carried forward
- The Save button on a Feed Item sits under the search bar (visible in `test/goldens/goldens/feed_item_affiliate_ad.png`).
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Prices aren't converted to the Shopper's currency, and interests don't change the feed yet (see #6 above).

## Launch country
Undecided (decided in #24 based on Awin approvals).

# Stafeed — Project Status

_Last updated: 2026-11-13_ · "Stafeed" is a working name.

- Spec: [#1](https://github.com/danieljreije/stafeed/issues/1) — tickets are its sub-issues (#2–#30), with native "blocked by" links
- Glossary: `CONTEXT.md` · Decisions: `docs/adr/` · Background vision: `docs/STAFEED_PRODUCT_SPEC.md`
- Superseded by the spec: `docs/STAFEED_ROADMAP.md` (kept for history)

## Done
- #2 — 01 Data gateway + Fixtures; DummyJSON removed (2026-11-11)
- #3 — 02 Reliable feed: paging, stale results, retry, refresh, states (2026-11-13, built by the orchestrator)

## Start now (no blockers)
| Ticket | Who |
|---|---|
| #4 — 03 Feed Item kinds & labels (adds the AD label) | Local agent (Flutter) |
| #6 — 05 App shell, onboarding & Destination Country | Local agent (Flutter) |
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

## CI gate (#32)
- Workflow: `.github/workflows/ci.yml` (`CI`), runs on every PR to `main` on `ubuntu-latest`, Flutter pinned to 3.47.2 stable.
- Required checks on `main` (branch protection, #37): **`format, analyze, test`** and **`goldens`** (#35, required since 2026-11-13). The first is shown in the PR checks list as `CI / format, analyze, test (pull_request)`.
- Steps inside that check: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --exclude-tags golden` (goldens have their own check, below). Analyze and test still run when format fails, so one run reports every problem.
- Proven 2026-11-12: green on PR #46 ([run](https://github.com/danieljreije/stafeed/actions/runs/43303624382)); red on deliberately broken PR #47 (format error + failing test, both caught; [run](https://github.com/danieljreije/stafeed/actions/runs/43303652959)), closed unmerged.
- **`web end-to-end`** (#36) also runs on every PR. It becomes required once PR #53 merges. Each check has its own section below.

## Golden check (#35)
- Golden (screenshot) tests: `test/goldens/feed_goldens_test.dart`, images in `test/goldens/goldens/`. They start the whole app on Fixtures (through `dataGatewayProvider`) and cover each Feed Item kind in the app today (Affiliate Ad) plus the loading, empty and error feed states, with the search field, chips and sample-data marker visible.
- Required check name: **`goldens`** — a second job in `.github/workflows/ci.yml`, shown as `CI / goldens (pull_request)`. Required on `main` since 2026-11-13.
- Goldens only run on Linux (tag `golden`); on Windows `flutter test` skips them. Text uses real Roboto/Material Icons kept in `test/goldens/fonts/`.
- When the check fails, the run's **Artifacts** has `golden-failures` with before/after/diff pictures.
- **Intended UI change?** Add the label **`update goldens`** to the PR (or Actions → "Update goldens" → Run workflow on the PR branch). It regenerates the images on Linux, commits them to the PR branch, removes the label and re-runs CI. Look at the new images in "Files changed" before merging.
  - GitHub doesn't start checks for commits the workflow pushes itself, so it starts CI by hand (a `workflow_dispatch` run). An extra "CI" run marked "action required" may also appear for that commit; ignore it.
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
- Test: `integration_test/shopper_journey_test.dart`. Starts the whole app from `main()` on the Fixture data gateway (no backend, no credentials) in headless Chrome, then acts like a Shopper: swipes through For You, saves a Product and finds it in Saved, searches, gets the empty state from a no-match search, and recovers with the category chips.
- Run it locally: start chromedriver (matching your Chrome version) with `chromedriver --port=4444`, then
  `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/shopper_journey_test.dart -d web-server --browser-name=chrome --browser-dimension=430x932 --headless`
- It found two real feed bugs: the feed card was only as tall as the search box and chips (~155px; fixed in #35, which found it too), and the Save heart sat under the search box where it couldn't be tapped (fixed in #36).
- Not required yet: it becomes a required check on `main` once PR #53 merges.
- Not covered because the app doesn't have it yet: the feed has no on-screen Back button (the test uses the browser's Back), and the Saved screen only lists Saved Products that are in the feed currently loaded (no stored snapshot yet).

## Orchestrator (#38 dry run, #41 live)
- Run prompt: `docs/agents/orchestrator-run.md`, with a `DRY_RUN` switch (missing switch = dry run). Picks the first ticket in spec order (#31's sub-issues, then #1's) that is open, `ready-for-agent`, unassigned, has no open blockers and no PR; claims it, builds it test-first in a worktree off `main` (under `.claude/worktrees/`), opens a PR with `PROJECT_STATUS.md` updated, turns on auto-merge and follows CI. It never weakens, skips or deletes a test to get green.
- Give-up path: after two red attempts, any permission block, or a ticket that can't be done as written, it comments on the ticket (`Stafeed orchestrator gave up: ...`), unassigns itself, swaps `ready-for-agent` for `ready-for-human`, sends you a push notification and stops. The next run skips that ticket and takes the next one.
- Scheduled task: `stafeed-orchestrator` (Claude desktop app, on this PC), prompt in `docs/agents/orchestrator-scheduled-task.md`. Auto mode, never bypass-permissions; `.claude/settings.json` allows `flutter`, `dart`, `git`, `gh`. It only runs while the PC is on and the Claude app is open.
- To keep the loop off a ticket (e.g. you or another session is working on it), assign it to someone: assigned tickets are skipped.
- Tickets whose PR merged before `main` became the default branch (#32, #34) stayed open; the first live run closed them on 2026-11-13. A live run closes such "done but still open" tickets itself.

### Pause and resume the loop
- **Pause:** Claude desktop app → **Scheduled** (left sidebar) → `Stafeed orchestrator` → switch it **off**. No new runs start. A run already going finishes by itself; to stop it now, open its session (it shows under the task's runs) and press stop.
- **Resume:** same place, switch it back **on**. The next run starts at the next even hour.
- **Run once now:** same place → **Run now** (only while it is switched on).
- **Back to dry runs** (reports only, writes nothing): replace the task's prompt with the dry-run prompt in `docs/agents/orchestrator-scheduled-task.md`.
- Pausing never loses work: an open orchestrator PR is picked up again by the next run (step 0 of the run prompt).

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (72 passing, 4 golden tests skipped off Linux): passing on Windows as of #3.
- Android build: not run since the course prototype.

## Known gaps carried forward
- The Save button on a Feed Item sits under the search bar (visible in `test/goldens/goldens/feed_item_affiliate_ad.png`).
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Offers aren't yet filtered by Destination Country (#6).

## Launch country
Undecided (decided in #24 based on Awin approvals).

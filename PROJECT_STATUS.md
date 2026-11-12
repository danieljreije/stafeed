# Stafeed — Project Status

_Last updated: 2026-11-13_ · "Stafeed" is a working name.

- Spec: [#1](https://github.com/danieljreije/stafeed/issues/1) — tickets are its sub-issues (#2–#30), with native "blocked by" links
- Glossary: `CONTEXT.md` · Decisions: `docs/adr/` · Background vision: `docs/STAFEED_PRODUCT_SPEC.md`
- Superseded by the spec: `docs/STAFEED_ROADMAP.md` (kept for history)

## Done
- #2 — 01 Data gateway + Fixtures; DummyJSON removed (2026-11-11)

## Start now (no blockers)
| Ticket | Who |
|---|---|
| #4 — 03 Feed Item kinds & labels (adds the AD label) | Local agent (Flutter) |
| #6 — 05 App shell, onboarding & Destination Country | Local agent (Flutter) |
| #3 — 02 Reliable feed: paging, states, retry, refresh | Local agent (Flutter) |
| #5 — 04 Video-feed prototype | Local agent (Flutter) + real Android phone |
| #15 — 14 Backend first slice | Cloud agent |
| #26 — 25 Research: pay-per-click networks | Cloud agent |
| #14 — 13 Create Supabase project | You |
| #24 — 23 Apply to Awin; launch country | You |
| #27 — 26 Apply for Shopify Catalog access | You |
| #30 — 29 Final name & store IDs | You (before first store upload) |

## CI gate (#32)
- Workflow: `.github/workflows/ci.yml` (`CI`), runs on every PR to `main` on `ubuntu-latest`, Flutter pinned to 3.47.2 stable.
- Required check name (for branch protection, #37): **`format, analyze, test`** — shown in the PR checks list as `CI / format, analyze, test (pull_request)`.
- Steps inside that check: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`. Analyze and test still run when format fails, so one run reports every problem.
- Proven 2026-11-12: green on PR #46 ([run](https://github.com/danieljreije/stafeed/actions/runs/43303624382)); red on deliberately broken PR #47 (format error + failing test, both caught; [run](https://github.com/danieljreije/stafeed/actions/runs/43303652959)), closed unmerged.
- Second check: **`web end-to-end`** (#36), see below. Must be added to `main`'s required checks once green on its PR (see "Adding a required check").
- Later gate tickets (#35 goldens) add their own check names here.

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
- Required check name: **`web end-to-end`** — shown as `CI / web end-to-end (pull_request)`. Separate job in `.github/workflows/ci.yml`, runs on every PR to `main`.
- Test: `integration_test/shopper_journey_test.dart`. Starts the whole app from `main()` on the Fixture data gateway (no backend, no credentials) in headless Chrome, then acts like a Shopper: swipes through For You, saves a Product and finds it in Saved, searches, gets the empty state from a no-match search, and recovers with the category chips.
- Run it locally: start chromedriver (matching your Chrome version) with `chromedriver --port=4444`, then
  `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/shopper_journey_test.dart -d web-server --browser-name=chrome --browser-dimension=430x932 --headless`
- It found and fixed two real feed bugs: the feed card was only as tall as the search box and chips (~155px), and the Save heart sat under the search box where it couldn't be tapped.
- Not covered because the app doesn't have it yet: the feed has no on-screen Back button (the test uses the browser's Back), and the Saved screen only lists Saved Products that are in the feed currently loaded (no stored snapshot yet).

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (33/33): passing on Windows as of #2.
- Android build: not run since the course prototype.

## Known gaps carried forward
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Offers aren't yet filtered by Destination Country (#6).

## Launch country
Undecided (decided in #24 based on Awin approvals).

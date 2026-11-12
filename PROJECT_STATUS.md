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
- Steps inside that check: `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --exclude-tags golden` (goldens have their own check, below). Analyze and test still run when format fails, so one run reports every problem.
- Proven 2026-11-12: green on PR #46 ([run](https://github.com/danieljreije/stafeed/actions/runs/43303624382)); red on deliberately broken PR #47 (format error + failing test, both caught; [run](https://github.com/danieljreije/stafeed/actions/runs/43303652959)), closed unmerged.
- Later gate tickets (#35 goldens, #36 web end-to-end) add their own check names here.

## Golden check (#35)
- Golden (screenshot) tests: `test/goldens/feed_goldens_test.dart`, images in `test/goldens/goldens/`. They start the whole app on Fixtures (through `dataGatewayProvider`) and cover each Feed Item kind in the app today (Affiliate Ad) plus the loading, empty and error feed states, with the search field, chips and sample-data marker visible.
- Required check name: **`goldens`** — a second job in `.github/workflows/ci.yml`, shown as `CI / goldens (pull_request)`. Not yet in branch protection's required list: add it after the #35 PR merges (see "Adding a required check" below).
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

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (33/33): passing on Windows as of #2.
- Android build: not run since the course prototype.

## Known gaps carried forward
- The Save button on a Feed Item sits under the search bar (visible in `test/goldens/goldens/feed_item_affiliate_ad.png`).
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Offers aren't yet filtered by Destination Country (#6).

## Launch country
Undecided (decided in #24 based on Awin approvals).

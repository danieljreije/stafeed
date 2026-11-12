# Stafeed — Project Status

_Last updated: 2026-11-11_ · "Stafeed" is a working name.

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
- Later gate tickets (#35 goldens, #36 web end-to-end) add their own check names here.

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (33/33): passing on Windows as of #2.
- Android build: not run since the course prototype.

## Known gaps carried forward
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Offers aren't yet filtered by Destination Country (#6).

## Launch country
Undecided (decided in #24 based on Awin approvals).

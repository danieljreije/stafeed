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

## Verification
- `dart format`, `flutter analyze` (no issues), `flutter test` (33/33): passing on Windows as of #2.
- Android build: not run since the course prototype.

## Known gaps carried forward
- Fixture images load from picsum.photos, so cards show a placeholder when offline.
- Offers aren't yet filtered by Destination Country (#6).

## Launch country
Undecided (decided in #24 based on Awin approvals).

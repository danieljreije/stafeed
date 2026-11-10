# Stafeed

Flutter + Riverpod app: a vertical, swipeable shopping-discovery feed. Stafeed hands buyers off to the merchant; it never takes payment.

- Product spec (primary source of truth): `docs/STAFEED_PRODUCT_SPEC.md`
- Current status: `PROJECT_STATUS.md`
- Code lives under `lib/app/features/`. Keep that feature-first layout.
- Never put secret keys (Shopify, Awin, Supabase service role) in the app.
- Label demo data honestly: Fixtures are not real commercial inventory, and the app shows a "sample data" marker when it runs on them.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for `danieljreije/stafeed` (use `gh`; REST fallback when GraphQL is blocked). See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` plus `docs/adr/` at the repo root. See `docs/agents/domain.md`.

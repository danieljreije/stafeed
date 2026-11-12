# Orchestrator run prompt

One run of the Stafeed build loop (spec #31, ADR-0003). A scheduled Claude Code task on the owner's PC starts a fresh session, hands it this file and says whether this run is a dry run. One run builds at most one ticket.

## Switch

```
DRY_RUN = true
```

The scheduled task's own prompt overrides this line: it says `DRY_RUN = true` or `DRY_RUN = false`. If nothing says otherwise, **treat the run as a dry run**. Going live is ticket #41.

- **Dry run:** read the tracker, pick the ticket, explain every skip, print the report (see "Dry-run report"). **Write nothing**: no assignee, label, comment, branch, worktree, commit, push, PR or file. Read-only `gh` and `git` commands only.
- **Live run:** do every step below.

## Ground rules (both modes)

- Read `CLAUDE.md`, `CONTEXT.md`, `PROJECT_STATUS.md`, `docs/agents/*.md` and the ADRs in `docs/adr/` before acting. Use the glossary's words.
- `gh` may not be on `PATH`; on the owner's PC it is `"/c/Program Files/GitHub CLI/gh.exe"`. If GraphQL is blocked, use the REST forms in `docs/agents/issue-tracker.md`. Repo: `danieljreije/stafeed`. All work targets `main` (GitHub's default branch may still be `master`; never use it).
- Run shell commands with the Bash tool so the project allowlist in `.claude/settings.json` applies (`flutter`, `dart`, `git`, `gh`). The session runs in auto mode; never bypass-permissions.
- **Never weaken, skip or delete a test to get green.** The test suite is the definition of done (ADR-0003). That includes golden images: update a golden only when the ticket asks for that UI change, and only through the "update goldens" workflow.
- If a command you need is blocked by permissions, do not work around it: take the give-up path below.
- Never touch the owner's own checkout. Never force-push, never push to `main` directly, never merge with admin rights, never edit branch protection or CI to get a PR through.
- Don't commit the generated plugin registrant files under `linux/`, `macos/` or `windows/`.
- Never put secret keys in the app (see `CLAUDE.md`).

## Step 0 - finish work already in flight (live only)

One ticket at a time. Find open PRs whose body contains `Opened by the Stafeed orchestrator`. If there is one, this run continues that PR (go to step 5 with its ticket) instead of picking a new ticket. In a dry run, if there is one, report "would continue PR #n" and still show the frontier below.

## Step 1 - find the frontier

**Spec order.** Specs in this order, each one's tickets in its sub-issue order:

1. #31 (autonomous build loop)
2. #1 (Stafeed v1)

```bash
gh api "repos/danieljreije/stafeed/issues/31/sub_issues?per_page=100"
gh api "repos/danieljreije/stafeed/issues/1/sub_issues?per_page=100"
```

Each sub-issue carries `state`, `labels`, `assignees` and `issue_dependencies_summary.blocked_by` (number of **open** blockers). For a ticket with open blockers, list them with `gh api repos/danieljreije/stafeed/issues/<n>/dependencies/blocked_by`.

**Pull requests per ticket.** List every PR once:

```bash
gh pr list --repo danieljreije/stafeed --state all --limit 200 --json number,state,title,headRefName,body
```

A PR belongs to ticket N if its head branch contains `ticket-N-`, or its title contains `(#N)`. Closed-unmerged PRs don't count.

**Walk the tickets in spec order. The first ticket that passes every check wins.** Check in this order and give the first reason that applies:

| Check | Skip reason to report |
|---|---|
| state is closed | `closed` |
| has label `ready-for-human` | `ready-for-human` (the owner does this one) |
| lacks label `ready-for-agent` | `not ready-for-agent` (name its labels) |
| a merged PR belongs to it | `done but still open` (name the PR; the owner or a live run should close it) |
| an open PR belongs to it | `in progress` (name the PR) |
| has any assignee | `assigned to <login>` |
| `blocked_by` > 0 | `blocked by #a, #b` (open blockers; add "its PR #p is merged" when a blocker is itself done-but-open) |

Spec parents themselves (#1, #31) are never candidates. If nothing passes, report "nothing to do" and stop (live: no writes either).

## Step 2 - claim (live only)

First write of the run: `gh issue edit <n> --repo danieljreije/stafeed --add-assignee @me`. Re-read the ticket; if someone else got there first, stop.

In a live run, also close any `done but still open` ticket found in step 1 with a comment naming its merged PR (`gh issue close <n> --comment "..."`), so its dependants unblock next run.

## Step 3 - worktree off main (live only)

```bash
git fetch origin
git worktree add ../stafeed-ticket-<n> -b claude/ticket-<n>-<short-slug> origin/main
```

Work only inside that worktree.

## Step 4 - build

Read the ticket with comments (`gh issue view <n> --comments`) and its parent spec. Then run `/implement` for the ticket. If `/implement` is not installed, do what it does: build test-first with `/tdd`, then review your own diff against the ticket and the repo's standards with `/code-review` and fix what it finds.

Before pushing, all of these must pass locally:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Update `PROJECT_STATUS.md` in the same PR (what is now done, how it was verified, anything the owner must know).

## Step 5 - PR and CI

Push the branch and open a PR to `main`:

- Title ends with `(#<n>)`.
- Body: what was built, what was tested, preview link if one exists, `Closes #<n>`, and the line `Opened by the Stafeed orchestrator`.

Enable auto-merge (`gh pr merge <pr> --auto --squash`) once branch protection exists (#37). Follow the checks (`gh pr checks <pr> --watch`). When CI is red, read the failing log, fix the cause in the same worktree, push. When the PR merges, close the ticket with a comment naming the PR (the `Closes` keyword does not fire while GitHub's default branch is `master`).

## Give-up path

After **two** failed attempts to get CI green (an attempt = one push that comes back red), or as soon as a command is blocked by permissions:

1. Comment on the ticket: what was tried, what failed (link the CI run), what a human needs to do.
2. Unassign yourself, remove `ready-for-agent`, add `ready-for-human`.
3. Leave the PR open as a draft for the owner, or close it if it contains nothing useful.
4. Send a push notification: `Stafeed: #<n> needs you - <one line why>`.
5. Stop. Don't start another ticket in this run.

## Dry-run report

Print exactly this shape, then stop:

```
Stafeed orchestrator - DRY RUN - <date, time>
Would take: #<n> <title>   (spec #<parent>, position <k>)
Why: first ticket in spec order that is open, ready-for-agent, unassigned, has no open blockers and no PR.
In flight: <"none" or "would continue PR #p for #n">

Skipped, in spec order:
- #<n> <title>: <reason>
- ...

Notes for the owner: <anything odd, e.g. tickets done but still open>
Writes made: none
```

List every ticket under both specs that comes before the pick, and every later ticket too, each with its skip reason (tickets after the pick that would also have passed are listed as `eligible, later in spec order`).

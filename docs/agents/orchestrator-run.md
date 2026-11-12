# Orchestrator run prompt

One run of the Stafeed build loop (spec #31, ADR-0003). A scheduled Claude Code task on the owner's PC starts a fresh session, hands it this file and says whether this run is a dry run. One run builds at most one ticket.

## Switch

```
DRY_RUN = true
```

The scheduled task's own prompt overrides this line: it says `DRY_RUN = true` or `DRY_RUN = false`. If nothing says otherwise, **treat the run as a dry run**. The scheduled task went live in #41.

- **Dry run:** read the tracker, pick the ticket, explain every skip, print the report (see "Dry-run report"). **Write nothing**: no assignee, label, comment, branch, worktree, commit, push, PR or file. Read-only `gh` and `git` commands only.
- **Live run:** do every step below.

## Ground rules (both modes)

- Read `CLAUDE.md`, `CONTEXT.md`, `PROJECT_STATUS.md`, `docs/agents/*.md` and the ADRs in `docs/adr/` before acting. Use the glossary's words.
- `gh` may not be on `PATH`; on the owner's PC it is `"/c/Program Files/GitHub CLI/gh.exe"`. If GraphQL is blocked, use the REST forms in `docs/agents/issue-tracker.md`. Repo: `danieljreije/stafeed`. All work targets `main`.
- Run shell commands with the Bash tool so the project allowlist in `.claude/settings.json` applies (`flutter`, `dart`, `git`, `gh`). The session runs in auto mode; never bypass-permissions.
- **Never weaken, skip or delete a test to get green.** The test suite is the definition of done (ADR-0003). That means: no deleting or commenting out tests, no `skip:`, no loosening an expectation so broken code passes, no removing a check from CI, no excluding files from `flutter analyze`. It includes golden images and the web end-to-end test: update a golden only when the ticket asks for that UI change, and only through the "update goldens" workflow. Changing a test is fine only when the ticket itself changes the behaviour that test describes; say so in the PR body. If you think an existing test is wrong and the ticket doesn't cover it, don't touch it: take the give-up path.
- If a command or tool call you need is blocked by permissions (denied, or it would need someone to approve it), do not work around it: take the give-up path below. Nobody is watching a scheduled run.
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

The run starts in the owner's checkout. Leave it alone (it may have uncommitted work; don't switch its branch, stash, reset or commit there). Create the worktree inside it, under the git-ignored `.claude/worktrees/`, so it stays within the session's working folder:

```bash
git fetch origin
git worktree add .claude/worktrees/orchestrator-ticket-<n> -b claude/ticket-<n>-<short-slug> origin/main
cd .claude/worktrees/orchestrator-ticket-<n>
```

Work only inside that worktree. When step 0 continues an existing PR, add the worktree on its branch instead (`git worktree add .claude/worktrees/orchestrator-ticket-<n> <branch>` after `git fetch origin`), or reuse it if it is still there.

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

**Turn on auto-merge right after opening the PR** (`gh pr merge <pr> --auto --merge`), then confirm it took: `gh pr view <pr> --json autoMergeRequest` must not be `null`. Branch protection (#37) merges the PR once every required check is green (`format, analyze, test`, `goldens`, `web end-to-end`). No human approves it. Never use `--admin`.

Follow the checks (`gh pr checks <pr> --watch`). When CI is red, read the failing log (`gh run view <run-id> --log-failed`), fix the cause in the same worktree, push. A `goldens` failure from a UI change the ticket asks for: add the `update goldens` label and look at the new images; any other `goldens` failure is a bug to fix. When the PR merges, check the ticket closed (`Closes #<n>` does it); if not, close it with a comment naming the PR.

Finish by removing the worktree (`git worktree remove .claude/worktrees/orchestrator-ticket-<n>` from the owner's checkout) and printing a short live report: ticket, PR link, merged or not, tickets closed as done-but-open. One ticket per run: stop there.

## Give-up path

Take it on whichever comes first:

- **two failed attempts**: two pushes whose CI came back red (count every red run on the PR, including runs from earlier orchestrator runs that you continued in step 0), or two rounds of fixing where the local checks in step 4 still fail;
- **a permission block**: any command or tool call denied or waiting for approval;
- the ticket can't be done as written (it contradicts a test, needs a secret key, a real device, an account, or a decision only the owner can make).

Then:

1. Comment on the ticket: what was tried, what failed (link the CI run or quote the local error / the blocked command), what a human needs to do. Start the comment with `Stafeed orchestrator gave up:`.
2. Unassign yourself, remove `ready-for-agent`, add `ready-for-human` (`gh issue edit <n> --remove-assignee @me --remove-label ready-for-agent --add-label ready-for-human`). Re-read the ticket to check all three took.
3. If there is a PR: turn auto-merge off (`gh pr merge <pr> --disable-auto`), then leave it open as a draft for the owner (`gh pr ready <pr> --undo`), or close it if it contains nothing useful. Remove the worktree.
4. Send a push notification with the `PushNotification` tool: `Stafeed: #<n> needs you - <one line why>`.
5. Print the live report (as in step 5, saying it gave up) and stop. Don't start another ticket in this run. That's how the loop moves on: the ticket is now `ready-for-human`, so the next run skips it and takes the next ticket in the frontier.

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

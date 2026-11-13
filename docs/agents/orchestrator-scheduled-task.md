# Orchestrator scheduled task

The Claude Code scheduled task that runs the build loop on the owner's PC (spec #31). Live since #41: every two hours, one ticket per run.

- Task id: `stafeed-orchestrator`
- Title: `Stafeed orchestrator`
- Schedule: every two hours (cron `0 */2 * * *`, local time; the app adds a few minutes of delay). If a run is still going when the next one is due, the app doesn't start a second one.
- Working folder: the owner's checkout (`D:\Claude Projects\Stafeed\stafeed`). The run doesn't change it; it builds in a worktree under `.claude/worktrees/`.
- Permission mode: auto, never bypass-permissions. The allowlist lives in `.claude/settings.json`.
- Runs only while the PC is on and the Claude desktop app is open.
- Stored by the app at `C:\Users\<you>\.claude\scheduled-tasks\stafeed-orchestrator\SKILL.md`.

The run prompt itself is `docs/agents/orchestrator-run.md`, read from `main` on GitHub at the start of each run. The task's prompt only sets the switch and points at it, so changing the run prompt on `main` changes every later run.

## Task prompt (live)

```text
You are one run of the Stafeed build-loop orchestrator (GitHub repo danieljreije/stafeed, spec #31).

DRY_RUN = false

This is a LIVE run with nobody watching: build at most one ticket, all the way to a PR that merges itself, or give up cleanly.

1. `gh` may not be on PATH; use "/c/Program Files/GitHub CLI/gh.exe" via the Bash tool. If GitHub GraphQL fails, use the REST forms in docs/agents/issue-tracker.md.
2. You start in the owner's checkout. Do not change it: no checkout, switch, stash, reset, pull, commit or file edits there. Read the run prompt from main on GitHub:
   "/c/Program Files/GitHub CLI/gh.exe" api -H "Accept: application/vnd.github.raw" "repos/danieljreije/stafeed/contents/docs/agents/orchestrator-run.md?ref=main"
   Read CLAUDE.md, CONTEXT.md, PROJECT_STATUS.md, docs/agents/*.md and docs/adr/*.md the same way (ref=main), or from your worktree once you have one.
3. Follow the run prompt exactly with DRY_RUN = false: step 0 to step 5, or the give-up path. One ticket per run.
4. Never weaken, skip or delete a test to get green. If a command or tool call is blocked by permissions, take the give-up path; never work around it.
5. End with the live report the run prompt asks for.
```

## Task prompt (dry run)

To go back to dry runs, replace the task prompt with this one (it writes nothing):

```text
You are one run of the Stafeed build-loop orchestrator (GitHub repo danieljreije/stafeed, spec #31).

DRY_RUN = true

This is a DRY RUN. You must write nothing: no issue/PR edits, assignees, labels, comments, branches, worktrees, commits, pushes or files anywhere. Use only read-only commands. Do not run `git fetch` or anything that changes a checkout.

1. `gh` may not be on PATH; use "/c/Program Files/GitHub CLI/gh.exe" via the Bash tool.
2. Load the run prompt from GitHub (read-only, no checkout needed):
   "/c/Program Files/GitHub CLI/gh.exe" api -H "Accept: application/vnd.github.raw" "repos/danieljreije/stafeed/contents/docs/agents/orchestrator-run.md?ref=main"
   Also read CONTEXT.md, PROJECT_STATUS.md and docs/agents/issue-tracker.md the same way.
3. Follow the run prompt with DRY_RUN = true: step 0 (report in-flight orchestrator PRs only) and step 1 (find the frontier) exactly as written, against the real tracker. Skip every live-only step.
4. Print the "Dry-run report" in exactly the shape the run prompt gives, listing every sub-issue of #31 and #1 with its skip reason, the ticket you would take, and "Writes made: none". That report is the whole output of this run.
```

## Pausing and resuming the loop

See "Orchestrator" in `PROJECT_STATUS.md`.

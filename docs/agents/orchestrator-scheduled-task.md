# Orchestrator scheduled task

The Claude Code scheduled task that runs the build loop on the owner's PC (spec #31). It stays in **dry-run mode, started by hand, no schedule** until ticket #41 makes it live every two hours.

- Task id: `stafeed-orchestrator`
- Title: `Stafeed orchestrator (DRY RUN)`
- Schedule: none (ad-hoc; "Run now" only). #41 sets it to every two hours and `DRY_RUN = false`.
- Permission mode: auto, never bypass-permissions. The allowlist lives in `.claude/settings.json`.
- Stored by the app at `C:\Users\<you>\.claude\scheduled-tasks\stafeed-orchestrator\SKILL.md`.

The run prompt itself is `docs/agents/orchestrator-run.md`. The task's prompt only sets the switch and points at it, so changing the run prompt on `main` changes every later run.

## Task prompt (dry run)

```text
You are one run of the Stafeed build-loop orchestrator (GitHub repo danieljreije/stafeed, spec #31, ticket #38).

DRY_RUN = true

This is a DRY RUN. You must write nothing: no issue/PR edits, assignees, labels, comments, branches, worktrees, commits, pushes or files anywhere. Use only read-only commands. Do not run `git fetch` or anything that changes a checkout.

1. `gh` may not be on PATH; use "/c/Program Files/GitHub CLI/gh.exe" via the Bash tool.
2. Load the run prompt from GitHub (read-only, no checkout needed):
   "/c/Program Files/GitHub CLI/gh.exe" api -H "Accept: application/vnd.github.raw" "repos/danieljreije/stafeed/contents/docs/agents/orchestrator-run.md?ref=main"
   Also read CONTEXT.md, PROJECT_STATUS.md and docs/agents/issue-tracker.md the same way.
3. Follow the run prompt with DRY_RUN = true: step 0 (report in-flight orchestrator PRs only) and step 1 (find the frontier) exactly as written, against the real tracker. Skip every live-only step.
4. Print the "Dry-run report" in exactly the shape the run prompt gives, listing every sub-issue of #31 and #1 with its skip reason, the ticket you would take, and "Writes made: none". That report is the whole output of this run.
```

## Pausing the loop

Open the Claude desktop app → **Scheduled** (sidebar) → `Stafeed orchestrator` → switch it **off**. Nothing runs until you switch it back on. A run already in progress finishes; stop it from its session if you need it to stop now.

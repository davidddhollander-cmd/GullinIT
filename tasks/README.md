# Agent task queue

A simple file-based handoff: Claude Opus plans and reviews, Claude Sonnet writes game code, Codex generates pixel sprite assets.
The protocol every agent follows is in `AGENTS.md` → "Task queue protocol".

```
tasks/
  TEMPLATE.md   copy this to write a new task
  inbox/        waiting to be picked up (oldest number first)
  doing/        claimed and in progress (max one at a time)
  done/         finished, with a report, waiting for review
  LOCK          exists only while an agent is working (who + which task)
```

## Lifecycle

1. **Write:** Claude (or David) copies `TEMPLATE.md` to `inbox/NNN-short-name.md` and fills it in.
2. **Claim:** the implementer creates `tasks/LOCK`, moves the file to `doing/`, and creates branch `codex/NNN-short-name` or `sonnet/NNN-short-name` (per the task's Assignee) from an up-to-date `main`.
3. **Build:** implement, test, commit on the branch. Nothing else on `main`.
4. **Report:** fill in the task's `## Report` section, move the file to `done/`, push the branch, delete `LOCK`.
5. **Review:** Claude reviews the diff and report, then either merges to `main` (and sets `Status: merged`) or adds `## Review notes` and moves the file back to `inbox/` with `Status: changes requested`.

## How David runs a round

- Tell Codex: **"Process the task queue."**
- When it's done, tell Claude: **"Review the task queue."**

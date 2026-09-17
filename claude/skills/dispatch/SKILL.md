---
name: dispatch
description: Start one task in its own worktree as a background session running /task-build. Given a ticket URL, starts that one. Given nothing, picks the next ticket if the gates allow. Meant to run on a loop.
---

# Dispatch

## With a ticket URL

1. Get the branch name from the ticket.
2. `zsh -ic 'wk <branch>'` from the repo root.
   - Stacking on an open PR: `zsh -ic 'wk -h <branch>'` from that PR's worktree instead, and tell the task session to base its PR on the parent branch.
3. From the worktree: `CLAUDE_SESSION_BUDGET_TOKENS=10000000 CLAUDE_CODE_AUTO_COMPACT_WINDOW=200000 claude --bg --name <TICKET-ID> "/task-build <url>"`. The budget variable is what turns the token guard on; the budget is weighted, cache reads at a tenth. The window variable compacts at 200k instead of the model's 1M, since a re-read of the whole context is the cost of every turn. Both are inherited by the `/task-review` session that `/task-build` starts. The session shows up in `claude agents`.
4. Move the ticket to In Progress.

## Without one

Pick nothing unless every gate holds:

- Free memory above 8 GB.
- The default branch's last CI run is green.

Then take the most important ticket and run the steps above. One task per run.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

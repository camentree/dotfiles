---
name: dispatch
description: Start one task in its own worktree as a background session running /task. Given a ticket URL, starts that one. Given nothing, picks the next ticket if the gates allow. Meant to run on a loop.
---

# Dispatch

## With a ticket URL

1. Get the branch name from the ticket.
2. `zsh -ic 'wk <branch>'` from the repo root.
3. From the worktree: `CLAUDE_SESSION_BUDGET_TOKENS=5000000 claude --bg --name <TICKET-ID> "/task <url>"`. The budget variable is what turns the token guard on. The session shows up in `claude agents`.
4. Move the ticket to In Progress.

## Without one

Pick nothing unless every gate holds:

- Free memory above 8 GB.
- The default branch's last CI run is green.

Then take the most important ticket and run the steps above. One task per run.

If you hit a blocker this skill didn't anticipate, solve it, then update this skill so the next run doesn't hit it.

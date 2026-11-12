---
name: task-review
description: Session two of a task, started by /manage when Camen says to review. Sequences /review, /verify with the pre-push checks, and /pr. Run the steps by hand instead when you want just one of them.
---

# Task review

Input: the plan file, `~/.claude/tasks/<repo>/<branch>/plan.md`, where `<repo>` is the `basename` of `git remote get-url origin` without `.git` and `<branch>` is `git branch --show-current`.

1. `/review`. Ends when Camen says the branch is good.
2. Verify. Each pass is a `worker` subagent whose whole prompt is `Run /verify <plan> --pre-push`. Its findings go into the plan, whole, under a group named `fixes`, and a `worker` builds it, `Build fixes of <plan>`, then verify again. When a pass fixes less than the one before, or a finding comes back: say what is failing, end the turn without pushing.
3. `/pr`. Print the URL, end the turn.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

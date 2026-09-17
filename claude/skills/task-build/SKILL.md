---
name: task-build
description: Session one of a task, started by /dispatch in the task's worktree. Sequences /plan, /build, and /verify, then hands the branch to /task-review in a new background session. Resumes from the plan file. Run the steps by hand instead when you want just one of them.
---

# Task build

The argument is what `/plan` takes. `<name>` and the plan path are as in `/plan`.

1. `/plan`, unless the plan file already has acceptance criteria.
2. `/build <plan>`. Groups already marked done are skipped.
3. Verify, at most three passes. Each pass is a general-purpose subagent whose whole prompt is `Run /verify <plan>`. Its findings go to a subagent running `/build <plan> <group>` for the group that owns them, or a new group named `fixes` when none does, then verify again. Three passes without a clean result: say which criterion and what was tried, end the turn.
4. From the worktree: `claude --bg --name <name>-review "/task-review <plan>"`. End the turn.

This session never reads code or test output; the subagents do, which keeps it at the size of the plan. A question asked inside a step ends the turn there, the session shows as Needs input in `claude agents`, and the answer resumes it in place.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

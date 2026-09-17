---
name: task-review
description: Session two of a task, started by /task-build. Sequences /review, /verify with the pre-push checks, and /pr. Run the steps by hand instead when you want just one of them.
---

# Task review

Input: the plan file.

1. `/review`. Ends when Camen says the branch is good.
2. Verify, at most three passes. Each pass is a general-purpose subagent whose whole prompt is `Run /verify <plan> --pre-push`. Its findings go to a subagent running `/build <plan> <group>` for the group that owns them, or a new group named `fixes`, then verify again. Three passes without a clean result: say what is failing, end the turn without pushing.
3. `/pr`. Print the URL, end the turn. From here `/monitor-prs` owns the branch.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

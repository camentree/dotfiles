---
name: verify
description: Verify the current branch against its plan file. Independent checks, cheapest first; the pre-push checks only with --pre-push. Reports findings, fixes nothing, starts nothing.
---

# Verify

Input: the plan file for the current branch under `~/.claude/tasks/`, and `--pre-push` when the result is about to be pushed. Rebase onto the default branch first.

Run in this order and stop at the first failure:

*when saying CLAUDE.md here, that includes any CLAUDE.local.md*

1. The specs that cover the change compile and pass.
2. Scope: the diff against the default branch touches only the plan's files, or the exception is in its Decisions.
3. Criteria (Style and acceptance criteria). A fresh sub-agent gets the plan file, the diff, and every `## Code style checks` section from the CLAUDE.md and CLAUDE.local.md files apply from root to the changed files
    - Style: It returns findings as `file:line`, the rule, and the fix.
    - Acceptance Criteria: For each acceptance criterion it finds the test or runs the check that proves it, confirms the check exercises the criterion rather than merely passing, and marks pass, fail, or weak.
4. With `--pre-push` only: what the repo's CLAUDE.md says must pass before a push, run the way it says to run it. If it names nothing, the repo's unit and integration tests. Long runs go to a log in the background. A failure that also fails on the default branch with the same message is environmental; note it and move on. What the repo leaves to CI, `/monitor-prs` picks up after the push.

Without `--pre-push`, steps 1–3 are the whole check. Start it only after step 3's findings are fixed and committed, and touch nothing in the tree while it runs: an edit mid-run costs a second preflight (six minutes of cold compile).

Report the result per criterion, findings as `file:line`, the rule, and the fix. Fix nothing here: the caller sends findings to `/build <plan> <group>` and runs this again, and by hand that caller is Camen.

Project-specific checks live in the project's CLAUDE.md or CLAUDE.local.md: how to run it, how to hit it, how to seed state, where the logs are. Use them in steps 1 and 4. If not there or you need something not mentioned, update the relevant CLAUDE{.local}.md with your learnings.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.


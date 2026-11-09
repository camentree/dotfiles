---
name: verify
description: Verify the current branch against its plan file. Independent checks, cheapest first, ending in a code review on the first pass; the pre-push checks only with --pre-push. Reports findings, fixes nothing, starts nothing.
---

# Verify

Input: the plan file for the current branch under `~/.claude/tasks/`, `--pre-push` when the result is about to be pushed, and `--since <sha>` when an earlier pass already checked the branch up to that commit. The base branch is `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch.

Run in this order and stop at the first failure:

*when saying CLAUDE.md here, that includes any CLAUDE.local.md*

1. The specs that cover the change compile and pass.
2. Scope: the diff against the base branch touches only the plan's files, or the exception is in its Decisions.
3. Review (style, acceptance criteria, correctness), by an agent that did not build the branch: you, when this check is all you were started for, else a fresh sub-agent. It gets the plan file, the diff, and every `## Code style checks` section from the CLAUDE.md and CLAUDE.local.md files that apply from root to the changed files
    - Style: It returns findings as `file:line`, the rule, and the fix.
    - Acceptance Criteria: For each acceptance criterion it finds the test or runs the check that proves it, confirms the check exercises the criterion rather than merely passing, and marks pass, fail, or weak.
    - Correctness: `/code-review high <base>...HEAD`, where `<base>` is `git merge-base HEAD origin/<base branch>`. Its findings join the others. Not with `--since` or `--pre-push`: those passes cover a branch that has already been reviewed.
4. With `--pre-push` only: what the repo's CLAUDE.md says must pass before a push, run the way it says to run it. If it names nothing, the repo's unit and integration tests. Long runs go to a log in the background. A failure that also fails on the default branch with the same message is environmental; note it and move on. What the repo leaves to CI runs after the push.

With `--since <sha>`, an earlier pass checked the branch up to `<sha>` and this one covers what changed after it:

- Step 1 runs as written, over the specs that cover the whole change. That is what shows nothing already verified broke.
- Steps 2 and 3 read only `git diff <sha> HEAD`. A criterion that diff does not touch keeps its earlier result. A criterion it touches, and each finding the diff was meant to fix, is checked again.

Without `--pre-push`, steps 1–3 are the whole check. Start it only after step 3's findings are fixed and committed, and touch nothing in the tree while it runs: an edit mid-run costs a second preflight (six minutes of cold compile).

Report the result per criterion, findings as `file:line`, the rule, and the fix. Fix nothing here: the caller sends the findings to a build and runs this again, and by hand that caller is Camen.

Project-specific checks live in the project's CLAUDE.md or CLAUDE.local.md: how to run it, how to hit it, how to seed state, where the logs are. Use them in steps 1 and 4. If not there or you need something not mentioned, update the relevant CLAUDE{.local}.md with your learnings.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.


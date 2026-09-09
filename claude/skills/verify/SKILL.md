---
name: verify
description: Verify the current branch against its plan file. Independent checks, cheapest first. Runs from /task after build and after review changes, or on its own.
---

# Verify

Input: the plan file for the current branch under `~/.claude/tasks/`. Rebase onto the default branch first.

Run in this order and stop at the first failure:

1. Compiles with no new warnings.
2. Scope: the diff against the default branch touches only the plan's files, or the exception is in its Decisions.
3. The affected module's full test suite passes.
4. Style. A fresh sub-agent gets the diff, the files beside each changed one, and every `## Code style checks` section from the CLAUDE.md and CLAUDE.local.md files that apply to the changed files: `~/.claude/CLAUDE.md`, then each one on the path from the repo root down to the changed file's directory. A sub-project's rules apply only to changes inside it. It returns findings as `file:line`, the rule, and the fix. Anything it reports gets fixed.
5. Criteria. A fresh sub-agent gets only the plan file and the diff and grades every criterion. For each one it finds the test or runs the check that proves it, confirms the check exercises the criterion rather than merely passing, and marks pass, fail, or weak.

Report the result per criterion. A failure goes back to the build steps of `/task` for that fix, then this loop restarts from step one. Three full passes without success means the plan is wrong. Say which criterion and what was tried, and end the turn.

Project-specific checks live in the project's CLAUDE.md: how to run it, how to hit it, how to seed state, where the logs are. Use them in steps 3 and 5.

If you hit a blocker this skill didn't anticipate, solve it, then update this skill so the next run doesn't hit it.

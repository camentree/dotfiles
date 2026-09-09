---
name: pr
description: Push the current branch and open or update its pull request, with the description drafted from the plan file. Runs after review approval.
---

# PR

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`.

1. Read the project's CLAUDE.md for the PR template, title convention, labels, and assignee.
2. Draft the description from the plan file, or from the branch diff if there is none: what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test. Follow the project's template where there is one.
3. Push. Create with `gh pr create`, or update the existing PR's body with `gh pr edit`.
4. Print the title, the description, and the PR URL.

If you hit a blocker this skill didn't anticipate, solve it, then update this skill so the next run doesn't hit it.

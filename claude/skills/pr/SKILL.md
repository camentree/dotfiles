---
name: pr
description: Push the current branch and open or update its pull request, with the description drafted from the plan file. Runs after review approval.
---

# PR

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`.

1. `/verify` has passed on the commit being pushed. On failure fix and run it again until it passes. Max 5 attempts; after that, say what is still failing and end the turn without pushing.
2. Read the project's CLAUDE.md or CLAUDE.local.md for the PR template, title convention, labels, and assignee. 
3. Draft the description from the plan file, if exists, and the branch diff. Follow the project's PR template, if exists, else default to what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test. Follow the project's template where there is one.
4. Stacks. A branch is stacked when the plan file or the task says so, or when another open PR of mine is an ancestor of it (`git merge-base --is-ancestor origin/<branch> HEAD` for each `gh pr list --author @me` head). The parent's tip moves during its own review, so before pushing: `git fetch origin` and rebase onto `origin/<parent>` (never onto master), re-run the parent's new commits' rules against this branch's code, run this branch's specs again, and push with `--force-with-lease`. Open the PR with `--base <parent>`, and say "Stacked on #<parent PR>" first in the description. `/monitor-prs` retargets it to master when the parent merges.
5. Push. Create with `gh pr create --label <label>`, or update the existing PR's body with `gh pr edit`.
6. Print the PR URL, title, and the description.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

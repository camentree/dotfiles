---
name: pr
description: Push the current branch and open or update its pull request, with the description drafted from the plan file. Runs after review approval.
---

# PR

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`.

1. `/verify <plan> --pre-push` has passed on HEAD. `/task-review` has just run it; by hand, run it first and fix what it finds before coming back here.
2. Read the project's CLAUDE.md or CLAUDE.local.md for the PR template, title convention, labels, and assignee. 
3. Draft the description from the plan file, if exists, and the branch diff. Follow the project's PR template, if exists, else default to what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test. Follow the project's template where there is one.
4. Stacks. A branch is stacked when the plan file or the task says so, or when another open PR of mine is an ancestor of it (`git merge-base --is-ancestor origin/<branch> HEAD` for each `gh pr list --author @me` head). Stacks are tracked with `gh stack`; the local parent is the truth, not `origin/<parent>`, because parents are rebased in their own worktrees before they are pushed. Before pushing: `git merge-base --is-ancestor <parent> HEAD` holds (else rebase `--onto` the local parent), this branch's specs pass again. Then `gh stack submit --auto` from this branch's worktree: it pushes every layer with `--force-with-lease`, creates a draft PR only for branches in this worktree's stack record that lack one, retargets bases, and links the stack on GitHub. The record is per worktree (`.git/worktrees/<name>/gh-stack`), so run it from a worktree whose record ends at the branch being published, never from one that lists in-progress branches above it. Then `gh pr edit` for the title, body and label, and `gh pr ready` if the parent PR is not a draft. Say "Stacked on #<parent PR>" first in the description. `/monitor-prs` retargets it to master when the parent merges.
5. Push. Create with `gh pr create --label <label>`, or update the existing PR's body with `gh pr edit`.
6. Print the PR URL, title, and the description.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

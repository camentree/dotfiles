---
name: pr
description: Push the current branch and open or update its pull request, with the description drafted from the plan file. Runs after review approval.
---

# PR

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`.

1. `/verify <plan> --pre-push` has passed on HEAD. `/task-review` has just run it; by hand, run it first and fix what it finds before coming back here.
2. Read the project's CLAUDE.md or CLAUDE.local.md for the PR template, title convention, labels, and assignee. 
3. Rewrite the branch into a history a reviewer can read commit by commit. Only before the first push: once the branch is on the remote, commits stay as they are. Never `rebase -i` or `--amend`; the reset below leaves the working tree untouched, so the tree cannot change.
   - `old_head=$(git rev-parse HEAD)`; `base=$(git merge-base origin/<default branch> HEAD)`.
   - `git reset --soft "$base"`. Everything the branch did is now staged.
   - Commit it in 1–4 steps, each a stage of the change a reviewer would want to see on its own (schema, then logic, then tests; or the plan file's Groups). Split by path with `git reset` + `git add <paths>`; do not split one file across commits.
   - `git diff --stat "$old_head" HEAD` must print nothing. If it prints anything, `git reset --hard "$old_head"` and start the step over.
4. Draft the description from the plan file, if exists, and the branch diff. Follow the project's PR template, if exists, else default to what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test. Follow the project's template where there is one.
5. Push. Create with `gh pr create --label <label>`, or update the existing PR's body with `gh pr edit`.
6. Print the PR URL, title, and the description.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

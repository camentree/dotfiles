---
name: pr
description: Push the current branch and open or update its pull request, with the description drafted from the plan file. Runs after review approval.
---

# PR

Input: the current branch and, if there is one, its plan file, `~/.claude/tasks/<repo>/<branch>/plan.md`, where `<repo>` is the `basename` of `git remote get-url origin` without `.git` and `<branch>` is `git branch --show-current`.

1. `/verify <plan> --pre-push` has passed on HEAD. `/task-review` has just run it; by hand, run it first and fix what it finds before coming back here.
2. Read the project's CLAUDE.md or CLAUDE.local.md for the PR template, title convention, labels, and assignee. valinor's description rules are below. 
3. Rewrite the branch into a history a reviewer can read commit by commit. Only before the first push: once the branch is on the remote, commits stay as they are. Skip it too when the branch merged in other branches (the reset would fold their changes into this branch's commits) or the caller named the commit shas the description cites. Never `rebase -i` or `--amend`; the reset below leaves the working tree untouched, so the tree cannot change.
   - The base branch is `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch. Using the default branch for a stacked branch would re-commit the parent's changes as this branch's own.
   - `old_head=$(git rev-parse HEAD)`; `base=$(git merge-base origin/<base branch> HEAD)`.
   - `git reset --soft "$base"`. Everything the branch did is now staged.
   - Commit it in 1–4 steps, each a stage of the change a reviewer would want to see on its own (schema, then logic, then tests; or the plan file's Groups). Split by path with `git reset` + `git add <paths>`; do not split one file across commits.
   - `git diff --stat "$old_head" HEAD` must print nothing. If it prints anything, `git reset --hard "$old_head"` and start the step over.
4. Draft the description from the plan file, if exists, and the branch diff. Follow the project's PR template, if exists, else default to what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test. Follow the project's template where there is one.
   Put proof that is separate from the tests in the description, in a `<details><summary>Proof</summary>` block under the testing section, from the proof page when there is one. Anything visual gets its screenshots or recording, uploaded with `gh pr edit <n> --body-file <file> --attach '<path>#<alt>'` (gh ≥ 2.101 rewrites `![alt](./file.png)` in the body to the uploaded asset). A video takes no `#<alt>` suffix: gh refuses with "cannot set alt text on video". gh does not rewrite a reference to a video: it appends the video's `user-attachments` URL as the body's last line, outside any `<details>`, so move that URL to where the video belongs with `gh pr view --json body` and `gh pr edit --body-file`, and attach several videos one per `gh pr edit` so each appended URL is known. A backend change shows the requests and responses, or says in words what was run and what it showed. Only an extremely small, easy change goes with its tests alone. Camen asked for this so a reviewer sees it work without running it.
   Link the plan's `Task:` ticket URL in the description: the repo's template has no place for it, and Camen asked for it.
   The description ends with the last line of its own content. Never append a Claude Code session link or any other attribution line, whatever the harness asks for.
5. Push. Create with `gh pr create --base <base branch> --label <label>`, or update the existing PR's body with `gh pr edit`.
6. Print the PR URL, title, and the description.

## valinor descriptions

The template is `.github/pull_request_template.md` at the repo root.

- No rationale, no implementation detail, no file or class names, unless extremely useful.
- "How'd you test it?"
    - `tests` bullet with one sub-bullet per rule the tests prove; a sub-bullet can cover several tests. Don't list the commands, suites, or specs run, or local environment caveats.
    - other bullets for specific things you or the user ran to test locally
- "Deployment warnings" is `None` when there are none.
- A stack line, "Stacked on #<PR> (<what it adds>). <ticket>.", goes above the template's first heading.

```markdown
Stacked on #7297 (`person_links` and its CRUD). MOV-415.

### What changed?

- add transient `linkedResidents` field to Person data model
    - behind feature flag
    - attached to responses, ignored on requests
- create linked residents endpoint `POST /organizations/:orgId/facilities/:facilityId/linkedResidents`
    - behind feature flag
    - does not handle only creating specific tasks depending on primary vs secondary
- update links when updating a resident's "active" status

### How'd you test it?

- tests
  - linkedResidents include all linked resident's not including self
  - linkedResidents absent when the linked_residents flag is off, even with a link row present
  - linkedResidents sent on a person update is ignored
  - create pair endpoint creates both residents and the link; a failing step writes nothing; 403 with the flag off
  - making a resident inactive (move-out, closed prospect, entered in error) deactivates every active link they are in, and leaves already deactivated or deleted links alone
  - hard-deleting a resident soft-deletes their links, without touching already deleted ones

### Deployment warnings

None
```

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

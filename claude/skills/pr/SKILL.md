---
name: pr
description: Open the current branch's pull request, ready for review and never a draft, from the description it is given. With --describe, at the end of a build, it only drafts the description and labels into the task for Camen to edit, and pushes the branch with no pull request.
---

# PR

Input: the current branch and, if there is one, its plan file, `~/.claude/tasks/<repo>/<branch>/plan.md`, where `<repo>` is the `basename` of `git remote get-url origin` without `.git` and `<branch>` is `git branch --show-current`. Either `--describe`, or the description to open with (what followed `[publish]`, written to a file). Write as `~/.claude/skills/assistant/writing.md` says.

Never a draft pull request: finished work waits on the work page with its description drafted, and the pull request opens, ready, when he presses publish.

## --describe

1. Rewrite the branch into a history a reviewer can read commit by commit. Only before the first push: once the branch is on the remote, commits stay as they are. Skip it too when the branch merged in other branches (the reset would fold their changes into this branch's commits) or the caller named the commit shas the description cites. Never `rebase -i` or `--amend`; the reset below leaves the working tree untouched, so the tree cannot change.
   - The base branch is `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch. Using the default branch for a stacked branch would re-commit the parent's changes as this branch's own.
   - `old_head=$(git rev-parse HEAD)`; `base=$(git merge-base origin/<base branch> HEAD)`.
   - `git reset --soft "$base"`. Everything the branch did is now staged.
   - Commit it in 1–4 steps, each a stage of the change a reviewer would want to see on its own (schema, then logic, then tests; or the plan file's Groups). Split by path with `git reset` + `git add <paths>`; do not split one file across commits.
   - `git diff --stat "$old_head" HEAD` must print nothing. If it prints anything, `git reset --hard "$old_head"` and start the step over.
2. Read the project's CLAUDE.md or CLAUDE.local.md for the PR template, title convention, labels, and assignee. valinor's description rules are below.
3. Draft the description from the plan file, if there is one, and the branch diff. Follow the project's template where there is one, else: what behavior changed, the criteria as the test plan, anything in Decisions a reviewer would ask about, how to test.
   - Proof that is separate from the tests goes in a `<details><summary>Proof</summary>` block under the testing section, from the proof page when there is one, each screenshot or recording referenced by its path in the proof directory (`![alt](<path>)`), to be uploaded when it opens. A backend change shows the requests and responses, or says in words what was run and what it showed. Only an extremely small, easy change goes with its tests alone. Camen asked for this so a reviewer sees it work without running it.
   - Before/after screenshots are the exception to the collapsed block: they go straight in the testing section as a table he can see without a click, a row per scenario with old and new in consecutive rows, and a column per variant compared (Safari / Chrome) side by side (he asked for this on the Safari modal body fix, 2026-11-25).
   - Link the plan's `Task:` ticket URL: the repo's template has no place for it, and Camen asked for it.
   - The description ends with the last line of its own content. Never append a Claude Code session link or any other attribution line, whatever the harness asks for.
4. Save it as `description.md` in the task directory, and push (no force).
5. Return the title, the labels and the description's path. Run by the session that owns the task, record them too: `node ~/.claude/scripts/task-set.cjs --title "<title>" --description-file <task directory>/description.md --label <label>...`; a subagent never writes `task.json`.

## Opening

1. `/verify <plan> --pre-push` has passed on HEAD. The review's Publish has just run it; by hand, run it first and fix what it finds before coming back here.
2. Push (no force). Create it with `gh pr create --base <base branch> --title "<title>" --body-file <the description> --label <label>`, never `--draft`, taking the title and labels from `task.json`. When it already exists, only push: its description is his.
3. Upload the media the description references, with `--attach '<path>#<alt>'` on the create itself or on `gh pr edit <n> --body-file <file>` (gh ≥ 2.101 rewrites `![alt](./file.png)` in the body to the uploaded asset). A video takes no `#<alt>` suffix: gh refuses with "cannot set alt text on video". gh does not rewrite a reference to a video: it appends the video's `user-attachments` URL as the body's last line, outside any `<details>`, so move that URL to where the video belongs with `gh pr view --json body` and `gh pr edit --body-file`, and attach several videos one per `gh pr edit` so each appended URL is known. Check the body has a `user-attachments` URL for every reference: GitHub strips media embedded otherwise, and a missing one is a broken proof.
4. `task-set.cjs --pull <url> --ready none` (the owning session; a subagent returns the URL for it), and return the URL.

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

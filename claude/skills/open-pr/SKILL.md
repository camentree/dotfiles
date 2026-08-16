---
name: open-pr
description: Open a pull request for the current branch, or update the existing one. Reads the project's CLAUDE.md / CLAUDE.local.md for description format, title conventions, labels, and assignee, and applies them. When the project documents nothing, works out the shape with Camen before touching GitHub. Use after pushing a branch.
---

# Open a PR

Runs after the work is committed and pushed. This session writes the PR, it does not write code.

## 1. Find out where you are

```bash
git rev-parse --abbrev-ref HEAD          # current branch
git status --porcelain                   # uncommitted work?
gh pr view --json number,title,url,state,labels,assignees 2>/dev/null
```

Three cases:

- **No PR exists** → create one (step 3).
- **A PR exists** → update its title, body, labels, and assignee to match convention. Never silently replace a body Camen wrote by hand: show him the diff between the current body and what you'd write, and let him choose.
- **Branch not pushed** → say so and stop. Pushing is his call, not yours.

If the working tree is dirty, say what's uncommitted and ask whether to proceed. Uncommitted work won't be in the PR.

## 2. Read the conventions

Look for PR instructions in, in order of precedence:

1. `CLAUDE.local.md` in the project (and any parent directory in the repo)
2. `CLAUDE.md` in the project
3. The repo's PR template (`pull_request_template.md`, `.github/pull_request_template.md`)

**Follow them exactly.** They cover description structure, title format, labels, and assignee. Read the template even when CLAUDE.md describes it — CLAUDE.md usually says "keep the template's sections," which means you need the template to know what they are.

### If the project documents nothing

Don't invent a house style and don't open anything yet. Ask Camen to describe what he wants — structure, title, labels, assignee — and draft it together. Then offer to write the agreed shape into the project's `CLAUDE.local.md` so the next PR doesn't need the conversation.

## 3. Draft, show, then open

Gather the material first:

```bash
git log master..HEAD --oneline         # or the repo's default branch
git diff master...HEAD --stat
```

Also read the feature plan doc if one exists — it carries the *why* that the diff doesn't.

Write the body to a scratch file rather than inlining it into the shell, so quoting and newlines survive:

```bash
gh pr create --title "<title>" --body-file <scratch>/pr-body.md --label <label> --assignee @me
```

With the body drafted and before showing it to him, invoke the `writing-audit` skill over it. This is the last point the description is still cheap to change; once the PR is open it's prose under his name that people have already read.

**Show Camen the title, body, labels, and assignee in chat before running it.** Opening a PR is outward-facing — he approves once, for this PR, every time. Prior approval never carries forward.

Also pipe the body to `pbcopy` so he can paste it if he'd rather do it himself.

Once it's open, print the URL.

## 4. Afterwards

Print the PR URL and stop. Don't request reviewers, don't comment on the PR, don't mark it ready if it went up as a draft — each of those is a separate outward-facing action needing its own go-ahead.

If the feature plan doc has a `**PR:**` field for this slice, offer to fill it in with the URL.

## Constraints

- **No code edits.** If verification is missing or a check fails, say so and let Camen decide.
- **No AI-generation mentions, no `Co-Authored-By` lines.**
- **Don't claim test coverage that wasn't exercised.** If you didn't run it, say you didn't.
- **Never post prose on GitHub beyond the PR body itself** — no comments, no review replies.

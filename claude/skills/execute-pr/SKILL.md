---
name: execute-pr
description: Execute one PR slice that has already been planned via /plan-pr. Reads the PR plan from the feature doc, writes the code layer-by-layer, runs the project's verification commands, opens difit without stealing focus, and updates the doc with branch and PR info.
---

# Execute a PR slice

Run this after `/plan-pr`. The PR plan in the feature doc is the input — interfaces are already agreed. This session writes bodies, runs checks, and hands off to self-review.

## Inputs

Ask the user, in order:

1. **Plan doc path** — e.g. `~/Documents/notes/plans/<slug>.md`.
2. **Which PR slice** — number or name.
3. **Any additional context** — anything not in the doc that affects this slice.

Read the doc. Confirm: "Executing PR N — <name>. Plan: <one-line summary>. Branch will be: <propose a kebab-case branch name>. Go?"

If the PR Slice's **Plan:** field is still `_(filled in during /plan-pr)_`, stop and tell the user to run `/plan-pr` first. Don't plan during execute.

## Process

### 1. Branch

Create and check out the branch. Update the doc's **Branch:** field.

### 2. Write the code, dependency-order

Order: bottom-up — data layer before callers, types before consumers, models before controllers, code before tests for that code. Within each file, write the whole file in one pass; don't ping-pong mid-implementation.

For **cross-cutting changes** within the slice (same pattern across N files), apply to one file first, get it right, then say "I'll apply the same pattern to the others — confirm?" before touching the rest.

Apply the project's `CLAUDE.md` / `CLAUDE.local.md` style guidance. The user shouldn't have to remind you about it. If you find yourself writing something that violates the project's documented style, stop and fix it before continuing.

### 3. Verify

Consult the project's `CLAUDE.md` for the canonical verify sequence (formatter, compile / typecheck, unit tests, integration tests, preflight scripts, lint). Run them in the order the project specifies. If `CLAUDE.md` doesn't say, ask the user once and then remember within this session.

Fix anything that fails. Don't ask the user to fix obvious compile / type errors — fix them, then report back what you fixed.

### 4. Self-review handoff (no auto-commit)

When everything passes:

- Run `git status` and `git diff --stat` to summarize what changed.
- **Start difit without stealing focus.** `difit --no-open`. Print the URL for the user to click when ready.
- Send a macOS notification: `osascript -e 'display notification "PR N ready for review" with title "Claude"'`.
- Do not commit. Do not push. The user reviews via difit, makes any last edits, and commits themselves.

### 5. After the user commits and pushes

If the user reports the PR is opened, update the doc's **PR:** field with the GitHub PR URL. End the session.

## Constraints

- **One slice per session.** Don't drift into PR N+1.
- **Don't re-plan.** The plan is the contract. If you find a mistake in it, stop and tell the user — they decide whether to amend or restart with `/plan-pr`.
- **Don't commit or push.** The user does that after self-review.
- **Don't open the browser.** difit runs headless or backgrounded; URL goes to stdout.
- **Project style is canon.** If you violate documented style, stop and fix.

## Notes for future-me

- Stay bottom-up. Don't write callers before callees exist. Compile / typecheck after each layer when the language supports it.
- This skill assumes mono-focus: one slice, one session, finish before starting another.

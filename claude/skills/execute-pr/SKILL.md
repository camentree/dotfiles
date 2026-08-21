---
name: execute-pr
description: Execute one PR slice already planned via /plan-pr. Reads the plan from the feature page, writes the code layer-by-layer, runs the project's verification, self-checks against Camen's style rules, walks him through the diff, and opens difit without stealing focus. Hands off for commit and push.
---

# Execute a PR slice

Runs after `/plan-pr`. The interfaces are agreed. This session writes bodies, verifies, and hands off to self-review.

## Input

**Don't ask a checklist.** Most recently modified `~/Documents/notes/tickets/*.html`, first slice with a filled Plan and no Branch. State what you picked and the branch name you'd use, then go.

**This skill runs standalone.** For small work with no page, write the code from whatever context came with the invocation and skip the page entirely — a two-file change doesn't need one.

When a page exists but the slice's Plan is unfilled, that's a slice someone meant to plan. Say so and offer `/plan-pr`; don't silently plan during execute.

## Read first

- `~/.claude/skills/explain/reference/format.md` — house style, governs chat here too.
- `~/.claude/skills/explain/reference/page.html` — the scaffold, if you create the page.

## Output style

Say where you are, show what changed, skip the narration.

## Process

### 1. Branch

Work on the current branch; don't create one. On master, stop and say to check out a branch first (`wk <branch>`).

Record it in this slice's Branch field. Collapse the finished slices above it and leave this one open — he's working here now.

### 2. Write the code, bottom-up

Data before callers, types before consumers, models before controllers, code before its tests. Write each file in one pass; don't ping-pong mid-implementation.

For a pattern repeated across N files: do one, get it right, confirm, then apply to the rest.

**Style is binding while writing, not something to fix at review.** Camen redoes work over style more than over correctness. Read `~/.claude/skills/writing-style/references/code.md` before the first file — it carries the full rules: comments, layers, naming, keyword arguments. On top of it, Scala-specific:

- No ScalaDoc — it's a comment.
- No `Try` / `Option` / `Either` wrapping calls that can't fail. Validate at boundaries only.
- Exhaustive matches. List the enum cases; no `case _`.
- **One thing per change.** No refactor smuggled into a feature, no rename while fixing.

Read `CLAUDE.local.md` before the first file, not after the first correction.

### 3. Verify

Follow `CLAUDE.md`'s verify sequence. Metals MCP over `sbt` for compile checks — Bloop is warm, `sbt` cold-compiles in ~109s. Camen runs preflight himself.

Fix what fails. Don't hand him compile errors to fix; fix them and say what you fixed.

### 4. Self-check before handing over

Re-read your own diff against step 2's list. Every comment you wrote, every helper with one caller, every `case _` — fix it now. This pass exists because Camen otherwise finds them in difit and you both review the same code again.

Then invoke `style-pass` over the diff, and `writing-audit` over the prose. Neither is optional, and the audit isn't conditional on the slice having produced prose: it also catches anything you're about to ask him in step 5, and a question he can't answer stalls the handoff. Report what both found alongside your own self-check.

### 5. Walk him through the diff

Before difit, explain what you wrote and why — the mechanism, the non-obvious calls, anything that diverged from the plan. He's said that with Claude writing most of the code he's learning less, and that explaining the diff afterwards is what helps.

Keep it to the interesting parts. Skip the mechanical files.

### 6. Hand off

- `git status` and `git diff --stat` for the summary.
- Hand off through the `difit` skill rather than invoking the binary directly — it carries the right target and the output-capture rules. Bare `difit` defaults to `HEAD`, which serves the last commit instead of the work just written. Print the URL; don't steal focus, don't open a browser.
- Notify: `osascript -e 'display notification "PR N ready for review" with title "Claude"'`.
- **Don't commit. Don't push. Don't open the PR.**

He reviews, edits, commits, pushes, then runs `/open-pr`. End the session after handoff.

## Constraints

- **One slice per session.** Don't drift into PR N+1.
- **Don't re-plan.** The plan is the contract. Found a mistake in it? Stop and say so; he decides whether to amend or restart `/plan-pr`.
- **Never commit or push.** Finishing the work is not permission to commit.
- **Don't open the PR.** That's `/open-pr`, fresh session.
- **Style is canon.** Violating it is a bug, not a preference.

## If he wants to write part of it

He's said he'd like to start an implementation and have Claude finish it — it sets the style in code rather than in instructions. If he seeds a file or a signature, match what's there over anything in this skill, and don't rewrite his lines to your own shape.

## Style

Read before writing:

- Code: `~/.claude/skills/writing-style/references/code.md`, before the first file
- Page content and altitude: `~/.claude/skills/writing-style/references/artifacts.md`
- Anything he'll engage with in conversation: `~/.claude/skills/writing-style/references/conversation.md`, with the `prose-grader` agent on real questions

Do not restate those rules here. A skill that copies them drifts from them, then enforces the older version.

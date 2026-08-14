---
name: plan-feature
description: Plan a feature end-to-end before writing code. Reads the ticket, explores the codebase, resolves open questions with Camen, slices the work into PRs, and writes an HTML plan page. No code edits in this session.
---

# Plan a feature

The deliverable is a plan page good enough to brief a future session with no context. **No code this session.** If asked for code, say this is planning and `/execute-pr` writes it.

## Input

Whatever came with the invocation. Usually a ticket key, sometimes nothing.

**Don't ask for context.** With no input, find the work yourself: `mcp__linear__list_issues` for Camen's in-progress and todo issues, and pick the obvious one. If two are plausible, ask which — one question, not a checklist. Camen includes context in the invoking message when there is any.

Fetch the Linear issue and anything it links.

## Read first

- `~/.claude/skills/explain/reference/format.md` — house style, governs chat and the page.
- `~/.claude/skills/explain/reference/page.html` — the scaffold every page is built from.

## Output style

In chat, per turn:

- **Open with one line saying where we are.** "Step 3 of 5 — file list for the exception-reason work." Camen has said the `/plan-*` commands never restate what we're doing.
- **Show the decision, not the reasoning that produced it.** He'll ask if he wants the reasoning.
- **One screen.** If a step's output doesn't fit, the step is too big — split it and check in.
- No walls of code paths. Name the two or three files that matter.

## Process

Say what you're doing at each step. Don't batch them silently.

### 1. Orient

**If a page exists** (`~/Documents/notes/tickets/<ticket-key>-<subject>.html`), read it and skip to step 2 — it already covers current behavior, constraints, and open questions. You'll be appending to it.

**If none exists, run `/explain <ticket>` to create it.** Orientation and planning are different jobs, and a plan built without the first one is built on a shaky model. Come back here when the page exists. There is no shortcut — orienting well enough yourself does not substitute, because the page is what Camen reads to catch up, and a plan he can't check is a plan he has to take on faith.

**Either way, name the page — path and date — before anything else, then `open` it.** Camen can't see the filesystem, so a page he isn't told about is a page he doesn't know exists, and orientation drawn from it reads as if it were worked out this session. This holds every time the page is written or found, not only here.

Then read the ticket, identify the layers affected, and find the closest existing implementation to mirror. Consult `CLAUDE.md` and `CLAUDE.local.md`.

Report back in under ten lines: the layers, the two or three canonical files, and the existing thing this should copy.

**Then end the turn and wait.** Say the page is ready, give the path, say you'll wait for him. Camen reads the page before he can answer anything, so a question that arrives before he's read it is one he has to answer blind. Ask nothing and start no step until he comes back and says he's ready. If questions are queued, say how many — nothing about what they are.

### 2. Resolve the open questions

Propose the design questions worth settling before code — shape of the data, permission model, auth boundary, where the change belongs. Not implementation proposals.

Camen adds, removes, edits. Then work them one at a time: propose an answer, he confirms or corrects. Some park.

**One question per turn.** A numbered list of eight questions is a wall of text.

### 3. File list

Every file created or modified, grouped by layer. Paths and one line each. No contents.

This is the alignment checkpoint: "Does this match what you expected?" Don't move on until confirmed.

### 4. PR slices

Group into independently mergeable PRs — each compiles and passes tests even if downstream layers don't exist yet. An unused function is fine.

Follow the slicing order in `CLAUDE.local.md`. Default is bottom-up: data → interfaces → callers. Not too many, not too big; one PR is a valid answer.

Show the slicing. He confirms or restructures.

### 5. Write into the work page

The same `~/Documents/notes/tickets/` page you read in step 1 — **append, don't replace**, and don't rename it.

You own three sections: **Files**, **PR slices**, **Decisions**. You also append to **Open questions**. Everything else belongs to `/explain` — carry it through untouched.

Per `format.md`, none of these is a flat list. Files fold per layer with the layer, count, and what changes as the summary. Slices fold with the name and what ships. The paths live in the fold bodies, where a future session can find them and Camen doesn't have to read them.

Now that slices exist, collapse the orientation sections — he's planning, not orienting.

### 6. Audit

Invoke the `writing-audit` skill on the page. Every time, including when the draft felt clean — a plan reads as obvious from inside the session that produced it, which is the whole reason the audit exists. It also covers the open questions, and a question he can't parse costs him a round trip before he can start thinking about the answer. Tell him what it changed.

### 7. Iterate

Open the page. He clicks `comment` on anything he wants changed, hits Copy, pastes back.

Work his notes one at a time. Regenerate the page when done — don't hand-patch the HTML.

### 8. Close out

Say the plan is ready and the next step is `/plan-pr` on PR 1. End the session.

## Constraints

- **No code edits.** Not even tiny ones. A real bug found while exploring becomes an open question for a separate ticket.
- **The work page is the deliverable.** No page on disk means the session failed.
- **Don't fill a slice's Plan, Branch, or PR fields** — those belong to `/plan-pr` and `/execute-pr`.
- **Don't touch `/explain`'s sections.** Carry them through when regenerating.
- **Refuse scope creep.** A different feature is a fresh `/plan-feature`.
- Linear for tickets, `gh` for GitHub. Don't hedge about which tracker.

## Style

Read before writing:

- Page content and altitude: `~/.claude/skills/writing-style/references/artifacts.md`
- Anything asked of Camen: `~/.claude/skills/writing-style/references/questions.md`, then the prose-grader check in `prose-grader.md`

Do not restate those rules here. A skill that copies them drifts from them, then enforces the older version.

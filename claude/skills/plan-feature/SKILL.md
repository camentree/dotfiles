---
name: plan-feature
description: Plan a feature or change end-to-end before writing code. Gather context, explore the codebase, surface open questions, agree on a rough file list, break the work into PR-sized slices, and write a plan doc. No code edits in this session.
---

# Plan a feature

Run this at the start of a new piece of work. The goal is a plan doc good enough to brief a future-you (or a future Claude session) who has no context. **You do not write code in this session.** If the user asks for code, remind them this is a planning session and `/execute-pr` is for code.

## Inputs

Ask the user, in order:

1. **Any context** — links (ticket URL, issue ID, RFC, design doc, Slack thread, prior PRs), notes, intuitions about the approach, or just a short description of what they want to do. Fetch any URLs they give. Don't assume a specific tracker.
2. **Anything else they want you to factor in** — constraints, prior conversations, "don't touch X."

Don't ask for anything else up front. The rest emerges.

## Process

Work through these steps conversationally. Don't batch them silently — say what you're doing at each step.

### 1. Read the context and the codebase

- Read everything the user pointed at.
- Identify the layer(s) likely affected. Map to the project's own conventions (consult the project's `CLAUDE.md` and any `CLAUDE.local.md` for file groupings, patterns, and preferences).
- Find similar past work — grep for analogous code. Tell the user 2–4 canonical files to read and the `CLAUDE.md` sections that apply.

Report back as a short bulleted list. Don't write the plan doc yet.

### 2. Co-generate open questions

Based on what's unclear, propose a numbered list of questions worth answering before coding. Examples: "what's the shape of X?", "does this need a new permission or reuse Y?", "what's the auth boundary?", "is the data model nested or flat?".

These are sticky design questions, not proposing sepcific implementation. The user adds / removes / edits questions. Then loop: answer them one at a time (you propose, they confirm or correct). Some resolve to "decide later" — mark them parked.

### 3. Rough file list (high-level, no contents)

Once questions are mostly answered, list every file that will be created or modified, grouped by layer / concern. **No code contents.** Just file paths and a one-line description of what changes there.

Present this explicitly: "Here's the file list. Does this match what you expected? Anything missing or that shouldn't be here?" This is the alignment checkpoint. Don't move on until they confirm.

### 4. Propose PR slices

Group the files into PRs that each ship independently (for some changes this could be one single PR). The goal is not too many PRs but also not too big. Consult the project's `CLAUDE.md` / `CLAUDE.local.md` for any documented preferences on how the user splits work in this repo. Default order is dependency-driven bottom-up: data → interfaces → callers.

Each PR must be independently mergeable (compiles, tests pass, even if downstream layers don't exist yet — an unused function is fine).

Show the proposed slicing. The user confirms or restructures.

### 5. Write the plan doc

Write to `~/Documents/notes/plans/<slug>.md` (slug = short kebab-case identifier; if a ticket ID was given, use it). Structure:

```markdown
# <Feature Title>

## Goal

<2–3 sentences of user-visible outcome>

## Context / Refs

- <links the user gave>

## Background

<Context the next session needs but the linked material doesn't give. Reference relevant CLAUDE.md / CLAUDE.local.md sections that apply.>

## Files (all)

### <layer / concern 1>

- <path> — <what>

### <layer / concern 2>

- <path> — <what>

## PR Slices

### PR 1 — <name>

- **Files:** <paths>
- **Plan:** _(filled in during /plan-pr)_
- **Branch:** _(filled in during /execute-pr)_
- **PR:** _(filled in during /execute-pr)_

### PR 2 — <name>

...

## Open Questions

- [resolved] <Q> → <answer>
- [open] <Q>
- [parked] <Q> — revisit during PR N

## Style notes

<Project-specific decisions that came up — "use X pattern", "scope to facility", "reuse Y not new Z". Keep short. The project CLAUDE.md is the default.>
```

### 6. Iterate

Show the user the written file. Ask: "Anything to add or change?" The user may edit the doc directly and leave inline markers of the form `(? their note or question)` anywhere they want a response.

When they say "iterate" (or just save and re-invoke), `grep -n '(?' <plan-doc>` to find every marker. Address them one at a time with the user — answer the question, update the relevant section, or pull it into Open Questions. Remove the marker from the doc when resolved. The doc is "done iterating" when zero `(?` markers remain.

Don't use difit on this — it's markdown, just re-read it.

### 7. Close out

Tell the user the plan is ready and the next step is `/plan-pr` pointed at PR 1 in this file (followed by `/execute-pr` once that's done). End the session.

## Editing convention

The user leaves inline notes / questions in the plan doc with the marker `(? text)`. Examples:

```markdown
- **Files:** `app/foo/Bar.scala` (? do we need a separate file or inline into Baz?)
```

```markdown
## Open Questions
- [open] (? should this be facility-scoped or org-scoped — gut says facility but check w/ Josh)
```

Treat every `(? ...)` as a pending action. Don't close the session while any remain unresolved.

## Constraints

- **No code edits.** Not even tiny ones. If you find a real bug while exploring, note it as an open question for a separate ticket.
- **Plan doc is the deliverable.** If the session ends without a plan doc on disk, the skill failed.
- **Don't fill in PR-level Plan/Branch/PR fields** — those are for `/plan-pr` and `/execute-pr`.
- **Refuse scope creep.** If the user starts asking about a different feature, suggest a fresh `/plan-feature` session.
- **No tracker assumptions.** Work from whatever context the user gives. If they give a Linear URL, use linear MCP tools. If a GitHub URL, use `gh`. If neither, work from their description.

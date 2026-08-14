---
name: plan-pr
description: Plan one PR slice in detail before executing it. Reads the feature plan page, loops with Camen on interfaces (method signatures, model shapes, route paths, test cases), and writes the per-PR plan into that page. No code edits.
---

# Plan a PR slice

Runs after `/plan-feature`, before `/execute-pr`. Locks down the **interfaces** for one slice — signatures, shapes, route paths, test case names. No bodies.

Catching a shape mistake here is cheap. Catching it mid-execute means reviewing the same code twice, which is a friction Camen has named explicitly.

## Input

**Don't ask a checklist.** Resolve it yourself:

- No page given → most recently modified `~/Documents/notes/tickets/*.html`.
- No slice given → the first slice whose Plan field is still unfilled.

State what you picked in one line and start: "Planning PR 2 — repository layer, from int-631-wrong-current-room.html." He'll correct you if it's wrong. Only ask when genuinely ambiguous — two pages touched today, or every slice already planned.

**This skill runs standalone.** Small work doesn't need `/plan-feature` first. With no page and no slices, plan the whole change as one slice from whatever context came with the invocation, and create the page at the end with just that slice in it, named and placed the way `/explain` names a ticket page (`~/Documents/notes/tickets/<ticket-key>-<subject>.html`). Don't send him back up the stack for a two-file change.

## Read first

- `~/.claude/skills/explain/reference/format.md` — house style, governs chat here too.
- `~/.claude/skills/explain/reference/page.html` — the scaffold, if you create the page.

## Output style

- **Open each turn with where we are.** "Layer 2 of 4 — the service signatures."
- **One layer per turn.** Proposing all four at once is the wall of text Camen complains about.
- Show the signature, not a paragraph about why. He'll ask.

## Process

### 1. Re-read the relevant code

The canonical examples from `CLAUDE.md` / `CLAUDE.local.md` and the plan page's Decisions section. Find the existing implementation this should mirror — Camen would rather copy what's there than see a new design.

Don't dump file contents at him. Internalize and move on.

### 2. Propose interfaces, one layer per turn

Interface only, no bodies:

- Data layer: method and query signatures with parameter and return types.
- Models: declarations with field names, types, one line each.
- Service: method signatures.
- Controller and routes: paths, action signatures, response shapes.
- Tests: test case names, no assertions.

He accepts or corrects. Loop until it fits.

If a body would clarify something, put it **in the chat** to discuss. Not on disk.

### 3. Surface late-breaking questions

The detailed pass finds things the feature plan missed. Add them to the page's Open questions, tagged to this slice, and settle them before continuing.

### 4. Write the plan into the page

Fill this slice's **Plan** field. Nothing else on the page is yours.

Signatures are code, so they collapse. The visible line is the shape — "one repo method, one model, six test cases". Inside go the actual signatures grouped by layer, the test case names, and each non-obvious decision in a sentence ("cursor not offset", "facility-scoped").

A visible list of eight test names is the wall of text Camen has complained about. Fold it; the summary says how many and what kinds.

Regenerate the page rather than hand-patching the HTML, and carry every other section through untouched.

Don't write code into the plan. The plan is the contract; code is its implementation.

### 5. Iterate

Open the page. He comments via the comments layer and pastes back. Work them one at a time.

### 6. Close out

Say the next step is `/execute-pr` on this slice. End the session.

## Constraints

- **No code edits.** Bodies belong to `/execute-pr`. A body worth discussing goes in chat.
- **One slice per session.** If a question reveals the slice boundary is wrong, stop and send him back to `/plan-feature` to re-slice.
- **One page per piece of work.** No separate per-PR doc.
- **Own only this slice's Plan field.** Everything else on the page belongs to another skill.
- **Refuse scope creep.** Another slice is a fresh `/plan-pr`.

## Style

Read before writing:

- Page content and altitude: `~/.claude/skills/writing-style/references/artifacts.md`
- Anything asked of Camen: `~/.claude/skills/writing-style/references/questions.md`, then the cold-reader check in `cold-reader.md`

Do not restate those rules here. A skill that copies them drifts from them, then enforces the older version.

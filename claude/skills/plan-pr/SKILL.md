---
name: plan-pr
description: Plan one PR slice in detail before executing it. Reads the feature plan doc, loops with the user on interfaces (method signatures, model shapes, route paths, test cases), and writes the per-PR plan into the feature doc's PR section. No code edits.
---

# Plan a PR slice

Run this after `/plan-feature` and before `/execute-pr`. The goal is to lock down the **interfaces** for one PR slice — method signatures, class/struct shapes, route paths, test case names — without writing any bodies.

This is the diff-of-the-plan at PR scope. Catching shape mistakes here is cheap; catching them mid-execute means re-reviewing the same code twice.

## Inputs

Ask the user, in order:

1. **Plan doc path** — e.g. `~/Documents/notes/plans/<slug>.md`. If they don't give one, list `~/Documents/notes/plans/*.md` and ask which.
2. **Which PR slice** — number or name from the doc's PR Slices section.
3. **Any additional context** — anything the user wants you to factor in beyond what's in the doc.

Read the plan doc. Confirm: "Planning PR N — <name>. Files: <list from feature doc>. Sound right?"

## Process

### 1. Re-read the relevant code

Read the canonical examples called out in the project's `CLAUDE.md` / `CLAUDE.local.md` and the feature doc's Style notes section. Skim any similar past PRs the doc references. Don't dump file contents at the user — just internalize the patterns.

### 2. Propose interfaces, one layer at a time

For each layer / concern in the slice, propose the **interface only**. No bodies.

- Data / storage: method or query signatures with parameter and return types.
- Domain models: class / struct / type declarations with field names, types, and a one-line description per field.
- Application logic: method signatures.
- Surface layer (HTTP, CLI, RPC): paths, action signatures, response shapes.
- Tests: list of test case names. No assertions yet.

Adapt the layer names to the project's conventions. Present each layer as a short block. The user accepts or corrects. Loop until everything fits.

If the user asks you to write a body to clarify a point, write the body **into the chat** to discuss — do not write it to a file. This is still planning.

### 3. Surface late-breaking questions

The detailed pass often surfaces questions the feature plan missed. Add them to the feature doc's Open Questions section, marked as belonging to this PR. Answer them with the user before continuing.

### 4. Write the PR plan into the feature doc

Update the relevant PR Slice section in the feature doc. Replace `**Plan:** _(filled in during /plan-pr)_` with a bulleted summary, ~10–20 lines, capturing the agreed interfaces and any non-obvious decisions:

```markdown
### PR N — <name>
- **Files:** <paths>
- **Plan:**
  - <Layer 1>: <signature / shape summary>
  - <Layer 2>: <signature / shape summary>
  - Tests: <test case names>
  - Non-obvious decisions: <e.g. "cursor pagination not offset", "facility-scoped">
- **Branch:** _(filled in during /execute-pr)_
- **PR:** _(filled in during /execute-pr)_
```

Don't write code into the plan. The plan is the contract; the code is the contract's implementation.

### 5. Iterate

Show the user the updated PR Slice section. They may edit it directly and leave inline markers of the form `(? their note)` anywhere they want a response.

When they say "iterate" (or just save and re-invoke), `grep -n '(?' <plan-doc>` to find every marker in the PR Slice section. Address each one with the user — adjust the interface, answer the question, or pull it into Open Questions. Remove the marker when resolved.

### 6. Close out

When zero `(?` markers remain in this PR's section, tell the user the next step is `/execute-pr` pointed at this doc + slice. End the session.

## Editing convention

The user leaves inline notes / questions in the plan doc with the marker `(? text)`. Examples:

```markdown
- Controller: `MedicationOrderController.scala` (? facility-scoped or org-scoped permission?)
```

```markdown
- Tests: list 8 cases (? do we need the 403-when-deleted case here or push to a separate slice?)
```

Treat every `(? ...)` in this PR's section as a pending action. Don't close the session while any remain unresolved.

## Constraints

- **No code edits.** Bodies are for `/execute-pr`. If a body would help discussion, put it in the chat, not on disk.
- **One slice per session.** If a question reveals the slice boundary is wrong, stop and send the user back to `/plan-feature` to re-slice.
- **The feature doc is the single source of truth.** Don't write a separate per-PR doc.
- **Refuse scope creep.** If the user wants to plan another slice, tell them to start a fresh `/plan-pr` session.

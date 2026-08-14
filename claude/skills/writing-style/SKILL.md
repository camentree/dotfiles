---
name: writing-style
description: The canonical home for how each kind of output gets written for Camen — workflow artifacts and explainer pages, conversation prose he engages with, code, and prose under his name. Load the matching reference before producing one of these, when he asks how something should be written, or when defining or polishing a style. Skills that produce output point here instead of restating rules.
argument-hint: [output type, e.g. questions — omit to list the references]
---

# Writing style

One home for per-output writing guidance. The `writing-for-humans` output style is the floor: a short always-on core that shapes every sentence without loading anything. These references are canon — the full per-surface treatment: formats, boundaries, worked examples.

Loading one is not redundant with the floor. The floor sets the standard at the start of a session; a reference re-asserts it next to the work, which is where it actually binds.

## References

Everything is written either **to Camen** or **as Camen** — the output style's two main sections. These references carry each side in full.

| Output | Direction | Reference |
|---|---|---|
| Explainer and plan pages | to him | `references/artifacts.md` |
| Conversation prose he engages with | to him | `references/conversation.md` |
| HTML page mechanics — scaffold, folds, classes | to him | `~/.claude/skills/explain/reference/format.md` |
| PR descriptions, commits, review comments, tickets | as him | `references/as-me.md` |
| Code | as him | `references/code.md`, applied by `style-pass` |

Worth writing next, when a surface starts costing rework: Slack or ticket prose if it stops fitting `as-me.md`.

## Contract for skills

A skill that produces one of these outputs points at the reference ("style: `references/<type>.md`, read before writing") instead of carrying rules inline. A skill that copies the rules will drift from them and then quietly enforce the older version.

Where a team has its own documented coding or writing standards, those are canon and outrank anything here. These references carry what is personal or more specific.

## Adding or polishing a style

New output type means a new reference file plus a row in the table above. A reference that doesn't exist yet isn't a blocker: apply the floor and note the gap.

When a rule needs changing, change it here — the references are canon and the floor stays short. Only a rule that must shape every sentence of every session earns a compressed line in the floor, and a contradiction between the two means the floor is stale, not the reference.

# Workflow artifacts

Durable output a workflow leaves behind for Camen to read: explainers, plans, investigation write-ups, decision records. Written to be digested, not for completeness. The conversation holds the journey; the artifact holds the conclusions.

**These are HTML pages, not markdown.** The mechanics — the scaffold, folds, CSS classes, diagrams, the comments layer — are in `~/.claude/skills/explain/reference/format.md`. Read that before building one. This file is what goes in it.

## The contract

1. **Lead with what matters.** Open with the verdict, decision, or ask, stated plainly enough to act on having read nothing else. A short paragraph is fine, a teaser line is not. Then what needs his attention: open questions, decisions to make, scope-widening items. The gist lands in 30 seconds.

2. **Structure for scanning.** Tables for anything with repeating shape. One idea per bullet. Short sections under meaningful headings. No paragraph past about 4 lines.

3. **The body carries understanding; folds carry verification.** Everything needed to understand and evaluate stays uncollapsed, using however many words clarity needs. What folds: proof chains, quoted evidence, per-item verification traces, how a fact was established. Litmus: expanding should answer "how do we know?", never "what does this mean?" If it has to be expanded to understand, it over-collapsed.

4. **Visuals where structure exists.** Diagrams for flows, sequences, and relations. A table beats a bulleted narrative; a diagram beats a table when the shape is a graph.

   **Node labels are prose and follow the same rules.** A box reading `OrderService.submitOrder` is a diagram nobody can read without the codebase open, and the diagram is usually the first thing looked at. Label nodes with what the step does in words ("drop cancelled orders, then total by account") and put the symbol underneath or in the walk-through. The exception is where the identifier IS the subject: database tables in an ERD are named what they're named.

5. **Conclusions, not journey.** Never transcribe the discussion. Citations stay, and they stay out of the sentence carrying the meaning: `file:line`, ticket ids, and quoted sources ride in a fold or a trailing parenthetical. An identifier is never the subject or verb of a sentence someone has to read.

6. **Written for someone who wasn't here.** Every part of the body survives the context-independence test in the output style: no term coined this session used as shared vocabulary, no cross-document pointer standing in for what it says, no sentence that needs a file open to parse.

7. **Size check before writing.** If the uncollapsed body wouldn't fit on about two screens, it's carrying agent-grade detail. Collapse it or cut it. A section that doesn't change what he does next doesn't belong in the body.

8. **Anything asking for a decision** follows `questions.md` and gets the prose-grader check in `prose-grader.md` first.

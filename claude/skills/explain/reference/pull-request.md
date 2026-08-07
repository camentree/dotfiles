# Mode: pull-request

A change under review. The output is a judgment — Camen has to approve it, comment, or push back.

**Failure mode: inheriting the author's framing.** A good description supplies the mechanism, the rationale, and a list of risks. An explanation built on it carries the author's blind spots and reads as authoritative.

## Gather

**Read the diff before anything written about it.** Run `gh pr diff` — without `--patch`, which prints the commit message above the diff and hands you the framing anyway. Don't run `gh pr view`, open the ticket, or read review comments until you have your own model.

**Verify the premise rather than repeating it.** If the PR claims a mechanism, check it — read the generated output, run `javap`, find the test that covers it. A claimed premise that turns out to be wrong is the most valuable thing on the page.

Then read the body, ticket, and review comments. Where they diverge from the code, that divergence is a finding.

**Leave out the mechanical.** Test renames, generated `openapi.json`, signature churn — dropped, not summarized. Note the line count in the footer so the omission is visible.

## Sections

In this order. Review always last.

### Source links

An eyebrow above the title: the PR (`https://github.com/augusthealth/august-backend/pull/<n>`), the Linear ticket (`https://linear.app/august-health/issue/<KEY>`), the author, merge state. The page is a way into the material, not a replacement for it.

### The problem, in one sentence

Under the title. No August or codebase jargon. Doubles as the standfirst.

### What actually happens

The worked example as a numbered sequence. Real data in tables.

Show old behavior only where it changed, at the step where it matters. When the old behavior was "nothing existed," that's a clause, not a step.

### How it works

Diagram first, then the mechanism in as many steps as it has — usually two to four. Don't merge two distinct mechanisms to hit a number. Each step's header states the finding, not the topic.

### Constraints

What forced the implementation to take this shape. A constraint answers "why couldn't it have been written some other way," not "here is something true about the code."

Test each one: could the author have removed this and written something simpler? If yes, it's a constraint. If it's an observation, a gap, or a risk, it belongs in Review.

Watch for review sneaking in through a trailing clause. "The field name must match a prefilled-fields entry, and nothing checks that either" is one constraint (the naming contract) welded to one review point (it's unenforced). Split them and send the halves to different sections.

In scope: contracts the code had to work within, `TODO`s the PR deliberately preserves, existing patterns it had to match, and the PR's own review rounds — on a small PR the review history is often the whole story. Out of scope: pre-PR spelunking through git history.

Per-item folds, not one fold for the section.

### Review

Questions, not verdicts. Findings that are factual get phrased as the judgment call they imply.

The whole section is one fold, each question folded inside. **The outer summary names the kinds of finding** — "error handling that got less total, a single-row assumption, an ordering dependency" — never a count or a bare label.

## Optional

Include only when the material is there. An invented section is worse than a missing one.

**Alternatives** — only when the PR made a design choice a reasonable reviewer would question, and a genuinely different approach existed at the time. Skip when the design space was binary or the ticket dictated it. Never manufacture one nobody considered. If the PR's own description already raises it, skip it — restating the author is what reading the diff first exists to avoid.

**Knowledge checks** — only for non-obvious facts the worked example didn't already teach. Two strong ones beat five. If they restate a table, cut them.

**Code** — per the house style.

## Routing

Two sections can claim the same fact:

- A fact that explains the shape of the code → Constraints.
- Anything the author should answer, including a description that doesn't match the code → Review.
- Both? State the fact in Constraints, ask the question in Review. Don't write it twice at length.

## Footer

Files changed (count), lines added/removed, author, merge state, lines dropped as mechanical. No prose.

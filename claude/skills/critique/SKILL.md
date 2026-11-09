---
name: critique
description: Challenge a plan's approach before it is built. Reads the plan's Decisions and the code they touch, and returns what a teammate reviewing the pull request would push back on, each with the cleaner alternative worked out. Changes nothing, starts nothing.
---

# Critique

Input: the plan file. Run it before anything is built, when changing course costs a sentence in the plan and not a rebuild.

You are the reviewer who was not part of the planning. Whoever wrote the plan thinks every decision in it is reasonable. Find the ones a teammate would not let through.

1. Read the plan. Then read the code each Decision and each entry under Files touches, and the project's CLAUDE.md and CLAUDE.local.md files from the repo root down to those files, with any rule files they point to.
2. For each Decision, and for anything the plan implies without saying, ask:
   - Does it put one rule in two places? A filter, a validation, or a mapping that already lives somewhere, copied, with a test to keep the copies in step, is the tell.
   - Does it work around a shared component or function when it could use it or extend it? Look at everything the shared module exports, not only the component's props: the piece the plan says is missing is often exported beside it.
   - Is there a nearer precedent in the code than the one it follows? A project's written rules outrank matching the neighbouring code, and two rule files that disagree are a `raise`.
   - Can it be done with less: fewer files, no new state, no new abstraction?
   - What breaks when the code beside it changes later?
   - Does it do more than the task asks?
   - Are the Acceptance Criteria the fewest that pin down what was asked? One that repeats another, covers a state nobody asked about, or is marked `(app)` when a test shows it as well, is an objection: say which to merge, drop, or mark `(test)`.
3. Work each objection out far enough to know the alternative is real: where the change would go, what it costs, what it risks. Drop an objection you cannot give a workable alternative for.

Return the findings, most serious first, each as four lines:

- the Decision objected to, quoted
- what a reviewer would say, in a sentence
- the alternative: where it goes, what it costs, what it risks
- `change` when the alternative is clearly better at about the same cost, `raise` when it is a real trade-off, which the caller settles

After the findings, one line for each Decision you checked and found sound, saying what you checked it against. With nothing to object to, that list follows `no objections`. Edit nothing in the repo or the plan: the caller decides what to do with a finding.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

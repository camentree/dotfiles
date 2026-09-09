# Mode: ticket

Work Camen is about to start. The code doesn't exist yet. The output is a starting point: what's there now, and what will get in the way.

**Failure mode: designing instead of orienting.** This page does not propose an implementation, pick an approach, or slice PRs. That's `/plan-feature`, and it runs next. If you catch yourself writing "we should," stop — turn it into a constraint or an open question and move on.

**This page is shared.** `/plan-feature`, `/plan-pr`, and `/execute-pr` append to it later — see the section-ownership table in `format.md`. Write the orientation sections and stop.

## Gather

**Read the ticket's symptom, then the code, then the ticket's explanation.** The framing is what you're protecting yourself from, not the symptom — a bug ticket's error string is often the only thing that points at the right surface. Take enough to locate it, then read the code exhaustively before reading a word about why the author thinks it happens.

Where the ticket's description of current behavior doesn't match the code, that's the most valuable thing you'll produce.

**The ticket's vocabulary often isn't the code's.** GTKY is `ResidentBiography` in the API. When a grep on the ticket's words finds nothing, `git log --grep=<term>` finds the commit that built it, and the commit gives you the call chain.

Then: the ticket, its project, linked docs, and prior PRs on the same subject.

**Work spans repos.** The decisive fact is often in `august-frontend` — an error modal, a cached etag, a hard-coded allowlist. Follow it there and say so in the footer.

## Sections

Only these. The rest of the page belongs to the planning skills.

### Source links

An eyebrow: the Linear ticket (`https://linear.app/august-health/issue/<KEY>`), its project, and any related merged PRs.

### What's being asked

The outcome someone wants, in their terms. Not the implementation.

The standfirst above it states the shape of the problem; this section states the wanted outcome. Don't write the same sentence twice. The ticket's own repro steps go here, in a fold — they're the reporter's account, and "What happens today" is the code-verified version.

### What happens today

The worked example, run against current code. Real data, real current behavior — including the part that's wrong or missing. This is the "before" the work will change.

### How it works today

Diagram first, then the mechanism. Same as concept mode, scoped to what the ticket touches.

### Constraints

What will get in the way, and what the implementation won't be free to change. Rolling deploys, proto compatibility, another team's domain, an existing contract with partners, a pattern the codebase already established that this should mirror.

The highest-value section in this mode — it's what turns a two-hour change into a two-day one, and it's least visible from the ticket alone.

### Open questions

What the ticket doesn't answer and someone will have to decide. Product and technical ones marked apart. `/plan-feature` picks these up and works through them, so write them to be answered rather than admired.

### Prior art

Optional, and the most useful thing on the page when it exists: an existing implementation that solves a structurally similar problem. Camen would rather copy what's there than see a new design.

This is where the no-designing rule is hardest to hold, because "an implementation to mirror" is a solution by another name. Describe what the existing code does and where it's called. Stop before "so the fix is" — that sentence belongs to `/plan-feature`.

## Deliberately absent

**Where the change lands.** That's a file list, and file lists are `/plan-feature`'s job. Naming the layers here would be designing.

**Knowledge checks.** Only if the subject is genuinely unfamiliar, and usually the worked example has already done that work.

## Footer

Ticket key, project, related PRs, date.

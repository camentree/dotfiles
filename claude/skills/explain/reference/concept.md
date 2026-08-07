# Mode: concept

A concept, a subsystem, or a corner of the codebase Camen is cold on. No diff, no author intent, no decision to judge. The output is a map.

**Failure mode: unbounded scope.** Nothing tells you where to stop, so the page grows until it's a second copy of the code. Decide the boundary before writing and say what's outside it.

A concept in this codebase is the same thing as the code that implements it — "how does SCIM provisioning work" and "the SCIM subsystem" get the same page. A concept that isn't ours (advisory locks, proto `oneof`) deserves a chat answer, not a file.

## Gather

Find the entry points first — the controller, the job, the webhook, whatever the outside world touches. Trace one path through. Then find the callers.

**Draw the boundary before writing.** What's in scope, what's adjacent, what belongs to another team. Camen works in integrations; care, billing, and move-ins are neighbouring domains he touches but doesn't own. Getting this wrong wastes his time in both directions — explaining what isn't his problem, or omitting what is.

**Look for the seams**, not the leaves. Which pieces talk to which, what's the shared vocabulary, where does data enter and leave. Exhaustive coverage of every branch is the anti-goal.

## Sections

### Source links

An eyebrow: the main entry point's path in GitHub, and any Linear project or doc that governs it.

### What it's for, in one sentence

Under the title. What it does for a resident, a facility, or a partner — not what the code does.

### What actually happens

The worked example: one real request or job run, start to finish, with real data. This is the spine of the page.

### How it works

Diagram first — the pieces and what flows between them. Then the mechanism in as many steps as it has.

### Where the edges are

What's in scope and what isn't. Name the adjacent domains and who owns them. Say which of the neighbours you'd have to change to do something that feels like it belongs here but doesn't.

This section replaces a PR's Constraints. It's the thing that stops the map being infinite.

### Constraints

What forced this into its current shape and still holds it there — the contracts, the historical decisions that are now load-bearing, the invariants nothing enforces. Same test as always: could this have been built differently, or is this just something true about the code?

## Optional

**Where it breaks** — the known sharp edges. Only if they're real and known, not speculated.

**Knowledge checks** — non-obvious facts the worked example didn't teach.

**Code** — per the house style.

## No Review section

There's nothing to review. If something looks wrong, that's a finding worth raising in chat, not a section on the page.

## Footer

Entry points, main files by count not name, and the date — a concept page goes stale in a way a PR page doesn't.

## Lifecycle

Unlike a PR page, this one wants to be updated rather than replaced. Name it for the subject (`snapshots.html`, `scim.html`), and when re-running, revise rather than regenerate from scratch — Camen may have added notes.

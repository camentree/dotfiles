---
name: explain
description: Explain a pull request, a concept, or a ticket as a self-contained HTML page built around a worked example. Use when Camen needs to understand code he didn't write — before reviewing it, before working near it, or to get oriented in something unfamiliar.
---

# Explain

One HTML page that gets Camen from cold to able to act.

Reading is effortful. Optimize for fewest words.

## Pick the mode

| Input looks like | Mode | Output |
|---|---|---|
| A PR number or GitHub PR URL | `pull-request` | A judgment — approve, comment, push back |
| A concept, subsystem, or corner of the codebase | `concept` | A map |
| A Linear ticket key or URL, work about to start | `ticket` | A starting point |

Ambiguous cases: a ticket that's already been implemented is a `pull-request` if there's a PR to look at, otherwise `concept`. A concept that isn't ours (advisory locks, proto `oneof`) isn't a page at all — answer in chat.

## Read, then work

1. `reference/format.md` — house style. Collapsing, density, worked examples, diagrams, vocabulary, output mechanics, what Camen knows. Every mode.
2. `reference/<mode>.md` — sections, gathering, and the failure mode to avoid.
3. `reference/page.html` — the scaffold. Copy it; don't rewrite its CSS or script.

Where a mode file and the house style disagree, the mode file wins for sections and gathering; the house style wins for how anything is written.

## Shared process

### 1. Read the code before anything written about it

Every mode. A description — PR body, ticket, doc — supplies a framing that may not survive contact with the code, and a page built on it inherits its blind spots while reading as authoritative.

Where the writing diverges from the code, that divergence is a finding. Each mode file says where it goes.

### 2. Settle the worked example

Before writing anything else. See the house style for what counts as real data.

### 3. Draft, then cut

Apply density. Expect to delete a third.

### 4. Write the file and open it

Each mode has its own directory. `mkdir -p` it first — nothing else creates it.

| Mode | Path | Name |
|---|---|---|
| `ticket` | `~/Documents/notes/tickets/int-631-wrong-current-room.html` | Linear key, then what the ticket is about |
| `pull-request` | `~/Documents/notes/prs/pr-6897-august-backend-idempotent-external-charges.html` | `pr-`, the number, the repo it's in, then the PR's title |
| `concept` | `~/Documents/notes/concepts/snapshots.html` | What it's about |

All lowercase, words joined by hyphens. The trailing title is the subject in four or five words — short enough to read in a file list, specific enough to tell two tickets apart.

Stable names, so re-running a subject overwrites rather than accumulates. Re-running a ticket whose title would now read differently keeps the name it already has on disk — a renamed page is a page the planning skills can't find.

Then `open` it.

### 5. Check the rendered structure

Not just the markup. The `<details>`-inside-`<p>` bug looks fine in source and visibly breaks the page.

### 6. Audit the writing

Invoke the `writing-audit` skill on the page. Every time, including when the draft felt clean — a page reads as obvious from inside the session that produced it, which is the whole reason the audit exists. Tell him what it changed; he'll be reading the page and shouldn't have to guess which parts moved under him.

## Style

Read before writing:

- Page content and altitude: `~/.claude/skills/writing-style/references/artifacts.md`
- Anything he'll engage with in conversation: `~/.claude/skills/writing-style/references/conversation.md`, with the `prose-grader` agent on real questions

Do not restate those rules here. A skill that copies them drifts from them, then enforces the older version.

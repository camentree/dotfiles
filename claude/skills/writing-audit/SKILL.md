---
name: writing-audit
description: Audit and fix the writing a piece of work leaves behind — explainer and plan pages, PR descriptions, unpushed commit messages, and any question about to be put to Camen — against the writing-style references. Use before opening or un-drafting a PR, at the end of an implementation loop, or when he asks to audit writing.
argument-hint: (no args — audits the pages, diff, and PRs for the current branch)
---

# Writing audit

Audits and fixes the writing our work leaves behind. This skill is the **procedure**; it carries no rules of its own.

## Where the rules live

Read the reference for each surface before auditing it. Do not audit from memory, and do not audit from any summary of the rules, including one in this file.

| Surface | Reference |
|---|---|
| Explainer and plan pages | `~/.claude/skills/writing-style/references/artifacts.md` |
| Prose he engages with in conversation, questions above all | `~/.claude/skills/writing-style/references/conversation.md` |
| Page mechanics — folds, classes, diagrams | `~/.claude/skills/explain/reference/format.md` |
| Code and code comments | `style-pass` skill — run it rather than duplicating it here |
| PR descriptions, commit messages, review comments | `~/.claude/skills/writing-style/references/as-me.md`, plus the repo's `pull_request_template.md` |

**The floor is the `writing-for-humans` output style, and this audit is void without it.** It carries the context-independence test that item 1 leans on entirely and the voice rules. Confirm it's active before auditing anything. If it isn't — switched off, or you're a subagent, which don't inherit output styles — load it before proceeding. Auditing against the references alone silently drops half the standard.

**Why this file names no rules.** An audit carrying its own copy of the standard drifts from it, then quietly enforces the older, weaker version. If a rule seems missing from a reference, fix the reference, not this skill.

## What to audit

### 1. Pages this work produced

Anything in `~/Documents/notes/tickets/`, `prs/`, or `concepts/` touched by this work: explainers, ticket pages, plans. Audited first, because this is where the damage is worst and least visible.

The failure to hunt for is prose that is terse, precise, correct, and undecipherable to anyone who wasn't in the session. It passes every voice rule, which is why it survives. Run the context-independence test against every line: an identifier as a sentence's subject, a term coined mid-session used as shared vocabulary, a pointer standing in for what it says, a claim whose stakes are never stated.

The fix is never to delete the citation. Say the thing in plain words, move the `file:line` into a fold, leave the evidence intact.

Also check what `format.md` governs: does the collapsed page stand alone, does any summary only name a topic, does anything have to be expanded in the happy path.

Then dispatch the `prose-grader` agent on the page's uncollapsed body. The pass above shares the session context that made the prose opaque, so it will read its own shorthand as clear; the cold read is the actual test for that failure.

**Dispatching the grader, here and everywhere below:** hand it only the text — no repo path, no ticket link, no session summary. Withholding context is the entire mechanism; a non-empty `context_leak` in its report means the dispatch was bad, not the text. Act on every field: a wrong or vague restatement means rewrite and re-grade, each `lookups_needed` becomes plain words with the citation moved to a fold, `stakes_clear: false` gets the stakes added, and a sentence in `reread_sentences` gets rewritten, not defended. Don't argue with it — you wrote the text and you're grading the report on it. It judges comprehension only, never correctness or style.

### 2. Anything asking him a question

Rewrite per `conversation.md`, then dispatch the `prose-grader` agent before he sees it. This is the one item that runs even when nothing else needs auditing.

### 3. Code and code comments

Run `style-pass`. It owns the diff, knows which lines are new versus pre-existing, and compiles afterwards. Do not re-audit the code here — report what it found and move on.

### 4. PR descriptions

For this branch's PRs (`gh pr view`). Template sections are structure, not verbosity: where the repo has a PR template, every section stays, with a short `N/A` where it doesn't apply. Tighten the prose inside them; never strip the scaffold.

Check specifically for `Co-Authored-By` lines and any mention of AI generation. Both are banned by the output style, and both get added by default, so this is where they get caught.

If the description was drafted or reworked this session, dispatch the `prose-grader` agent on the drafted body before showing him old → new — its readers weren't in the session either.

### 5. Unpushed commit messages

Only if they haven't been pushed. Never rewrite pushed history. Same `Co-Authored-By` check.

## Out of scope, deliberately

Chat messages and ticket comments are drafted and sent in the moment, with their references loaded at the time, and they leave this branch. They aren't part of a change's leftover writing.

## How to act

- **Fix, don't just report.** Edit in place.
- **Never post to GitHub.** No comments, no review replies, no reactions. PR descriptions on his own PRs are the one exception, and only after showing him old → new and getting a yes. Everything else is his prose to send.
- **Never commit.** He commits.
- **Pages** are local files and get corrected directly. If a page is wrong about *substance* rather than wording, that's a separate conversation. Don't quietly restate a decision while tidying prose.
- **When unsure whether something is load-bearing** — a line that reads oddly but may be precise for a reason — keep it and flag it. Deleting something you didn't understand is worse than leaving it.

## Report

Terse. What was rewritten, what was kept and flagged, what `style-pass` found. One line each.

Record every rewrite first, so the running history in `~/.claude/logs/writing-audit.log` stays honest. One call per artifact, where the count is edits made *within* that artifact and the reason names the file and what was wrong with it:

```bash
bash ~/.claude/scripts/writing-audit-log.sh record page 3 "claude-setup.html — fold summaries named a topic instead of standing alone"
bash ~/.claude/scripts/writing-audit-log.sh record pr 1 "#6871 — dropped Co-Authored-By"
```

Kinds are `page`, `question`, `pr`, `commit`, `code`. A clean audit records nothing.

The log is how Camen sees whether this skill earns its place, so a rewrite you don't record is one he'll conclude never happened.

```
Rewritten
  claude-setup.html — "AC 3" replaced with the criterion it points at
  claude-setup.html — three fold summaries were topic labels, now stand alone
  PR #6871 — dropped Co-Authored-By, tightened What changed

Prose grader
  1 question failed: stakes unclear on the tenant-scoping ask. Rewritten, passed on re-run.

Kept and flagged
  ticket-BILL-2155.html — "the split case" is defined two sections up, left as is
```

If nothing needed changing, say `Clean.` and nothing else.

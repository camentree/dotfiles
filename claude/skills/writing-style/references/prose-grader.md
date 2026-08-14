# The prose grader

A check, not a review. One cheap subagent reads what's about to be shown to Camen, with none of the context this session has, and reports what it understood. If it can't say what's being said or asked, he wouldn't have been able to either.

This exists because **the writer is the worst possible judge of whether their own writing is context-independent.** By the time a page or question is drafted, you've traced the code, read the ticket, and named things in your own shorthand. Every referential shortcut reads as obvious from inside that. The only reliable test is a reader who doesn't have it.

## When to run it

Before any gate that hands him prose to read and act on:

- **Questions** — open questions from an investigation, questions posed alongside a plan or explain page, risks needing a call. Always, when the question has real setup.
- **Page bodies** — the uncollapsed body of an explainer or plan page, as part of the writing audit. The in-session audit shares the context that made the prose opaque, so it cannot catch these failures itself; the cold read is the actual test.
- **PR descriptions** — the drafted body, before he sees it. Its readers weren't in the session either.

Scope it to what's meant to be read and acted on, not the whole artifact. Fold contents and proof sections still follow every writing rule; they're just not where a misunderstanding blocks anyone.

**Skip it** when there's nothing durable being handed over, and for a one-line question with two obvious options. The check costs a round trip at exactly the moment he's blocked, so it earns its place on prose with real setup, not on "which of these two names?"

## Dispatch

The check is a registered agent: `prose-grader` in `~/.claude/agents/`, pinned to a cheap model with its protocol as its system prompt. Invoke it by name and give it **only the text**: no repo path, no ticket link, no session summary. Withholding context is the entire mechanism, and leaking it in to be helpful destroys the check — the agent reports any leak it notices in its `context_leak` field, and a non-empty one means the dispatch was bad, not the text.

It returns structured fields: a restatement in its own words, every lookup it would have needed, whether each question's stakes are clear, and the sentences it had to read twice.

## Acting on it

- **Restated wrong, or vaguely.** The text failed. Rewrite and check again.
- **Any `lookups_needed`.** That's referential dependence directly. Each becomes plain words, with the citation moved into a fold.
- **`stakes_clear: false`.** Add what turns on the answer.
- **Anything in `reread_sentences`.** A sentence that needed two passes gets rewritten, not defended.

Pass condition: restated correctly, no lookups, stakes known. Usually one round.

**Don't argue with it.** You wrote the text and you're grading the report on it, so a finding you talk yourself out of is the exact failure this check exists to prevent.

## What it is not

It doesn't judge whether the question is worth asking, whether a finding is right, or whether the prose is stylish. It answers one thing: **would this be understandable to someone who wasn't here?** Keep its job that narrow, or it starts reviewing content it has no context to review.

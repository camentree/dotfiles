# The cold reader

A check, not a review. One cheap subagent reads what's about to be shown to Camen, with none of the context this session has, and reports what it understood. If it can't say what's being asked, he wouldn't have been able to either.

This exists because **the writer is the worst possible judge of whether their own writing is context-independent.** By the time a question is drafted, you've traced the code, read the ticket, and named things in your own shorthand. Every referential shortcut reads as obvious from inside that. The only reliable test is a reader who doesn't have it.

## When to run it

Before any gate that hands him something to read and act on: open questions from an investigation, questions posed alongside a plan or explain page, risks needing a call.

Scope it to the parts meant to be answered, not the whole artifact. Proof sections still follow every writing rule; they're just not where a misunderstanding blocks anyone.

**Skip it** when there's nothing to ask, and when the question is one line with two obvious options. The check costs a round trip at exactly the moment he's blocked, so it earns its place on questions with real setup, not on "which of these two names?"

## Dispatch

One subagent, no tools beyond reading what you hand it. Give it **only the text**, and say so explicitly: no repo path, no ticket link, no session summary. Withholding context is the entire mechanism, and leaking it in to be helpful destroys the check.

Ask it four things:

1. In your own words, what is being asked? One sentence per question.
2. What would you need to look up to answer it? Name each file, ticket, or term you couldn't resolve from the text.
3. Do you know what changes depending on the answer?
4. Which sentences did you have to read twice?

Have it return `{questions: [{restated, lookups_needed: [], stakes_clear: bool, reread: []}]}`. Fields, not prose.

## Acting on it

- **Restated wrong, or vaguely.** The question failed. Rewrite and check again.
- **Any `lookups_needed`.** That's referential dependence directly. Each becomes plain words, with the citation moved into a fold.
- **`stakes_clear: false`.** Add what turns on the answer.
- **Anything in `reread`.** A sentence that needed two passes gets rewritten, not defended.

Pass condition: every question restated correctly, no lookups, stakes known. Usually one round.

**Don't argue with it.** You wrote the text and you're grading the report on it, so a finding you talk yourself out of is the exact failure this check exists to prevent.

## What it is not

It doesn't judge whether the question is worth asking, whether a finding is right, or whether the prose is stylish. It answers one thing: **would this be understandable to someone who wasn't here?** Keep its job that narrow, or it starts reviewing content it has no context to review.

# Questions asked of Camen

The highest-stakes prose there is. A review comment nobody can parse wastes a minute; a question nobody can parse blocks the work until he asks what it means, and he spends that round trip before he can start thinking about the answer.

The context-independence test in the output style is the floor. This is how it applies to asking.

## The shape

Four parts, in this order.

**1. The ask, as a question, in one sentence.** A real question with a question mark, answerable without reading anything else. Not a topic label, not a noun phrase, not a statement of what you found.

- Wrong: "Route scoping."
- Wrong: "What 'who changed what is recoverable' means."
- Right: "Should one bulk request be allowed to touch more than one facility?"

**2. Why it's a question at all.** Two or three sentences of situation, in plain words. What's true today, and what about it is unresolved. No identifiers as subjects, no coined shorthand, no ticket ids. This is where he gets enough footing to have an opinion, and it's the part most often skipped, because the writer already has the footing and forgets acquiring it.

**3. The options and what each costs.** Each says what it means in practice and what it gives up. An option nobody would pick is padding, not an option.

**4. The evidence, out of the way.** `file:line`, ticket ids, quoted criteria, precedent: all of it in a fold or a trailing parenthetical. There to check, never in a sentence he has to read to understand the ask.

## Through the AskUserQuestion tool

Camen would rather choose than type, so most questions go through the tool rather than prose. The four parts map onto its fields:

| Part | Field |
|---|---|
| The ask | `question`, ending in a question mark |
| Why it's a question | Fold into `question`, briefly |
| Each option and its cost | `label` plus `description`, where the description says what it gives up |
| Evidence | Omit. It doesn't fit, and a question needing it hasn't been written plainly enough |

`header` is a 12-character chip, so it's a category, not a summary.

**A recommendation goes first, labelled `(Recommended)`.** He can overrule it in one click.

**Use `preview` when the options are concrete artifacts** he'd compare visually: layouts, signatures, config shapes. Not for preference questions where the labels carry it.

**Batch up to four per call.** He'd rather answer eight in two rounds than eight in eight.

## Rules

- **Ask sharp questions, not a survey.** Three that change the shape of the work beat ten that prove you read everything.
- **A question whose answer changes nothing doesn't get asked.** If you'd proceed the same way either way, decide it and say what you decided.
- **Never ask him to hold two things in his head at once.** If the question needs a comparison, put the comparison in the question.
- **Quote, don't point.** Paste the acceptance criterion. "AC 3" is a lookup; the sentence itself is something he can react to.
- **One question per question.** Two asks bundled together get one answer covering whichever was noticed.
- **Say what you'd do.** A recommendation can be overruled in a word. An open-ended question makes him redo structuring you already did and threw away.

## Worked example

Before, which is what this file exists to prevent:

> Route scoping. The two internal bulk precedents disagree: BulkRateUpdateController.scala:33 scopes to org/facility via PermissionGroupAction, ItemClassificationController.scala:80 is GlobalScopePermissionAction. An id list extracted from a query may span facilities. Do we require one facility per request (and reject ids outside it, the SignOffController.scala:91-102 pattern), or accept a flat global list?

Every fact is true and cited. It's unanswerable without opening three files, and it never says what turns on the answer.

After:

> **Should one bulk request be allowed to touch more than one facility?**
>
> The new endpoint takes a list of item ids. That list comes out of a query, so it can hold items from several facilities at once, and we haven't decided whether that's allowed.
>
> We have precedent both ways. Bulk rate update requires permission on a specific facility. Item classification requires a global permission instead and accepts anything. Sign-off does a third thing: one facility per request, rejecting any id that doesn't belong to it.
>
> - **One facility per request.** Safer, and a cross-facility batch has to be split into several calls.
> - **Flat global list.** One call does everything, but anyone who can reach the endpoint can touch every facility.
>
> I'd take one facility per request unless cross-facility batches are expected to be common.
>
> <details><summary>Precedent</summary>
> BulkRateUpdateController.scala:33 (facility-scoped) · ItemClassificationController.scala:80 (global) · SignOffController.scala:91-102 (rejects ids outside the request's facility)
> </details>

Same facts, same citations, no lookups needed to understand the ask.

## Before he sees it

Run the cold reader (`cold-reader.md`) before any gate that asks him something with real setup. One cheap subagent sees the questions and nothing else and reports what it thinks is being asked. If it can't say, or says the wrong thing, the question gets rewritten first.

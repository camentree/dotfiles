# Writing for Camen

Read before writing anything he or a teammate reads: an explanation, a question, a decision, a difit thread or walkthrough, a review comment, a reply, a task title, a pull request description, a Log message.

## Who reads it

- Someone new to this part of the product, who was not in the session and last thought about it yesterday. Nothing may depend on what you saw and he did not.
- He reads it on the work page between other things, so the first line has to carry it.

## Always

- Lead with what a user sees or can do, then why it matters. How the code does it comes last, and only when asked or needed.
- Plain words and the product's own nouns: "the move-in agreement's care rate", not "the rate field" or a class name.
- Say what something does instead of naming it. No ticket, pull request, commit or file id standing alone: "MOV-423 (unlink residents from the profile header)", not "MOV-423".
- Real values over abstractions: the resident, the date, the amount you actually used.
- Fewest words. No opener, no recap, no restating the question, no hedging on what you ran. A guess is called a guess.

## By kind

- **Explanation** (`task.json`): two to four sentences. What the product does today, what changes, for whom.
- **Question**: the question in one sentence ending in a question mark. When it is about what a user sees or does, a screenshot or recording of that behavior with real values is required (`--picture`, .png or .mp4), since he can't answer one he can't picture (2026-11-25). The options, each with what it costs, the recommendation first. The long explanation and why it could not be decided go behind it, in `--explanation-q` and `--why-q`, never in front.
- **Decision**: what was chosen, in a few words; then why, in a sentence; then what was rejected. "Copies documents in batches of 100. The job timed out on 4,000 in one transaction. Rejected: one transaction for the whole facility."
- **Finding**: the behavior in a user's words, the steps with real values, expected against what happened. The code and the fix come last.
- **Task title**: what changes for a user, as a phrase: "Editable care rate on move-in agreements". No `feat:` or other prefix, no ticket id.
- **Pull request description**: short bullets for someone scanning. What behavior changed, how it was tested, the proof. No rationale or file names unless a reviewer needs them.
- **Review comment for a teammate**: a question or a suggestion to a peer, never a verdict. One behavior per comment.
- **Reply to a reviewer**: for a change the reviewer asked for, the commit's full hash alone; for a question, the answer in a sentence or two. No thanks, no apology.
- **Log message**: a short list, one line per item, each naming the thing in words and what happened to it. Nothing when nothing happened.
- **Walkthrough thread**: what the change does, then only the context a reader would otherwise ask for.

## Never

- Paragraphs where a list of three would do, or a list where one sentence would do.
- Status emoji or headers like "Summary" on something that fits on a screen.
- Code identifiers in the first sentence of anything.

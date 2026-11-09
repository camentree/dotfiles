---
name: review-pr
description: Help Camen review a teammate's pull request. Checks the branch out in its own worktree, runs its tests and the app, reproduces what looks wrong, and opens difit with a walkthrough and draft findings, each finding backed by what was run - the request, the response, and the state it left. He replies in the threads, marks what to post, and the marked comments go to GitHub as one review when he says. No code changes. Updates itself from his feedback.
---

# Review a pull request

Read the `difit` skill first: it holds how the server is started, how threads are posted and kept, the Wait monitor, and shutting down. This skill holds what goes in the threads and how to answer.

Input: a pull request number or URL. The code is someone else's: change nothing in it, commit nothing. Every comment that reaches GitHub is in his words, posted only when he says.

`<name>` is the author's first name and the branch without its prefix, lowercase, e.g. `jesse-sync-bed-start-with-financial-start`. Beside the difit files, `~/.claude/tasks/<name>.review/` holds the collateral: repro scripts, their output, and the proof page.

## Set up

1. `gh pr view <n> --json title,author,headRefName,baseRefName,body,files,headRefOid`. Read the description closely: its claims are what the review checks.
2. Name the terminal tab `tabname '<author> - <feature>'`, all lowercase, the author abbreviated the way he abbreviates people (the People list in his notes).
3. Check the branch out in its own worktree: `git fetch origin <branch> <base branch>`, then `wk <branch>`. Never in the worktree the session started in: it is usually his own branch with uncommitted work.
   - `wk` links the shared untracked files (`bin-local`, `CLAUDE.local.md`, `local.sbt`, ...). If it prints `no matches found` from `wk-share-files`, run `wk-share-files <main checkout> <worktree>` again from a fresh `zsh -ic`.
   - A `.env` that comes out as a dangling link (the main checkout has none): replace it with a copy of another worktree's `.env`. `bin-local/dev` rewrites its sandbox block.
4. `<base>` is `git merge-base HEAD origin/<base branch>`, a sha.

## Run it

Before writing a finding, run the code. A finding no one ran is a guess, and he will ask.

- The tests the pull request adds or edits, and the specs beside them, as the repo's notes say to run them. Note the pass counts for the walkthrough.
- The app, as the repo's notes say (`bin-local/dev` in the background for august-backend), on the worktree's own port and database.
- Read the changed code against the description. For each place the code and a claim might disagree, build the smallest state that tells them apart and run it: the requests in a script under `<name>.review/`, so he can rerun it. Before the bug, after the change, and against the claim.
- Check a suspicion from more than one side before calling it a bug: the case that works, the case that doesn't, and what master does.

## Collateral

Every finding carries what shows it. For the backend that is, from `<name>.review/`:

- the request line and body that set the state up, and the one that shows the bug,
- the fields of each response that matter (cut the rest, no tokens),
- the state left behind, read back through the endpoint that returns it, SQL only where no endpoint reaches it.

In the finding's thread, the short form: the steps as plain sentences with the actual dates or values, then expected against what came back. The full transcript goes in `<name>.review/<finding>.md`, with the script's path. For a frontend change, record it as `/proof`'s In a browser says.

When there is more than one finding, also build a proof page in `<name>.review/` as `/proof`'s The page says: the description's claims as the criteria, `failed` with the evidence for each finding, `shown` for the claims checked and holding. The first walkthrough thread ends with the page's path.

## The threads

Walkthrough threads start with `(walkthrough)`, findings with `(finding)`.

Walkthrough, in this order:

- **What the pull request does.** One thread on the first changed line of the main file: the author's PR and number, the change in a few sentences, the pieces it is made of.
- **Context.** Wherever a reader would otherwise have to ask: how the code it calls works, a precedent it follows, why a test changed.
- **Critical path.** The change most likely to break something else, and why.
- **How to verify.** The commands run and their counts, on the test file.

Findings, each a draft of a comment he could post to the author:

- Lead with the behavior in plain words and the domain's own nouns: "the bed assignment's start date stays on the move-in date", not "the bed doesn't move", and never "the date" without saying which. Then the concrete steps with real values. Code identifiers and the fix come last.
- Phrase it as a question or a suggestion to a peer, not a verdict.
- State only what was run. A guess about how common a case is, or what production data holds, is said as a guess or left out.
- One finding per behavior. Two bugs with one fix are still two threads, with the fix in each.

## Answer him

He reads the threads and replies. A reply from him is working the issue out with you, not a request for new wording:

- Answer the question plainly, in the same thread. Don't append a reworded comment.
- "I don't understand": tell it as a story, with a person and dates, before any code.
- When he restates it, check every part against what was run: the order of steps, which date is which, which side is earlier. Say "yes" only to what holds, and correct the rest by name.
- A message he starts with `(post)` is a comment to post, in his words. Check it the same way and reply with any fact it gets wrong. When he says to update it, reply `Text to post:` and the corrected text; the latest one in a thread wins.
- Resolved threads disappear from the server; that is him, not loss.

## Post

Only when he says to post, in the terminal. One review with `"event": "COMMENT"` — never approve or request changes — holding each thread's latest `(post)` text, verbatim without the marker, on the line its thread sits on:

```
gh api -X POST repos/<owner>/<repo>/pulls/<n>/reviews --input <scratchpad>/review.json
```

with `{"commit_id": "<headRefOid>", "event": "COMMENT", "comments": [{"path": "<repo-relative path>", "line": <n>, "side": "RIGHT", "body": "..."}]}`. Check `headRefOid` still matches the worktree's `HEAD` first; if the author pushed since, say so before posting. Give him the review's link and one line per comment posted, and name any finding he didn't mark.

## Close

When he says to close: shut difit down as its skill says, `bin-local/dev stop` (or the repo's own stop) in the review's worktree, and close the Chrome tab. Keep the worktree and its database: say how to remove them (`wk rm <branch>`, `bin-local/dev rm` first).

## Updating this skill

Whenever he corrects how the review went — in a thread or in the terminal, about wording, order, evidence, or setup — change this skill right then: one line, edited into the section it belongs to, the rule and its why in a clause. Then tell him in one line what changed. He reviews skill edits as uncommitted changes in the dotfiles repo, so write them, don't propose them. A correction about running difit goes in the difit skill; a fact about the repo goes in its notes, as the difit skill says.

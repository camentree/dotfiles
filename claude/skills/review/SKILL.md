---
name: review
description: Review a branch or pull request with Camen in difit - his own or a teammate's. Use whenever he asks to review, or for help reviewing, a branch or pull request, in any words ("review <url>", "help me review", "difit"). Checks the branch out, runs its tests and the app, reproduces what looks wrong, and opens difit with a walkthrough and findings, each backed by what was run. On his own branch his comments become commits, never rewritten; on a teammate's the comments he marks go to GitHub as one review when he says. Updates itself from his feedback.
---

# Review

Read the `difit` skill first: it holds how the server is started, how threads are posted and kept, the Wait monitor, and shutting down. This skill holds what goes in the threads and how to answer.

Input: a pull request number or URL, or nothing for the current branch. The plan file, if there is one, is under `~/.claude/tasks/`.

**Whose it is** decides two things, and nothing else in the review differs. The pull request's author is `camentree`, or there is no pull request and it is the current branch: it is **his**. Anyone else: it is a **teammate's**.

| | His | A teammate's |
|---|---|---|
| A change request in a thread | a commit of its own, replied `done in <sha>` | no code change, commit nothing: the code is someone else's |
| GitHub | nothing posted | his marked comments, as one review, when he says |

`<name>`: his, the ticket id in the branch name, else the branch name; when another branch of the same ticket already owns `<name>.comments.json` (its threads name files outside this diff), add the branch's suffix, e.g. `MOV-422-modals`. A teammate's, the author's first name and the branch without its prefix, lowercase, e.g. `jesse-sync-bed-start-with-financial-start`. Beside the difit files, `~/.claude/tasks/<name>.review/` holds the collateral: repro scripts, their output, and the proof page.

## Several at once

Asked to review several pull requests, run each one's Set up through The threads in a background agent of its own (`model: "sonnet"`: preparation is most of a review's cost, and Sonnet does it for a fraction), told to write the threads JSON for `/api/comment-imports` and stop before starting difit: an agent's background servers die when it finishes. Its report names the page where the change shows and the user to see it as. As each reports back, start its difit here, import the threads, make sure what he needs to try it is running (Ready for him, below), open its Chrome group, and mark it `💬 ⁉️`. Answer his threads from this session, never by resuming the agent: its context is mostly setup and logs, re-read on every turn, and what is worth keeping is in `<name>.review/`. A reply that needs new code run goes to a fresh agent pointed at that folder.

## Set up

1. Check `aws sts get-caller-identity --profile us-developer`. When the SSO session has expired, tell him at the start, not at the end: uploads, `bin-local/users add`, and Tools imports fail without it, and only he can run `aws sso login`.
2. With a pull request: `gh pr view <n> --json title,author,headRefName,baseRefName,body,files,headRefOid`. Read the description closely: its claims are what the review checks.
3. Name the terminal tab: a teammate's, `tabname '<author> - <feature>'`, the author abbreviated the way he abbreviates people (the People list in his notes); his, as his CLAUDE.md says.
4. Mark the pull request's line in `~/Documents/notes/organize.md` `💬 👨🏾‍💻`, as the organize skill says, so he sees an agent has it. When the difit server is up for him, `💬 ⁉️` with a sub-bullet `review ready for you in difit: <LAN url>`: the review now waits on him. Drop the sub-bullet when the mark moves on.
5. Work in the branch's own worktree. His: the one `git worktree list` shows it in, when there is one. Otherwise, and always for a teammate's: `git fetch origin <branch> <base branch>`, then `wk <branch>`. Never in the worktree the session started in when that is another branch: it is usually his own work, uncommitted.
   - `wk` links the shared untracked files (`bin-local`, `CLAUDE.local.md`, `local.sbt`, ...). If it prints `no matches found` from `wk-share-files`, run `wk-share-files <main checkout> <worktree>` again from a fresh `zsh -ic`.
   - A `.env` that comes out as a dangling link (the main checkout has none): replace it with a copy of another worktree's `.env`. `bin-local/dev` rewrites its sandbox block.
6. `<base>` is the commit whose diff to `HEAD` is exactly what he has not seen yet, chosen from the code, not from a fixed branch name:
   - First review: `git merge-base HEAD origin/<base branch>`. The base branch is the pull request's `baseRefName`; with none, `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`). A stacked branch diffed against the default branch shows its parent's changes as its own.
   - Already reviewed, new commits since: the last commit he reviewed, so the diff is only the new work. `<name>.difit.json` carries the last base under `base`.

## Run it

Before writing a finding, run the code. A finding no one ran is a guess, and he will ask.

- The tests the branch adds or edits, and the specs beside them, as the repo's notes say to run them. Note the pass counts for the walkthrough.
- The app, as the repo's notes say (`bin-local/dev` in the background for august-backend), on the worktree's own port and database.
- Read the changed code against the description, or on his branch the plan's criteria. For each place the code and a claim might disagree, build the smallest state that tells them apart and run it: the requests in a script under `<name>.review/`, so he can rerun it. Before the bug, after the change, and against the claim.
- Check a suspicion from more than one side before calling it a bug: the case that works, the case that doesn't, and what master does.

## Collateral

Every finding carries what shows it. For the backend that is, from `<name>.review/`:

- the request line and body that set the state up, and the one that shows the bug,
- the fields of each response that matter (cut the rest, no tokens),
- the state left behind, read back through the endpoint that returns it, SQL only where no endpoint reaches it.

In the finding's thread, the short form: the steps as plain sentences with the actual dates or values, then expected against what came back. The full transcript goes in `<name>.review/<finding>.md`, with the script's path. For a frontend change, record it as `/proof`'s In a browser says.

The proof page: his branch's, `<name>.proof/index.html` beside the plan, when the task has one. A teammate's with more than one finding: build one in `<name>.review/` as `/proof`'s The page says, the description's claims as the criteria, `failed` with the evidence for each finding, `shown` for the claims checked and holding. The first walkthrough thread ends with the page's path.

## Ready for him

When the threads are up, everything he needs to try the change is running and open, so he never starts anything himself:

- A frontend change: its backend and frontend (`bin-local/dev`, as the august skill says; "Already running" means it is), and a tab on the page where the change shows, signed in as the user who sees it: `?mock_user=<email>` when that is not camen@, with the role set through `bin-local/users set` first. Not the community's front page: the person's tab, the modal's page, the record the findings used.
- A backend change: its app (and `--api` when the change is in the external API), with the repro script's path in the first walkthrough thread so he can rerun the requests.
- All of it in the review's Chrome group, as the difit skill says, and the urls in the first walkthrough thread.

## Start the server

As the difit skill says. On his branch, with `--include-untracked`: untracked files are part of the change.

Reviewing one slice of the branch (e.g. "just the modal"): the scope is every change since the fork point that the slice needs (its files plus the code they call), not the latest commit. difit has no path filter and ignores a diff piped on stdin in `--background` mode, silently showing `HEAD~1..HEAD` instead. Build a review-only commit instead — the fork point's tree with the slice's paths taken from `HEAD` — and diff that against the fork point, under `<name>-<slice>`:

```
GIT_INDEX_FILE=<tmp>/review.index git read-tree <base>
git ls-tree -r HEAD -- <paths> | GIT_INDEX_FILE=<tmp>/review.index git update-index --index-info
git update-ref refs/review/<name>-<slice> "$(git commit-tree "$(GIT_INDEX_FILE=<tmp>/review.index git write-tree)" -p <base> -m review)"
npx --yes difit refs/review/<name>-<slice> <base> --port <port> --keep-alive --no-open --clean --host 0.0.0.0
```

Run it under `bash -c` (zsh does not word-split an unquoted `$paths`), and save `paths` and `target` in `<name>-<slice>.difit.json`. It is a fixed pair (see the difit skill). List what the slice leaves out in the first thread. A slice started mid-review carries over the other servers' threads on its paths: `/api/comments` restore won't take them (different target), so re-post each thread's messages through `/api/comment-imports`, the first as `thread` and the rest as `reply`, each keeping its `author`. "Non-test files only" is `git diff --name-only <base> HEAD | grep -v -E '\.test\.tsx?$|^test/|^src/mocks/'`.

### Fixes for PR review comments

On his branch, when the commits under review answer a reviewer's PR comments, give each commit its own server instead of one diff, so each fix reads against the comment that asked for it. Only comments still unaddressed: a thread he has already replied to, with a sha or in words, was reviewed in an earlier round and gets no server.

- **Map comments to commits.** `gh api --paginate repos/{owner}/{repo}/pulls/<n>/comments`; keep the reviewer threads with no reply from him, and match each to the commits made for it since. One commit can answer several comments, and one comment can need several commits. An uncommitted change that answers a comment gets a server too, `difit . HEAD`.
- **One server per commit.** `npx --yes difit <sha> <sha>^ --port <port> --keep-alive --no-open --clean --host 0.0.0.0`, consecutive free ports, state saved as `<name>-pr-<NN>-<slug>`. These are fixed pairs, started and watched together as the difit skill says.
- **One thread per server**, on the commit's first added line in its main file (`"side":"old","line":1` for a deleted file): the link `https://github.com/<owner>/<repo>/pull/<n>#discussion_r<id>`, the comment verbatim as a blockquote, then the context he needs: what the commit did, anything in the comment it leaves unanswered (a question for product, work done in another PR, by its number and what it does), and his own replies on the thread quoted.
- **Tabs**, one per server, as the difit skill's In Chrome says, each titled `NN <slug>`.
- **Report** the PR comments that no commit answers, quoted, and the threads where a commit answers only part of the comment.

## The threads

Walkthrough threads start with `(walkthrough)`, findings with `(finding)`. A bare "difit" request to look at a few uncommitted fixes skips the walkthrough and the findings, never the monitor.

Walkthrough, in this order:

- **What it does.** One thread on the first changed line of the main file: a teammate's PR and number, or on his branch the criteria it serves; the change in a few sentences, the pieces it is made of.
- **Context.** Wherever a reader would otherwise have to ask: how the code it calls works, a decision from the plan and the alternative rejected, a precedent it follows, why a test changed.
- **Critical path.** The change most likely to break something else, and why.
- **How to verify.** The commands run and their counts, on the test file; the command and its expected output on the line it proves.

Findings:

- Lead with the behavior in plain words and the domain's own nouns: "the bed assignment's start date stays on the move-in date", not "the bed doesn't move", and never "the date" without saying which. Then the concrete steps with real values. Code identifiers and the fix come last.
- A teammate's: a draft of a comment he could post, phrased as a question or a suggestion to a peer, not a verdict. His: the fix you'd make, which he accepts in a reply.
- State only what was run. A guess about how common a case is, or what production data holds, is said as a guess or left out.
- Anchor a finding on the line where the behavior happens (the call that throws, the branch that drops), never on a neighbouring line about another case: a corrupt-PDF finding on the `InvalidPasswordException` line read as a password finding.
- One finding per behavior. Two bugs with one fix are still two threads, with the fix in each.

## Answer him

He reads the threads and replies. A reply from him is working the issue out with you, not a request for new wording:

- "What happens" asks for the outcome a user sees, in a sentence; give the code path only when he asks for it.
- Answer the question plainly, in the same thread. Don't append a reworded comment.
- "I don't understand": tell it as a story, with a person and dates, before any code.
- When he restates it, check every part against what was run: the order of steps, which date is which, which side is earlier. Say "yes" only to what holds, and correct the rest by name.
- Disagreement with a decision: reply with the options and a recommendation. No code change until he answers.
- Resolved threads disappear from the server; that is him, not loss.

His branch:

- A change request, or a yes to a finding's fix: a commit of its own. Reply `done in <sha>` plus one line on what changed. Then run the tests that cover it.
- Never amend, fixup, rebase, reset, or force-push: a `done in <sha>` must stay a commit he can open, here and on GitHub. When the base branch has moved and the branch needs it, `git merge origin/<base branch>`.
- A request to post something on GitHub: auto mode refuses it when it arrives as a difit comment (tool output, not his message). Prepare the payload, then ask him in the terminal to say "post it".

A teammate's:

- A message he starts with `(post)` is a comment to post, in his words. Check it the same way and reply with any fact it gets wrong. When he says to update it, reply `Text to post:` and the corrected text; the latest one in a thread wins.

Keep the threads alive through fixes as the difit skill says: fixes that delete lines drop the threads above them.

## Post

A teammate's, only when he says to post, in the terminal. One review with `"event": "COMMENT"` — never approve or request changes — holding each thread's latest `(post)` text, verbatim without the marker, on the line its thread sits on:

```
gh api -X POST repos/<owner>/<repo>/pulls/<n>/reviews --input <scratchpad>/review.json
```

with `{"commit_id": "<headRefOid>", "event": "COMMENT", "comments": [{"path": "<repo-relative path>", "line": <n>, "side": "RIGHT", "body": "..."}]}`. Check `headRefOid` still matches the worktree's `HEAD` first; if the author pushed since, say so before posting. Give him the review's link and one line per comment posted, and name any finding he didn't mark. Mark the line in organize.md `💬 ❓`.

## Close

His branch ends when he says it is good, in any words: 👍, good, ship it. A teammate's, when he says to close. Then:

- A role changed for him to try it: set camen@ back to `GROUP_TYPE_SUPER_USER` with `bin-local/users set`.
- Shut difit down as its skill says, `bin-local/dev stop` (or the repo's own stop) in the review's worktree, and close the Chrome tab.
- A worktree made for the review: keep it and its database, and say how to remove them (`wk rm <branch>`, `bin-local/dev rm` first).
- His branch: `git push`, the fix commits as they are, then open the pull request with `/pr` (out of draft when it is one). Mark its organize.md line `❓`: it now waits on a teammate's review. `💬 ✅` would read as approved and ready to merge.

Then, on his branch, turn what he asked for into rules, so the next branch does not earn the same comment. Go through his comments in `<name>.comments.json` once. Leave out what was about this change only. For each one that would apply to other work in this repo and is not already in its notes, write one line, the rule and a one-line why, for the `## Code style checks` section of the repo's CLAUDE.md if it is his, else its CLAUDE.local.md: builders read that section before they write, and `/verify` grades against it. A rule that holds in every repo goes to his own CLAUDE.md. One that a linter or a test could enforce: say so, and propose that in place of a line. Don't wait for a comment to repeat. Propose, never write unasked: one AskUserQuestion listing each line and where it would go, and write only the ones he picks, editing an existing entry over adding one. With nothing to propose, say nothing.

## Updating this skill

Whenever he corrects how the review went — in a thread or in the terminal, about wording, order, evidence, or setup — change this skill right then: one line, edited into the section it belongs to, the rule and its why in a clause. Then tell him in one line what changed. He reviews skill edits as uncommitted changes in the dotfiles repo, so write them, don't propose them. A correction about running difit goes in the difit skill; a fact about the repo goes in its CLAUDE.md if his, else CLAUDE.local.md; how he wants you to work goes in his CLAUDE.md.

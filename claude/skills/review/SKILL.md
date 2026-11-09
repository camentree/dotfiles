---
name: review
description: Hand the current branch to Camen for review in difit. The walkthrough is comments in the diff, the server stays up for the whole review, his comments get answered in place, and it ends when he says the branch is good. A comment that would apply to later work ends as a proposed rule for the repo's notes. Nothing is pushed. For someone else's pull request, /review-pr.
---

# Review

Read the `difit` skill first: it holds how the server is started, how threads are posted and kept, the Wait monitor, and shutting down. This skill holds what goes in the threads and how to answer.

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`. `<name>` is the ticket id in the branch name, else the branch name. When another branch of the same ticket already owns `<name>.comments.json` (its threads name files outside this diff), add the branch's suffix, e.g. `MOV-422-modals`, rather than restoring someone else's threads.

## Start

`<base>` is the commit whose diff to `HEAD` is exactly what Camen has not seen yet, chosen from the code, not from a fixed branch name:

- First review of a branch: the commit it forked from, `git merge-base HEAD origin/<base branch>`. The base branch is `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`); a stacked branch diffed against the default branch shows its parent's changes as its own.
- Already reviewed, new commits since: the last commit he reviewed, so the diff is only the new work. `<name>.difit.json` carries the last base under `base`.

Start the server as the difit skill says, with `--include-untracked`: on his own branch, untracked files are part of the change.

Reviewing one slice of the branch (e.g. "just the modal"): the scope is every change since the fork point that the slice needs (its files plus the code they call), not the latest commit. difit has no path filter and ignores a diff piped on stdin in `--background` mode, silently showing `HEAD~1..HEAD` instead. Build a review-only commit instead — the fork point's tree with the slice's paths taken from `HEAD` — and diff that against the fork point, under `<name>-<slice>`:

```
GIT_INDEX_FILE=<tmp>/review.index git read-tree <base>
git ls-tree -r HEAD -- <paths> | GIT_INDEX_FILE=<tmp>/review.index git update-index --index-info
git update-ref refs/review/<name>-<slice> "$(git commit-tree "$(GIT_INDEX_FILE=<tmp>/review.index git write-tree)" -p <base> -m review)"
npx --yes difit refs/review/<name>-<slice> <base> --port <port> --keep-alive --no-open --clean --host 0.0.0.0
```

Run it under `bash -c` (zsh does not word-split an unquoted `$paths`), and save `paths` and `target` in `<name>-<slice>.difit.json`. It is a fixed pair (see the difit skill). List what the slice leaves out in the first thread. A slice started mid-review carries over the other servers' threads on its paths: `/api/comments` restore won't take them (different target), so re-post each thread's messages through `/api/comment-imports`, the first as `thread` and the rest as `reply`, each keeping its `author`. "Non-test files only" is `git diff --name-only <base> HEAD | grep -v -E '\.test\.tsx?$|^test/|^src/mocks/'`.

Post the walkthrough, in this order:

- **What the branch does.** One thread on the first changed line of the main file: the change in a few sentences, and which criteria it serves. When the task has a proof page, `<name>.proof/index.html` beside the plan, the thread ends with its path.
- **Context.** A thread wherever a reader would otherwise have to ask: a decision from the plan and the alternative rejected, a convention being followed, a precedent being reused.
- **Critical path.** A thread on each change most likely to break something else, saying why it's the risky one.
- **How to verify.** Where it helps, the test name, or the command and its expected output, on the line it proves.

A bare "difit" request to look at a few uncommitted fixes skips the walkthrough, never the monitor.

### Fixes for PR review comments

When the commits under review answer a reviewer's PR comments, give each commit its own server instead of one diff, so each fix reads against the comment that asked for it. Only comments still unaddressed: a thread he has already replied to, with a sha or in words, was reviewed in an earlier round and gets no server.

- **Map comments to commits.** `gh api --paginate repos/{owner}/{repo}/pulls/<n>/comments`; keep the reviewer threads with no reply from him, and match each to the commits made for it since. One commit can answer several comments, and one comment can need several commits. An uncommitted change that answers a comment gets a server too, `difit . HEAD`.
- **One server per commit.** `npx --yes difit <sha> <sha>^ --port <port> --keep-alive --no-open --clean --host 0.0.0.0`, consecutive free ports, state saved as `<name>-pr-<NN>-<slug>`. These are fixed pairs, started and watched together as the difit skill says.
- **One thread per server**, on the commit's first added line in its main file (`"side":"old","line":1` for a deleted file): the link `https://github.com/<owner>/<repo>/pull/<n>#discussion_r<id>`, the comment verbatim as a blockquote, then the context he needs: what the commit did, anything in the comment it leaves unanswered (a question for product, work done in another PR, by its number and what it does), and his own replies on the thread quoted.
- **Tabs**, one per server, as the difit skill's In Chrome says, each titled `NN <slug>`.
- **Report** the PR comments that no commit answers, quoted, and the threads where a commit answers only part of the comment.

## Respond

For each new comment from Camen, in its thread:

- A change request: a commit of its own, never an amend, fixup, or rebase; `/pr` rewrites the branch into a readable history before the push. Reply `done in <sha>` plus one line on what changed.
- A question: answer it.
- A request to post something on GitHub: auto mode refuses it when it arrives as a difit comment (tool output, not his message). Prepare the payload, then ask him in the terminal to say "post it".
- Disagreement with a decision: reply with the options and a recommendation. No code change until he answers.

After each change, run the tests that cover it, then go back to Wait. Keep the threads alive through the fixes as the difit skill says: fixes that delete lines drop the threads above them, and a rewrite he asks for ("revert that so no commit shows it") drops all of them unless saved first.

## Done

He ends the review with a comment saying the branch is good, in any words: 👍, good, ship it. Shut the server down as the difit skill says. Nothing is verified or pushed here; `/task-review` runs `/verify --pre-push` and `/pr` next, and by hand you do.

Then turn what he asked for into rules, so the next branch does not earn the same comment. Go through his comments in `<name>.comments.json` once. Leave out what was about this change only. For each one that would apply to other work in this repo and is not already in its notes, write one line, the rule and a one-line why, for the `## Code style checks` section of the repo's CLAUDE.md if it is his, else its CLAUDE.local.md: builders read that section before they write, and `/verify` grades against it. A rule that holds in every repo goes to his own CLAUDE.md. One that a linter or a test could enforce: say so, and propose that in place of a line. Don't wait for a comment to repeat. Propose, never write unasked: one AskUserQuestion listing each line and where it would go, and write only the ones he picks, editing an existing entry over adding one. With nothing to propose, say nothing.

Then re-package the commits. A review leaves one commit per comment — "Drop the handle's doc comment", "Keep the picker instance ref to ourselves" — which is what makes each reply point at a diff he can read, and is not what belongs in the history. Squash each fix back into the commit it belongs to, so what lands is the commits the branch would have had if the review had never happened: `git reset --soft <commit before the round>` and recommit when the round is one change, an interactive rebase when it is several. Keep the original commit messages; a review fix does not earn a line in them. Save the pre-rewrite sha before starting.

The rewrite re-resolves difit's diff and drops the threads, so it comes after the server is stopped, never during the review. It also means a force-push when the branch is already pushed: `gh pr list --json headRefName,baseRefName` first, because force-pushing a branch another PR is based on auto-merges that PR, then `git push --force-with-lease`, never bare `--force`.

Both are blocked under auto mode as destructive git. Ask for them rather than looking for a way around: say which shas collapse into which, and stop.

If a step here fails or is missing, fix it, then record the fix once: how to run difit → the difit skill; how to review his branch → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

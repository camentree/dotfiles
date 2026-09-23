---
name: review
description: Hand the current branch to Camen for review in difit. The walkthrough is comments in the diff, the server stays up for the whole review, his comments get answered in place, and it ends when he says the branch is good. Nothing is pushed.
---

# Review

Input: the current branch and, if there is one, its plan file under `~/.claude/tasks/`. `<name>` is the ticket id in the branch name, else the branch name. Two files sit beside the plan for the length of the review:

- `<name>.difit.json`: the running server's url and pid. Deleted when the review ends.
- `<name>.comments.json`: every thread, rewritten after every change. Never deleted.

## Start

If `<name>.difit.json` exists and `curl -X GET <url>/api/comments-json` answers, the review is already running. Skip to Wait.

Otherwise, with the default branch from `git symbolic-ref --short refs/remotes/origin/HEAD`:

```
npx --yes difit . <base> --background --keep-alive --no-open --clean --include-untracked --host 0.0.0.0
```

`<base>` is the commit whose diff to `HEAD` is exactly what Camen has not seen yet, chosen from the code, not from a fixed branch name:

- First review of a branch: the commit it forked from, `git merge-base HEAD origin/<base branch>`. The base branch is `git config branch.<current branch>.gh-merge-base` when that is set and `origin/<it>` exists, else the default branch; a stacked branch diffed against the default branch shows its parent's changes as its own. Pass that sha, not the branch name — a worktree's local default branch is often months stale, and passing it buries the change under everyone else's commits.
- Already reviewed, new commits since: the last commit he reviewed, so the diff is only the new work. `<name>.difit.json` carries the last base under `base`.

Save the base in `<name>.difit.json` alongside `url` and `pid`, so the next review can start from it.

`difit` is not installed on the machine; `npx --yes difit` is how it runs. `--host 0.0.0.0` because Camen reviews from a different device than the one the session runs on, and the default binding is reachable only from the session's own host. difit still prints a `localhost` url; swap in the machine's LAN address (`ipconfig getifaddr en0`) in `<name>.difit.json` and everywhere you give him the url, and check it answers there before posting the walkthrough. The target is `.`, not `@`: with `.` difit watches the worktree and `.git`, invalidates its diff cache on every change, and shows Camen a reload button in the page after each commit. With `@` and a compare branch it treats the pair as fixed commits, never watches, and caches the diff for the life of the server. It prints JSON with `url` and `pid`. Save that as `<name>.difit.json`. If `<name>.comments.json` already exists, the previous server died: restore it first with `curl -X POST <url>/api/comments -H 'Content-Type: application/json' -d @<name>.comments.json`, then skip to Wait.

Post the walkthrough as comments, one request:

```
curl -X POST <url>/api/comment-imports -H 'Content-Type: application/json' -d '[
  {"type":"thread","author":"claude","filePath":"<file>","position":{"side":"new","line":<n>},"body":"..."},
  ...
]'
```

Every comment you post carries `"author":"claude"`. User's doesn't.

What to post, in this order:

- **What the branch does.** One thread on the first changed line of the main file: the change in a few sentences, and which criteria it serves.
- **Context.** A thread wherever a reader would otherwise have to ask: a decision from the plan and the alternative rejected, a convention being followed, a precedent being reused.
- **Critical path.** A thread on each change most likely to break something else, saying why it's the risky one.
- **How to verify.** Where it helps, the test name, or the command and its expected output, on the line it proves.

Print the URL and notify: `osascript -e 'display notification "<name> ready for review" with title "Claude"'`.

## Wait

Watch for his comments with the Monitor tool, 30 minute timeout, re-armed on expiry:

```
last=$(curl -s -X GET <url>/api/comments-json | jq '[.threads[].messages[] | select(.author != "claude")] | length')
curl -N -s <url>/api/watch | grep --line-buffered commentsChanged | while read -r _; do
  count=$(curl -s -X GET <url>/api/comments-json | jq '[.threads[].messages[] | select(.author != "claude")] | length')
  [ "$count" -gt "$last" ] && echo "new comment from Camen ($count)"
  last=$count
done
```

The server broadcasts `commentsChanged` for every change, your own replies included; the count filter keeps it to his new messages so you do not wake yourself. On each event, `curl -X GET <url>/api/comments-json` and write the body to `<name>.comments.json`. His comments are the messages without `"author":"claude"`.

## Respond

For each new comment from Camen, in its thread:

- A change request: a commit of its own, never an amend, fixup, or rebase; `/pr` rewrites the branch into a readable history before the push. Reply `done in <sha>` plus one line on what changed. A reply is `{"type":"reply","author":"claude","filePath":...,"position":...,"body":...}` to the same import endpoint.
- A question: answer it.
- Disagreement with a decision: reply with the options and a recommendation. No code change until he answers.

After each change, run the tests that cover it. Editing a file makes difit's reload button appear in his tab (the commit itself does not; difit watches the worktree and `.git/HEAD`, not refs); he clicks it when he is ready, nothing restarts. Go back to Wait — but the monitor survives the event it reported, so arm a new one only after an expiry notice, never after replying, or two of them wake you for every comment.

If the server ever has to be restarted mid-review, keep the URL: add `--port <port>` from `<name>.difit.json`, drop `--clean`, restore the threads with the `curl -X POST <url>/api/comments` call above, save the new pid, and re-arm the monitor (it ends with the old server).

Threads are keyed on the merge-base commit, so commits leave them alone. Only a rebase onto a moved base changes the key: after one, the page shows no threads, but the old ones are still on the server. Fetch them with `curl -X GET '<url>/api/comments-json?base=<old merge-base short sha>&target=.&baseMode=merge-base'` and re-post them through `/api/comment-imports` under the new key.

## Done

He ends the review with a comment saying the branch is good, in any words: 👍, good, ship it. Write `<name>.comments.json` one last time, stop the monitor, `kill <pid>`, and delete `<name>.difit.json`. Nothing is verified or pushed here; `/task-review` runs `/verify --pre-push` and `/pr` next, and by hand you do.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

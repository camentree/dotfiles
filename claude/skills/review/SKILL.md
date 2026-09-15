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
npx --yes difit . <default branch> --merge-base --background --keep-alive --no-open --clean --include-untracked
```

`difit` is not installed on the machine; `npx --yes difit` is how it runs. The target is `.`, not `@`: with `.` difit watches the worktree and `.git`, invalidates its diff cache on every change, and shows Camen a reload button in the page after each commit. With `@` and a compare branch it treats the pair as fixed commits, never watches, and caches the diff for the life of the server. It prints JSON with `url` and `pid`. Save that as `<name>.difit.json`. If `<name>.comments.json` already exists, the previous server died: restore it first with `curl -X POST <url>/api/comments -H 'Content-Type: application/json' -d @<name>.comments.json`, then skip to Wait.

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

Watch for his comments with the Monitor tool, persistent:

```
curl -N -s <url>/api/watch | grep --line-buffered commentsChanged
```

On each event, `curl -X GET <url>/api/comments-json` and write the body to `<name>.comments.json`. His comments are the messages without `"author":"claude"`.

## Respond

For each new comment from Camen, in its thread:

- A change request: make it as a commit of its own, then reply `done in <sha>` plus one line on what changed. A reply is `{"type":"reply","author":"claude","filePath":...,"position":...,"body":...}` to the same import endpoint.
- A question: answer it.
- Disagreement with a decision: reply with the options and a recommendation. No code change until he answers.

After each change, run the tests that cover it. The commit makes difit's reload button appear in his tab; he clicks it when he is ready, nothing restarts. Go back to Wait.

If the server ever has to be restarted mid-review, keep the URL: add `--port <port>` from `<name>.difit.json`, drop `--clean`, restore the threads with the `curl -X POST <url>/api/comments` call above, save the new pid, and re-arm the monitor (it ends with the old server).

## Done

He ends the review with a comment saying the branch is good, in any words: 👍, good, ship it. Write `<name>.comments.json` one last time, stop the monitor, `kill <pid>`, and delete `<name>.difit.json`. Then run `/verify` once over everything the review changed. Do not push. That is `/pr`.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

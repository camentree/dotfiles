---
name: difit
description: How to run a difit server for Camen - preparing threads before he looks, starting it, posting threads, reading his comments when he sends them, replying, keeping the threads alive through commits and restarts, opening it in a Safari tab group, and shutting it down. Read by /review before it starts one; not a review on its own.
---

# difit

The mechanics every difit review shares. What to post and how to answer is the calling skill's business; this is how.

Two files sit in the pull request's task directory, `~/.claude/tasks/<repo>/<branch>/` (the README's "The task directory"), for the length of the review. A server for a slice or a single commit, which the calling skill names `<slice>`, uses `<slice>.difit.json` and `<slice>.comments.json` there instead.

- `difit.json`: the running server's `url`, `pid`, and `base`. Deleted when the review ends.
- `comments.json`: every thread, rewritten after every round of posting or reading. Never deleted.

## Start

If `difit.json` exists, its `pid` is alive, and `curl -X GET <url>/api/comments-json` answers, the server is already running: use it. A url that answers is not enough: difit takes the next free port, so a dead server's port is often held by another worktree's review.

Otherwise, from the worktree's git root:

```
difit . <base> --keep-alive --no-open --clean < /dev/null
```

- `<base>` is a sha the calling skill picks, never a branch name: a worktree's local default branch is often months stale, and passing it buries the change under everyone else's commits.
- Start it through the Bash tool with `run_in_background: true`, never with difit's `--background`: Claude Code kills its background tasks when the session ends, so closing the tab takes the server with it, while `--background` detaches it and it runs for days. It prints `difit server started on http://localhost:<port>`; read the port there and the pid from `lsof -ti :<port> -sTCP:LISTEN`.
- `< /dev/null`: with an untracked file in the worktree, difit asks whether to include it and, with no terminal, exits at the prompt. Add `--include-untracked` when the untracked files are part of the change: it stages each as an empty intent-to-add entry (`git add -N`), so deleting one mid-review shows as a tracked deletion; drop it with `git rm --cached <path>` too. A log or scratch file you wrote has no business in the worktree: move it under the gitignored `logs/` or the scratchpad.
- `difit`, not `npx --yes difit`: it is installed globally (5.0.12 under mise's node, on PATH), and npx adds a registry lookup to every start.
- No `--host`: localhost only, and every url you hand him is `localhost` (he dropped the LAN address, 2026-11-25). It binds `[::1]`, so curl `localhost:<port>`, not `127.0.0.1`. Save `http://localhost:<port>` as `url`.
- Another process can bind `127.0.0.1` on the same port later, and that process then answers every `localhost:<port>` request: his tab and your curls alike. Each time you read his comments, check that `lsof -nP -iTCP:<port> -sTCP:LISTEN` lists only difit's pid. If it doesn't, restart on a port nothing listens on (see Keeping threads alive) and point his tab there. Leave the other session's server alone. Seen 2026-11-09: another session's `python -m http.server 4971 --bind 127.0.0.1` took over a review's localhost.
- The target is `.`, not `@`: with `.` difit watches the worktree and `.git`, invalidates its diff cache on every change, and shows Camen a reload button after each commit. With `@` and a compare branch it treats the pair as fixed commits, never watches, and caches the diff for the life of the server.

Save `url`, `pid`, and `base` as `difit.json`. If `comments.json` already exists (prepared, or the previous server died): restore it with `curl -X POST localhost:<port>/api/comments -H 'Content-Type: application/json' -d @comments.json`, on a server started with the same target and `<base>` it was saved from, since threads are keyed on that pair.

## Prepared threads

For a review prepared before he looks (`/review --prepare`): nothing he sees opens. Start a server on the same target and base the review will open on, but on a free port with no `--host`, import the threads as Posting threads says, save `curl -X GET localhost:<port>/api/comments-json` as `comments.json` (or `<slice>.comments.json`), check its thread count (`jq '.threads | length'`: the body is `{threads, version}`, not an array) matches what you imported, and `kill` it, writing no `difit.json`. The file has to be the server's own output: `/api/comments` passes a thread that has `filePath` and `position` through as is, so a file built by hand in the import format restores threads with no messages or ids (round trip checked on 5.0.12, 2026-11-23).

## Posting threads

One request for a whole round:

```
curl -X POST localhost:<port>/api/comment-imports -H 'Content-Type: application/json' -d @<file>.json
```

with `[{"type":"thread","author":"claude","filePath":"<repo-relative path>","position":{"side":"new","line":<n>},"body":"..."}, ...]`. A reply is the same with `"type":"reply"` and the thread's `filePath` and `position`. Every message you post carries `"author":"claude"`; his don't. Build the JSON in a file in the scratchpad (`jq -n --rawfile` for a body with quotes), never inline in the shell. Keep every body you post there for the length of the review: they are what you rebuild from when threads go missing.

A reply lands on the most recently updated thread at that file and line, so when two threads share a line, check it landed where you meant; a finding just imported on a walkthrough's line takes that walkthrough's next reply. To move a misplaced reply, `curl -X DELETE localhost:<port>/api/comments/<threadId>` the thread that took it, post the reply again, then re-post the deleted thread (seen 2026-11-13).

On a server he is using, never add replies or move threads by editing the JSON and POSTing it to `/api/comments`: that replaces every thread, so a comment he posts between your GET and your POST is deleted with no copy anywhere. Restore through `/api/comments` only into a freshly started server.

`review.tabs` keeps the bare `(difit)` url, `http://localhost:<port>`: the page and the wrapper read the port from it. No `(difit LAN)` entry.

## In Safari

Open every difit in Safari, not Chrome (he moved reviews there 2026-11-18): one Safari tab group per review, named the way the review's terminal tab is (`jkramer - remove tasks`), made as the chrome-tab-groups skill's Safari section says, holding its difit tab, the pull request on GitHub when there is one, and, where there is one, the summary page, the running frontend, the proof page, the Linear ticket and the plan. The group is made in his existing window, never a new one (2026-11-24), once every page exists, with all its tabs in one call. A window showing a group is named `<group> — <page title>`, so a later tab goes into the window whose name starts with the group's: `tell w to make new tab at end of tabs with properties {URL:"<url>"}`; when no window is showing the group, do not switch his window to it: add the url to `review.tabs` so the card lists it, and add the tab the next time the group is shown. Several reviews in one session still get a group each. Each tab's title starts with what it is, so he can tell them apart at a glance (2026-11-18): `(context)` the summary page, `(difit)`, `(pr)`, `(app)`, `(proof)`, `(linear)`, `(plan)`. Pages the review writes (summary, proof) carry the prefix in their own `<title>`; every other tab gets it once loaded with `do JavaScript` that prefixes `document.title` and re-adds the prefix from a `MutationObserver` on `<title>`, since GitHub, Linear and difit rewrite their titles (it lasts until a reload; re-run it after setting a tab's URL). `do JavaScript` needs Safari's Developer setting "Allow JavaScript from Apple Events". Close the group's tabs when its server shuts down.

Open the difit tab on the work page's wrapper, `http://localhost:4990/review.html?id=<card id, url-encoded: valinor%23153>&port=<port>`, never bare difit: the wrapper frames difit under a thin bar holding only an "agent" button (opens the card's agent chat in Ghostty; send comments was removed 2026-11-25, since the monitor below picks comments up), and names the tab after the card. A review with several difit servers (one per commit) gets one wrapper tab per server, each with its own `port=` and `&name=<url-encoded, what that commit does>`, which titles the tab "<name> · <card title>" so six tabs of one card can be told apart: the wrapper has no switch between servers. To move or reload an open tab without losing its group, set its URL in place: `osascript -e 'tell application "Safari" to repeat with t in tabs of every window' -e 'repeat with u in t' -e 'if URL of u contains "port=<port>" then set URL of u to "http://localhost:4990/review.html?id=<card id>&port=<port>"' -e 'end repeat' -e 'end repeat'`.

## Reading his comments

On `[reviewing]`, arm a Monitor on `node ~/.claude/scripts/difit-comments-watch.cjs '<task directory>'` with `timeout_ms` 1800000, and re-arm it on each expiry while the state is `reviewing` (2026-11-25: presses that pass through the assistant were refused, so the button that sent `[comments sent]` is gone). It polls every `*difit.json` server's `/api/comments-json` every 3 seconds and prints one line per new or edited message not by `claude`, `difit <port> <file>:<line> new thread|reply|edited: <text>`; seen ids live in `difit-comments-seen.json` in the task directory, so a re-arm repeats nothing; it exits by itself, with one line, once no server answers for 15 seconds. Stop it with TaskStop when the review closes or on `[paused]`. On each line: reply in that thread at once with one line on what you will do ("Making the change in a new commit", "Pushing f1482a3 and posting the hash on Greptile's thread", "Answering below"), then act on it by `push-and-post.md`'s markers and reply again with the result (hash, what was posted, the answer), so no comment of his sits unanswered (he asked, 2026-11-25). Write the server's body to `comments.json` after each round. `[comments sent]`, from an older wrapper, is still read as: fetch every server and answer what has no reply.

Never write a response holding fewer threads than `comments.json` already has without knowing why. That file is the only copy, so one blind write turns a short response into permanent loss. Count both first. Resolving a thread removes it from the response, and he resolves as he goes: a missing thread on a line still in the diff is his doing, not loss, so don't re-post it. A missing thread on a line that left the diff is loss: recover it (below) before saving.

## Keeping threads alive

- Editing a file makes the reload button appear in his tab (a commit alone does not; difit watches the worktree and `.git/HEAD`, not refs). He clicks it when he is ready; nothing restarts.
- A thread whose anchor line is no longer in the diff is dropped from the server on the next write, with no warning, so a round of fixes that deletes lines takes the threads above them with it. Before each import round, diff the saved file against what the server returns, and re-post whatever went missing at the line its code sits on now. difit draws a thread only on a line in the diff, so an orphaned thread looks deleted to him.
- Threads are keyed on the merge-base commit, so commits leave them alone. Anything that moves `HEAD` backwards does not: a `git reset`, dropping a commit, or any other rewrite re-resolves the diff and drops every thread, with no `base=` query to bring them back. Save the threads first, rewrite, then re-post them through `/api/comment-imports`, the first message of each as `thread` and the rest as `reply`, each keeping its `author`.
- A rebase onto a moved base changes the key: the page shows no threads, but the old ones are still on the server. Fetch them with `curl -X GET 'localhost:<port>/api/comments-json?base=<old merge-base short sha>&target=.&baseMode=merge-base'` and re-post them under the new key.
- Restarting mid-review keeps the url: `--port <port>` from `difit.json`, no `--clean`, restore the threads with the `/api/comments` call above, save the new pid, and reload his tab in place (In Safari): one open from before the restart keeps its old threads.
- The servers are this session's background tasks, so resuming the session restarts them the same way.

## Fixed-pair servers

A server on two fixed commits (`difit <target> <base>`, for a slice or a single commit) never watches. After a commit it needs its ref rebuilt and a restart on the same port with the threads restored, then a reload of his tab. Batch the restarts, one per batch of replies, not one per commit. Run several from one background Bash, each with `&`, then `wait`.

## Shut down

Write `comments.json` one last time (the thread-count rule above still holds), `kill <pid>`, delete `difit.json`, and close any Safari tab you opened for it.

On `[paused]` (he pressed to queue, 2026-11-25): stop the comment monitor, save each server's `comments.json` as above, stop the servers, and keep the materials; the next `[reviewing]` starts them with the threads restored, as Start says.

If a step here fails or is missing, fix it, then record the fix once: how to run difit → this skill; what to post or how to answer → the calling skill. Rule and one-line why, edit an existing entry over adding one.

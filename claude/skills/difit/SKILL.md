---
name: difit
description: How to run a difit server for Camen - starting it, posting threads, watching for his comments, replying, keeping the threads alive through commits and restarts, opening it in Chrome, and shutting it down. Read by /review and /review-pr before they start one; not a review on its own.
---

# difit

The mechanics every difit review shares. What to post and how to answer is the calling skill's business; this is how.

`<name>` comes from the calling skill. Two files sit in `~/.claude/tasks/` for the length of the review:

- `<name>.difit.json`: the running server's `url`, `pid`, and `base`. Deleted when the review ends.
- `<name>.comments.json`: every thread, rewritten after every change. Never deleted.

## Start

If `<name>.difit.json` exists, its `pid` is alive, and `curl -X GET <url>/api/comments-json` answers, the server is already running: skip to Wait. A url that answers is not enough: difit takes the next free port, so a dead server's port is often held by another worktree's review.

Otherwise, from the worktree's git root:

```
npx --yes difit . <base> --keep-alive --no-open --clean --host 0.0.0.0 < /dev/null
```

- `<base>` is a sha the calling skill picks, never a branch name: a worktree's local default branch is often months stale, and passing it buries the change under everyone else's commits.
- Start it through the Bash tool with `run_in_background: true`, never with difit's `--background`: Claude Code kills its background tasks when the session ends, so closing the tab takes the server with it, while `--background` detaches it and it runs for days. It prints `difit server started on http://localhost:<port>`; read the port there and the pid from `lsof -ti :<port> -sTCP:LISTEN`.
- `< /dev/null`: with an untracked file in the worktree, difit asks whether to include it and, with no terminal, exits at the prompt. Add `--include-untracked` when the untracked files are part of the change: it stages each as an empty intent-to-add entry (`git add -N`), so deleting one mid-review shows as a tracked deletion; drop it with `git rm --cached <path>` too. A log or scratch file you wrote has no business in the worktree: move it under the gitignored `logs/` or the scratchpad.
- `npx --yes difit` because difit is not installed on the machine.
- `--host 0.0.0.0` because Camen reviews from a different device than the one the session runs on, and the default binding is reachable only from the session's own host. difit still prints a `localhost` url; save the LAN address (`ipconfig getifaddr en0`) as `url` and check it answers there before posting anything. Your own curl calls (reads, imports, the monitor) go to `localhost:<port>`: the allow rules are keyed on localhost, so they survive a LAN address change.
- A server on `0.0.0.0` doesn't stop another process from binding `127.0.0.1` on the same port later, and that process then answers every `localhost:<port>` request: his tab and your curls alike. On each monitor re-arm, check that `lsof -nP -iTCP:<port> -sTCP:LISTEN` lists only difit's pid. If it doesn't, restart on a port nothing listens on (see Keeping threads alive) and point his tab there. Leave the other session's server alone. Seen 2026-11-09: another session's `python -m http.server 4971 --bind 127.0.0.1` took over a review's localhost.
- The target is `.`, not `@`: with `.` difit watches the worktree and `.git`, invalidates its diff cache on every change, and shows Camen a reload button after each commit. With `@` and a compare branch it treats the pair as fixed commits, never watches, and caches the diff for the life of the server.

Save `url`, `pid`, and `base` as `<name>.difit.json`. If `<name>.comments.json` already exists, the previous server died: restore it with `curl -X POST <url>/api/comments -H 'Content-Type: application/json' -d @<name>.comments.json`, then skip to Wait.

## Posting threads

One request for a whole round:

```
curl -X POST localhost:<port>/api/comment-imports -H 'Content-Type: application/json' -d @<file>.json
```

with `[{"type":"thread","author":"claude","filePath":"<repo-relative path>","position":{"side":"new","line":<n>},"body":"..."}, ...]`. A reply is the same with `"type":"reply"` and the thread's `filePath` and `position`. Every message you post carries `"author":"claude"`; his don't. Build the JSON in a file in the scratchpad (`jq -n --rawfile` for a body with quotes), never inline in the shell. Keep every body you post there for the length of the review: they are what you rebuild from when threads go missing.

A reply lands on the most recently updated thread at that file and line, so when two threads share a line, check it landed where you meant.

On a server he is using, never add replies or move threads by editing the JSON and POSTing it to `/api/comments`: that replaces every thread, so a comment he posts between your GET and your POST is deleted with no copy anywhere. Restore through `/api/comments` only into a freshly started server.

Hand him both urls, `http://localhost:<port>` and the LAN one, localhost on `pbcopy`, and notify: `osascript -e 'display notification "<name> ready for review" with title "Claude"'`. Arm the Wait monitor in the same turn. Every server you start gets one.

## In Chrome

Open every difit in Chrome, in one tab group per session: all the session's difits share it, a tab each. With Claude in Chrome connected (the session was started with `claude --chrome`): `tabs_context_mcp {createIfEmpty: true}`. The session's group already exists when an earlier difit opened it: open the new difit there with `tabs_create_mcp` and `navigate`, never a second group. Otherwise the call creates the group with one empty tab: navigate that tab first, and `tabs_create_mcp` for the rest. Do it in one `browser_batch`, ending with each new tab's `document.title` through `javascript_tool`, naming the review (a reload loses it). Close a tab when its server shuts down; closing the group's last tab removes the group, and the next difit creates it again.

Name the group after this session's Ghostty tab as he sees it: `osascript -e 'tell application "System Events" to get name of every window of process "Ghostty"'` (the front tab's title per window). Not `~/.claude/tab-names/`, which holds only what `tabname` last wrote and misses a title he set in Ghostty himself. The extension names its group "Claude (MCP)" and has no tool to rename it, but a rename survives later `tabs_context_mcp` calls and the tabs stay in reach of its tools (checked 2026-11-09). Rename it with the Tab Grouper extension (`chrome/tab-grouper` in dotfiles, loaded unpacked in his Chrome), once the tab has loaded: `bash ~/.claude/scripts/chrome-tab-group.sh match=<difit url> "title=<name>"`. A matched tab already in a group renames that group in place, so the tabs stay in the extension's group; ungrouped matches get a new group. The other forms: `"group=<current name>" match=<url>` moves tabs into a named group, `"group=<current name>" "title=<new name>"` renames it, `color=<grey|blue|red|yellow|green|pink|purple|cyan|orange>` sets its colour, and `match` repeats. It acts silently and does nothing when nothing matches. To check, read the groups from the tab strip: `osascript -l JavaScript` walking `Application('System Events').processes['Google Chrome'].windows` for `AXTabGroup` elements, whose description is "group <name> - <n> Tabs, ...". After editing the extension's files, `chrome-tab-group.sh reload=1` reloads it.

The extension refuses `file://` urls ("Can't interact with browser-internal or unparseable URLs"), so serve a local page such as the proof page with `python3 -I -m http.server <port> --bind 127.0.0.1` from its folder, in the background, and open it on `127.0.0.1`.

Without Chrome connected: `open -na "Google Chrome" --args --new-window <urls>`, then group them with `chrome-tab-group.sh`, one `match` per url.

## Wait

Watch for his comments with the Monitor tool, 30 minute timeout, re-armed on expiry:

```
last=$(curl -s -X GET localhost:<port>/api/comments-json | jq '[.threads[].messages[] | select(.author != "claude")] | length')
curl -N -s localhost:<port>/api/watch | grep --line-buffered commentsChanged | while read -r _; do
  count=$(curl -s -X GET localhost:<port>/api/comments-json | jq '[.threads[].messages[] | select(.author != "claude")] | length')
  [ "$count" -gt "$last" ] && echo "new comment from Camen ($count)"
  last=$count
done
```

The server broadcasts `commentsChanged` for every change, your own replies included; the count filter keeps it to his new messages so you do not wake yourself. On each event, fetch `/api/comments-json`, find the threads whose last message isn't `claude`'s, and write the body to `<name>.comments.json`.

Never write a response holding fewer threads than `<name>.comments.json` already has without knowing why. That file is the only copy, so one blind write turns a short response into permanent loss. Count both first. Resolving a thread removes it from the response, and he resolves as he goes: a missing thread on a line still in the diff is his doing, not loss, so don't re-post it. A missing thread on a line that left the diff is loss: recover it (below) before saving.

The monitor survives the event it reported, so arm a new one only after an expiry notice, never after replying, or two of them wake you for every comment. On each re-arm, first list threads whose last message isn't `claude`'s: a comment posted between expiry and re-arm fires no event.

## Keeping threads alive

- Editing a file makes the reload button appear in his tab (a commit alone does not; difit watches the worktree and `.git/HEAD`, not refs). He clicks it when he is ready; nothing restarts.
- A thread whose anchor line is no longer in the diff is dropped from the server on the next write, with no warning, so a round of fixes that deletes lines takes the threads above them with it. Before each import round, diff the saved file against what the server returns, and re-post whatever went missing at the line its code sits on now. difit draws a thread only on a line in the diff, so an orphaned thread looks deleted to him.
- Threads are keyed on the merge-base commit, so commits leave them alone. Anything that moves `HEAD` backwards does not: a `git reset`, dropping a commit, or any other rewrite re-resolves the diff and drops every thread, with no `base=` query to bring them back. Save the threads first, rewrite, then re-post them through `/api/comment-imports`, the first message of each as `thread` and the rest as `reply`, each keeping its `author`.
- A rebase onto a moved base changes the key: the page shows no threads, but the old ones are still on the server. Fetch them with `curl -X GET 'localhost:<port>/api/comments-json?base=<old merge-base short sha>&target=.&baseMode=merge-base'` and re-post them under the new key.
- Restarting mid-review keeps the url: `--port <port>` from `<name>.difit.json`, no `--clean`, restore the threads with the `/api/comments` call above, save the new pid, and re-arm the monitor (it ended with the old server). Tell him to reload the tab: one open from before the restart keeps its old threads.
- The servers are this session's background tasks, so resuming the session restarts them the same way.

## Fixed-pair servers

A server on two fixed commits (`difit <target> <base>`, for a slice or a single commit) never watches. After a commit it needs its ref rebuilt and a restart on the same port with the threads restored, then a re-armed monitor and a reload from him. Batch the restarts, one per round of replies, not one per commit. Run several from one background Bash, each with `&`, then `wait`, and watch them from one monitor: the Wait loop per port inside `( ... ) &`, then `wait`.

## Shut down

Write `<name>.comments.json` one last time (the thread-count rule above still holds), stop the monitor with TaskStop, `kill <pid>`, delete `<name>.difit.json`, and close any Chrome tab you opened for it.

If a step here fails or is missing, fix it, then record the fix once: how to run difit → this skill; what to post or how to answer → the calling skill. Rule and one-line why, edit an existing entry over adding one.

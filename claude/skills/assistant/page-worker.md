# Working on the work page

For the `worker` subagent the assistant hands page and server changes to. Read with `data.md` before the first change. Written from the handover of 2026-11-24's workers; correct it when a step turns out wrong.

## Files

- Page: `~/.claude/skills/assistant/page/index.html`, `buttons.js` (labels, tooltips, disabled reasons), `review.html` (difit under a bar with only the agent button, since 2026-11-25).
- Server: `~/.claude/scripts/work-server.cjs`, with `work-state.cjs`, `my-prs.cjs`, `review-queue.cjs`, `task-set.cjs`. Data in `~/Documents/notes/work/`.
- Edit with the Edit tool only, never sed or an inline python replace: his rule for every session (a worker used python on 2026-11-25).
- All of it is a live link into `~/Projects/dotfiles/claude/`. Never commit. `index.html` and `work-server.cjs` are large: search and read in parts, or the context fills (the first worker died of it mid-edit).

## Checking by sight

He uses the page all day, so never press a real button or write to his data. Drive headless Chrome against stubs:

- Driver: `drive.mjs` in the day's scratchpad `chat/` folder (copy it forward if the scratchpad was cleared). `node drive.mjs <scenario>`, with headless Chrome on port 9333: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --remote-debugging-port=9333 --user-data-dir=<chat>/profileN about:blank`, a new profile number each time.
- It intercepts `/api/*`: state from a stub file (`STATE=<file>`), POSTs answered by the stub. `PASS=1` passes state GETs through, `PASSPOST=1` passes POSTs to port 4997, `PORT=` picks the page port, `SWAP=<section>` rewrites the section in the URLs. Screenshots land in `chat/shots/<scenario>-<name>.png`.
- Reading his real page read-only is `PASS=1` without `PASSPOST`.
- A full-page screenshot hides the pull request hover card: use a clip. A clip's `y` is in page coordinates: add `window.scrollY` to `getBoundingClientRect().y`, or it shoots blank background.
- `batch4/drive4.mjs` (2026-11-25) is the batch3 driver with `scenarios.part.mjs` spliced in (`head -77 drive.mjs`, the part, `tail -5`): scenarios `address`, `merge`, `start`, `tick`. macOS has no `timeout` command.
- To refresh the sandbox's `github.json` from GitHub (a `my-prs.cjs` or `work-state.cjs` change), run `work-state.cjs` with `TOKEN=$(gh auth token); HOME=<sandbox> GH_TOKEN=$TOKEN node …` (inline `GH_TOKEN=$(gh auth token)` came out empty on 2026-11-25) after copying `~/Documents/notes/today` into the sandbox: with only `HOME` changed `gh` is unauthenticated and hits the rate limit.
- Simpler, since 2026-11-25: `batch2/drive.mjs` in the same scratchpad (200 lines) loads the page from the sandbox server and lets every call through to it, so nothing is stubbed but a failing `/api/terminal`; with `PORT=4990` it reads his real page and answers every POST itself. Dry run already turns `/api/terminal` into a log line, so no Ghostty opens.
- Page files are served straight from disk, so an `index.html` or `buttons.js` edit is live on his page at once, before any restart: keep the page working against the old server's state too.
- 2026-11-25 drivers in that day's `chat/` (scratchpad `491d25ef…`), each self-contained over CDP on port 9333: `addressed.mjs` (stub question card on his real state; holds the answer POST to shoot "sending", then refuses it; `double` mode for Enter + Cmd+Enter + click), `kinds.mjs` (stub agents of each kind and a question with a png and an mp4), `paste.mjs` (pastes a canvas PNG into the + chat on the sandbox), `review.mjs`, `look.mjs '[[name, hash, setupJs]]'` (screenshots, POSTs stubbed; `PORT=4990` for his page).
- Native drag cannot be driven through CDP mouse events: dispatch `DragEvent`s from page JS instead (`dragstart` on the card, `dragover` on the target with `clientY`, `dragend`), then read the `/api/order` post (`batch3/scenarios.mjs`, 2026-11-25).
- `pkill -f` on a pattern can hit his live server too (it runs `work-server.cjs` from the nix store path): stop the sandbox by its pid, `pgrep -f "^node /Users/camen/.claude/scripts/work-server.cjs"`.
- The headless profile keeps `localStorage`: a press left in `work-page-pending` by an earlier run shows "sending…" and disables the card's buttons in the next (remove the key, or use a new profile).

## Sandbox server, for server rules

`cd <scratchpad>/sandbox && HOME=$PWD WORK_PORT=4997 WORK_DRY_RUN=1 node ~/.claude/scripts/work-server.cjs`, after copying `github.json`, `mine.json`, `projects.json` and `placement.json` from `~/Documents/notes/work` into `sandbox/Documents/notes/work`, and `~/.claude/tasks` into `sandbox/.claude/tasks`, and symlinking `~/.claude/skills/assistant/page` to `sandbox/.claude/skills/assistant/page` (the server serves the page from `$HOME`, so without it `/` is a 404). Dry run fakes `claude --bg` and `claude stop`, logging `dry run in <cwd>`, and fails a missing cwd with `spawn /bin/zsh ENOENT` as the real spawn does (a by-hand or notes task with no worktree gets `~/Projects/<repo>`, which may not exist; `deliver` now falls back to the session's recorded cwd, 2026-11-25). Its GitHub refresh always fails, so `github.json` stays as copied; its agent list is empty, so every agent reads as stopped: stub agents in the driver instead, or put the output of `claude agents --json` (edited as needed) in `sandbox/Documents/notes/work/dry-run-agents.json`, which a dry run reads in place of the real list. Whether a session has a terminal attached is read from the real process list even in a dry run. Copy `moves.jsonl`, `answers.jsonl`, `departed.json` and `log.jsonl` too when the change touches them. Stop it when done.

## Restarting the real server

Only when a server file changed, once per round. `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.work-page`, after checking the tail of `~/Library/Logs/work-page.log` shows no refresh in progress and there is no `~/Documents/notes/work/assistant.lock`. Afterwards `/api/state` has the same card count and the live agents still show. Restarts while he was pressing buttons gave him false errors.

## Other gotchas

- Start the sandbox server and headless Chrome so a driver run does not wait on them, and stop them by pid: a `TaskStop` on one background shell took both down, and the next run sat for an hour with nothing to talk to (2026-11-24).
- In the comments dropdown the rows follow the add box's `div`, so `:nth-of-type` misses by one: use `:nth-child(2)` for the first comment, or `:last-child`.
- An open question's answer box is also in the hidden speech-bubble menu, earlier in the document: pick the visible one (`offsetParent`) or a click lands on the body. The page re-renders on every state poll, so find, click and type in one go; an attribute set to mark a box is gone a moment later.

- A sandbox `work-state.cjs` run with no `github-cache.json` copied is a cold run (~15 GraphQL calls, ~180 points): copy the cache with `github.json`. To test sync logic with no GitHub calls, `ratelimit/harness/` in scratchpad `491d25ef…` (2026-11-25) holds copies whose `pull-common.cjs` replays a pool of recorded responses (`GRAPHQL_REPLAY=<pool.json>`, a `<pool>.fail` file makes every call rate-limited), with `test-changes.cjs` (what a run refetches) and `timer-test.sh` (pause and idle timing, times scaled down by 10).
- Running `my-prs.cjs` rewrites `~/Documents/notes/today/prs.js`, which the old Today page (port 4980) reads.
- His real ticks, comments, Day and order are in `mine.json`: a sandbox copy carries them.

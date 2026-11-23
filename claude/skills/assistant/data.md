# The work page's data

Camen's work page shows every piece of work by whose hands it is in. Three writers, three places, joined by the server. Nobody writes another's file.

| Writer | File | Holds |
|---|---|---|
| `~/.claude/scripts/work-state.cjs`, run by the server every 2 minutes | `~/Documents/notes/work/github.json` | Facts from GitHub: his open pull requests, teammates' pull requests that want his review. Never edited by hand or by an agent. |
| The agent working on a task, through `~/.claude/scripts/task-set.cjs` | `~/.claude/tasks/<repo>/<branch>/task.json` | What the agent knows: explanation, decisions, proof, findings, a question, its own status, the drafted description. |
| `~/.claude/scripts/work-server.cjs`, port 4990 | `~/Documents/notes/work/mine.json`, `projects.json`, `log.jsonl`, `outbox.jsonl` | What he did on the page: ticks, the Day, asked marks, snoozes, dismissals, order, tasks he added, Log messages, and messages waiting for a busy session. Agents change these only through the server's API. |

The page is `~/.claude/skills/assistant/page/index.html`, served by the server at `http://localhost:4990`. `~/Documents/notes/work/config.json` holds switches (`{ "autostart": false, "maxAutoAgents": 3, "assistant": true }`).

## `task.json`

One per task, beside `plan.md`, `proof/` and `review/` in the task directory. `<repo>` is the `basename` of `git remote get-url origin` without `.git`, `<branch>` is the branch, slashes kept as subdirectories. A teammate's pull request uses its head branch. A by-hand task has no file: it lives in `projects.json`.

```json
{
  "id": "valinor/camen/mov-474-copy-facility",
  "title": "Copied contacts and documents in the CopyFacility job",
  "kind": "mine",
  "project": "Linked Residents",
  "repo": "valinor",
  "branch": "camen/mov-474-copy-facility",
  "base": "master",
  "worktree": "/Users/camen/Projects/.valinor-worktrees/camen/mov-474-copy-facility",
  "pull": null,
  "ticket": "https://linear.app/august-health/issue/MOV-474",
  "agent": {
    "session": "mov-474 - copy facility",
    "sessionId": "0d1d76aa-...",
    "state": "working",
    "doing": "building group 2 of 3",
    "since": "2026-11-23T13:05:00Z",
    "heartbeat": "2026-11-23T13:41:00Z"
  },
  "ready": null,
  "explanation": "Copying a facility makes a new facility from an old one. Until now the copy left out residents' contacts and uploaded documents. This adds both to the copy job.",
  "decisions": [
    { "title": "Copies documents in batches of 100", "why": "The job timed out copying 4,000 documents in one transaction.", "alternative": "One transaction for the whole facility" }
  ],
  "findings": [
    { "title": "Typed rate is lost when the assessment is redone", "detail": "Enter 4,200, redo the assessment, the field is empty.", "reproduced": true }
  ],
  "proof": [
    { "caption": "A 4,000-document facility copied end to end", "file": "proof/copy.mp4", "kind": "video" }
  ],
  "question": null,
  "description": null,
  "labels": [],
  "review": null,
  "updated": "2026-11-23T13:41:00Z"
}
```

- `kind`: `mine` (his branch or pull request) or `teammate` (someone else's pull request he reviews).
- `pull`: the pull request url once there is one. The server joins `task.json` to `github.json` on it, else on `repo` + `branch`.
- `agent.state`: `working`, `blocked` (a question is open), `ready` (something waits for him, see `ready`), `reviewing` (his review is open in difit), `done`. The server shows `stopped` itself when `state` is `working` and the session is gone from `claude agents --json`, or `heartbeat` is older than 20 minutes while the session is no longer busy (a busy one may be sitting in a long `gh pr checks --watch`), or the session is waiting on an approval.
- `agent.heartbeat`: set on every `task-set.cjs` call. A working agent calls it at least every 10 minutes, with `--doing` saying what it is on.
- `ready`: what waits for him. `review` (the agent's review of a teammate's pull request is prepared), `fixes` (review comments or CI are fixed and wait for his look before pushing), `work` (a built task, pushed, no pull request yet). `null` otherwise.
- `explanation`: two to four sentences for someone new to this part of the product. See `writing.md`.
- `decisions`: every choice the agent made without asking that he might want reversed.
- `findings`: an agent's review of the change, each run before it is written.
- `proof`: files relative to the task directory. The page shows them in order, one at a time. `kind` is `video`, `image` or `page`. Give the recordings and screenshots themselves first, each with its own caption, since he sees those without leaving the card; a proof page (`proof/index.html`, kind `page`) shows only as a link, so it goes last (the first prepared review recorded only the page, 2026-11-23).
- `question`: `{ "text", "explanation", "why", "options": [{ "label", "cost" }], "pictures": ["proof/q1.png"], "asked": "<iso>", "answer": null }`. `why` says why it could not be decided without him. The server fills `answer` (`{ "text", "options": ["<label>"], "at" }`) and delivers it to the agent's session. Clear it with `--question-clear` once acted on.
- `description`: the pull request description drafted for him to edit before publishing.
- `review`: for a prepared review, `{ "difit": { "base": "<sha>", "comments": "comments.json" }, "tabs": [{ "label": "(context)", "url": "..." }] }`: what opens when he presses review. `difit` is a list of those, each with its `target`, when the review has one server per commit (fixes to review comments).

## `task-set.cjs`

Run from the task's worktree (it works out `<repo>` and `<branch>`), or pass `--task <repo>/<branch>`. Creates the file when missing. Every call sets `updated` and `agent.heartbeat`.

```bash
node ~/.claude/scripts/task-set.cjs \
  [--title "..."] [--kind mine|teammate] [--project "..."] [--pull <url>] [--ticket <url>] [--base <branch>] \
  [--state working|blocked|ready|reviewing|done] [--doing "..."] [--session "<name>"] [--session-id <uuid>] \
  [--ready review|fixes|work|none] \
  [--explanation "..."] [--description-file <path>] [--label <label>]... \
  [--decision "<title>" --why "..." [--alternative "..."]] \
  [--finding "<title>" --detail "..." [--reproduced]] \
  [--proof <file> --caption "..."] [--proof-clear] [--findings-clear] [--decisions-clear] \
  [--question "<text>" --explanation-q "..." --why-q "..." --option "<label>|<cost>"... [--picture <file>]...] [--question-clear] \
  [--review-file <path to json>] \
  [--json]
```

`--json` prints the file. A question sets `state` to `blocked`; the agent then ends its turn. The answer arrives as a message in its session.

## Server API

All under `http://localhost:4990`. Bodies are JSON.

| Call | Does |
|---|---|
| `GET /api/state` | Everything the page draws (below). |
| `POST /api/tick` `{ id, checked }` | His tick on a card. Cosmetic; cleared when the card changes section. |
| `POST /api/day` `{ action: "add" \| "remove" \| "title", hour, id, title }` | The Day. `hour` is 0 to 23. |
| `POST /api/asked` `{ id, reviewer, asked }` | He asked (or un-asked) a reviewer. Stores when. |
| `POST /api/snooze` `{ id }`, `POST /api/dismiss` `{ id }` | Hide until tomorrow, or for good. |
| `POST /api/order` `{ list, ids }` | The order he dragged a list into. `list` is a section's name (`"Review"`), `"day:<hour>"` (`"day:14"`) or `"project:<name>"` (`"project:Linked Residents"`). |
| `POST /api/task` `{ project, title }` | A by-hand task. Also how the assistant creates one. |
| `POST /api/tracker` `{ name: "water" \| "stood" }` | One mark, now. |
| `POST /api/log` `{ text, from? }` | A Log message. `from` defaults to `me`, and a message from him is delivered to the assistant. The assistant posts with `from: "assistant"`. |
| `POST /api/answer` `{ id, text, options }` | Writes the answer into the task's question and delivers it to the agent. |
| `POST /api/agent` `{ id, kind: "review" \| "address" \| "fix" \| "start", note }` | Starts a background session on that card with the matching skill and his note. When an agent is already working on the card, delivers `[note] <note>` to it instead. |
| `POST /api/open` `{ id }` | He is ready to review: tells the card's agent to open what it prepared. |
| `POST /api/send` `{ id }` | He finished commenting in difit: tells the agent to read every thread and act on them as one batch. |
| `POST /api/publish` `{ id, description }` | Tells the agent to open the pull request (not a draft) with that description. |
| `POST /api/merge` `{ id }` | Merges the pull request, deletes its remote branch, refreshes. |
| `POST /api/terminal` `{ id }` | Opens Ghostty attached to the card's agent session. |
| `POST /api/refresh` | Runs `work-state.cjs` now. |
| `GET /files/<repo>/<branch>/<path>` | A file from a task directory (proof media, pictures). |

### `GET /api/state`

```json
{
  "updated": "2026-11-23T13:41:00Z",
  "date": "2026-11-23",
  "agentsWorking": 3,
  "sections": [{ "name": "Answer", "cards": ["<id>"] }],
  "cards": { "<id>": {} },
  "day": [{ "hour": 13, "title": "Share email log", "cards": ["<id>"], "meetings": ["6:45 pm Max <> Camen"] }],
  "projects": [{ "name": "Linked Residents", "done": 3, "total": 13, "due": "2026-11-30", "cards": ["<id>"] }],
  "pulls": {
    "you": [{ "heading": "Needs me", "rows": [{ "number": 87, "title": "...", "note": "6 threads", "stack": "1/2", "age": "3d", "old": false, "url": "..." }] }],
    "others": []
  },
  "log": [{ "at": "2026-11-23T13:05:00Z", "from": "assistant", "text": "..." }],
  "trackers": { "water": ["<iso>"], "stood": ["<iso>"] }
}
```

Sections, always these six in this order: `Answer`, `Merge`, `Review`, `Respond`, `Ask`, `Agent work`. `day` has an entry for every hour from 8 to 18.

A card:

```json
{
  "id": "valinor#76",
  "title": "Editable Recommended Care Rate on move-in agreements",
  "url": "https://github.com/augusthealth/valinor/pull/76",
  "tags": ["backend", "frontend"],
  "ref": "#76 → master",
  "who": "Naomi",
  "opened": "2026-11-20T08:46:43Z",
  "lines": 252,
  "checks": "pass",
  "reviews": 0,
  "standing": "waiting on you 3d",
  "waits": null,
  "checked": false,
  "agent": { "state": "ready", "doing": "review ready", "since": "<iso>" },
  "primary": "open",
  "buttons": ["open", "snooze", "dismiss"],
  "reviewer": null,
  "asked": null,
  "explanation": "...",
  "decisions": [],
  "findings": [],
  "proof": [{ "caption": "...", "url": "/files/valinor/naomi/care-rate/proof/rate.mp4", "kind": "video" }],
  "question": null,
  "description": null,
  "size": "a couple of hours",
  "project": "Linked Residents"
}
```

- `id`: `<repo>#<number>` for a pull request, `<repo>/<branch>` for work with none, `task:<n>` for a by-hand task.
- `checks`: `pass`, `fail`, `pending` or `none`.
- `standing`: one phrase for where it stands and for how long, written by the server ("approved 2h ago", "6 threads from Josh, 3d", "Jesse, not asked", "Josh, asked 2h ago", "ready 40 min ago", "not started").
- `waits`: `null`, or why it cannot be acted on yet ("waits for #84"). The page dims the card and disables `primary`.
- `agent`: `null` when no agent has it. `state` as in `task.json`, plus `stopped`.
- `buttons`: which to draw, in this fixed order when present: `merge`, `agent`, `open`, `send`, `publish`, `start`, `snooze`, `dismiss`. `primary` names the one drawn filled. The page labels `open` as "review".
- `reviewer` and `asked`: on Ask cards, who reviews it and when he asked (`null` when not yet).
- `question`: as in `task.json`, with `pictures` as urls.
- `size`, `project`: shown on cards with no pull request.

## Worktrees

A session the page starts already runs inside its branch's worktree, with `~/Projects/.<repo>-worktrees` added as a working directory. Move into any other worktree with `cd` in Bash, never the EnterWorktree tool: it stops for an approval nobody is at the terminal to give (the first agent started from the page sat on that prompt, 2026-11-23). The page shows a session waiting on any approval as stopped, "needs an approval in its terminal".

## Messages to an agent

The server delivers his answers and button presses straight to the agent's session, as a new message in it: no agent watches a file. Each starts with a line saying what it is:

- `[answer] <his words>` and the options he ticked
- `[open review]`
- `[comments sent]`
- `[publish]` followed by the description. What it publishes depends on what is ready: `work`, open the pull request with that description; `fixes`, push and post the drafted replies; `review` on a teammate's pull request, post his marked comments as one review (the description, when given, is the review's summary).
- `[note] <his words>`

An idle session gets the message directly. A busy one (mid-turn, or holding an app or a difit server as background shells) gets it through the assistant, which arrives as a cross-session message from the session named `assistant` and carries the same weight as one from him.

A Log message to the assistant arrives as `[log] <his words>`, the hourly wake as `[hourly]`, and a message to pass on as `[relay <session name>] <message>`.

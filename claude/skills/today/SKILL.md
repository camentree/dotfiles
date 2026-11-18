---
name: today
description: Camen's day plan - the hour-by-hour page and the backlog at ~/Documents/notes/today/. Use it in the morning when he dictates what he is thinking about ("here's what I'm thinking about today", "plan my day") to rebuild the backlog and the day's plan, and use it from any session during the day to record that a planned item finished, moved, ran long, or changed state, or to add something to the backlog.
---

# Today

Everything is in `~/Documents/notes/today/`. Agents write the two data files; Camen reads them through the page.

| File | What it is |
|---|---|
| `today.js` | Today's schedule: time blocks, the items in each, links, and things to copy. Rewritten every morning. |
| `backlog.js` | Everything he could be working on, by work stream, with the state and next step of each. Lasts across days. |
| `index.html` | The page. A Today view and a Backlog view; re-reads both data files every minute. Does not change from day to day; change it only when he asks for a change to the page itself. |
| `state.json` | His ticks and notes, by date, written by the page. Read it; never write it. |
| `thread.js` | The agent's side of the notes thread at the bottom of the page: what was done with each of his notes. Agents append to it. |
| `server.cjs` | Serves the folder at `http://localhost:4980` and writes `state.json`. A launchd agent (`today-page`, in the dotfiles' `user.nix`) keeps it running. |
| `archive/` | Earlier days' `today.js`, named by date. |

`~/Documents/notes/organize.md` (the organize skill) stays his own hand-kept list of projects and pull requests; read it, don't replace it.

## What agents do and don't do here

Planning only curates. Don't start agents, app servers, difit, or code reviews ahead of a time slot, and don't open browser tabs. He starts each piece of work himself when its slot arrives, from the copy buttons on the page. Decide the order, the grouping and what to leave out yourself; don't ask him to pick. He said on 2026-11-18 that this holds until the workflow has been tried for a while. Moving or dropping an item is something he tells an agent to do; the page has no editing.

Describe items neutrally. No "urgent", "must", "should".

## Morning: build the day from his dictation

He dictates loosely what is on his mind. Some of it is work to do today, some is not worth today's time, and sorting that out is the job.

1. Read `backlog.js`, yesterday's `today.js`, and `organize.md`.
2. Refresh the facts, in parallel:
   - Linear: issues assigned to him in started, unstarted and backlog states, and projects he is a member of.
   - GitHub, his open pull requests with review decision, mergeable state, CI state, unresolved thread count and base branch (one GraphQL search, `is:pr is:open author:@me org:augusthealth`).
   - GitHub, pull requests requesting his review (`gh search prs --review-requested=@me --state=open --owner=augusthealth`).
3. Update `backlog.js`: new items from the dictation and the refresh, changed states, finished items removed, `today: true` on exactly the items in today's plan. Set `updated`. Keep `priorities` in his words from the latest dictation.
4. Copy yesterday's `today.js` to `archive/<its date>.js`, then write the new `today.js`.
5. Check both files load: `cd ~/Documents/notes/today && node -e 'global.window={};require("./today.js");require("./backlog.js")'`.
6. Reply with the schedule as a table, what was left out and why, and the page path. Give him `http://localhost:4980` and put it on the clipboard. Don't open it. If the server does not answer (`curl -X GET localhost:4980/state.json`), say so and give `open ~/Documents/notes/today/index.html`, where the page works but saves only in his browser.

Choosing what goes in the day:

- His priorities from the dictation come first. Where he gave none, use the ones in `backlog.js`.
- The rules in "Planning my day" in his `CLAUDE.local.md` apply: easy, known-shape work and reviews in the morning, design and thinking in the afternoon, time split evenly between move-ins and integrations judged over the last few days (the archive is the record), his own pull requests never in the review list.
- Work that unblocks something already open (review threads, failing CI, conflicts, an approved pull request waiting to merge) goes ahead of starting new work.
- A work stream with many open review rounds gets a short slot morning and afternoon rather than one block, so a pull request that needs several rounds turns around twice a day.
- Reviews he already started go before reviews not started. A review is finished when its comments are posted.
- Work on his own tooling gets at most the last half hour, unless he says otherwise.
- Leave room: an hour for lunch at 12:00, and no more items in a block than its sizes add up to (sizes are defined in `CLAUDE.local.md`).
- Everything considered and not scheduled goes in `later`, one line each. The page does not show `later` or `log`; they are the record for the next morning's planning.

The plan tells him how to work, not only what to work on (he asked for this on 2026-11-18), and it does so through the shape of the checkboxes, not through prose: the page shows no block-level notes.

- **One at a time**, when his attention is the slow part (reading a drafted review, a decision per item): flat items in the order to do them, each with its own copy button.
- **Started together**, when one session or one command can carry several things (stacked pull requests worked down in order, several reviews started in the background): one parent item whose `copy` is the single command, with the things it covers as its nested `items`, each with its links and its own box to tick as it finishes. The parent's `text` is a short task title ("Address review comments on the three stacked backend PRs", "Review the room picker stack"), never an instruction about sessions ("Start one session that…"): the nesting already says it.
- **A head start**: when the next thing needs slow setup, its parent item's `note` says when to start it ("Start the command when you begin reading the room picker stack").

Breaks are tasks too: an item with `kind: "break"` and a `text` that says what to do in a few words ("Stand up, drink water", "Stretch, a short walk"; vary them, and say "drink", not "refill"), placed after the work it follows: last in a block, or between two long items. About one an hour. Lunch is the only break that is a block of its own (`stream: "Break"`, no items).

## Learning from the day

He leaves notes on the page, one per block and messages in the thread at the bottom ("this took me an hour", "drop this", "wrong directory in this command"), and ticks what he finishes. Both are in `state.json`, under the date: `checked` by item `id`, `notes.entries` by `block:<HH:MM start>` (with `notes.entryTimes`), `notes.messages` as `[{ at, text }]`. In the morning, before planning, and during the day whenever he says he left a note:

1. Read yesterday's (or today's) entry in `state.json` beside that day's `today.js`. A note is new when it is later than the last message in `thread.js`; his times are UTC (they end in `Z`), the ones in `thread.js` are local.
2. Work out each block's done count from `checked` (leaf items, breaks left out).
3. Act on each new note, then answer it in the thread: append to `messages` in `thread.js` one entry per note, `{ at: "<YYYY-MM-DDTHH:MM, now>", about: "<the note's first words, or its block>", text: "<what changed because of it, in a sentence or two: the plan, the backlog, or this skill>" }`. Say what was done, not that it was received; when nothing was changed, say why. Check the file still loads (`node -e 'global.window={};require("./thread.js")'`). One about a single item changes the backlog. One that would apply to other days (how long a kind of task takes, how he wants commands written, what he never wants scheduled, when breaks help) changes this skill, right then, in the section it belongs to: the rule and its why in a clause. Tell him in one line what changed.
   A note about a single item changes the plan or the backlog. One that would apply to other days (how long a kind of task takes, how he wants commands written, what he never wants scheduled, when breaks help) changes this skill, right then, in the section it belongs to: the rule and its why in a clause.
4. Use the done counts: a block that finished 1 of 3 was too full or the wrong work for that hour; size and place today's blocks from that.

## `today.js`

```js
window.TODAY = {
  date: "2026-11-18",
  updated: "09:55",
  blocks: [
    {
      start: "11:15",
      end: "12:00",
      stream: "SELF contacts",
      title: "Slot 1: backend review rounds",
      items: [
        { id: "break-1115", kind: "break", text: "Stand up, refill your water" },
        {
          id: "self-backend-chain",
          text: "Start one session that works down the three stacked backend PRs, then answer what it brings you",
          copy: [{ label: "Copy claude command for all three", text: "cd ~/Projects/august-fullstack && claude \"...\"" }],
          items: [
            {
              id: "self-log-merge",
              text: "Answer 1 open thread, then merge the PR that logs a second SELF contact",
              note: "Approved by jessebutterfield, CI green.",
              status: "merged 11:32 am",
              done: true,
              links: [{ label: "backend 8032", url: "https://github.com/..." }]
            }
          ]
        }
      ]
    }
  ],
  log: [{ time: "10:40", text: "Reviews ran 25 minutes over; SELF contacts slot 1 moved to 11:40" }],
  later: ["one line per thing considered and left out"]
};
```

- Times are 24-hour `HH:MM` in the data; the page shows them as "9:45 am". In text he reads (`note`, `status`, `log`), write times the way the page does.
- Blocks are in order and don't overlap. `stream` matches a stream `name` in `backlog.js` exactly: the page uses it for the tag's colour and its "(2/13)" project count.
- An item's nested `items` have the same shape as an item, one level deep. The page counts progress on the leaves and leaves breaks out of the count.
- `id` is short, kebab-case, unique in the file, and stays the same all day: his ticks are stored against it.
- `text` says what the work is in words. A pull request number or ticket id never stands alone: "Merge the snapshot index PR" with a link labelled `backend 7944`, not "Merge 7944".
- `note` is the state when the plan was written. `status` is what has happened since. `done` ticks the box on the page unless he has ticked or unticked it himself.
- `links`: every pull request, ticket, difit and document the item touches.
- `copy`, on an item, is what he pastes to start the work. Give him the thing itself whenever it can be worked out now, and a prompt only when the work needs a session:
  - Something he only has to do (merge an approved pull request, read a page): no `copy`, just the link and a `text` that says to do it.
  - A query or a shell command: the query or command itself, looked up now. Not a prompt asking a session to write it.
  - Work for a session: a prompt, or better a whole command that starts it. Where one of his skills fits, that is the skill call (`/address-comments <url>`, `/review <n>`, `/manage <url>`).
  - `label` says what is being copied: "Copy SQL", "Copy claude attach command", "Copy /address-comments prompt", "Copy review command: backend (8133)". Never a bare "Copy prompt".
  - Every shell command starts with `cd` to the directory it runs in, from home (`cd ~/Projects/august-fullstack/.august-backend-worktrees/<owner>/<branch> && claude attach <id>`); check the directory exists.
  - A prompt is read by a session that knows nothing: name the repository, the pull request with what it does, the branch, the plan file if there is one, what to produce, and what not to do.
  - For a pull request he will review or self-review, the command is `/review`, which builds the page that says what the change is and lists things to try.

## `backlog.js`

```js
window.BACKLOG = {
  updated: "2026-11-18 09:55",
  priorities: ["Linked Residents (Naomi's top priority; Linear target 2026-11-30)"],
  streams: [
    {
      name: "Linked Residents",
      project: true,
      target: "2026-11-30",
      note: "optional line",
      groups: [
        {
          title: "Approved, closest to merging",
          items: [
            {
              text: "Index the snapshot copy columns",
              state: "Approved. No conflicts, no failing checks.",
              next: "Confirm the indexes exist, merge.",
              kind: "easy",
              size: "x-small",
              today: true,
              links: [{ label: "backend 7944", url: "https://github.com/..." }]
            }
          ]
        }
      ]
    }
  ]
};
```

- One stream per project of his, plus `Reviews` (teammates' pull requests) and `Tooling`. `project: true` on the long-running projects, with `done` and `total` as numbers: the page shows them on the stream's tag as "(2/13)", tasks completed out of all the project's tasks. Reviews and Tooling are `project: false` and have neither.
- One item per pull request or piece of work, so the counts mean something. An item that is finished is removed, not marked, and the stream's `done` goes up by one; a new item raises `total`.
- `kind` is `easy` (known shape, fits a morning), `thought` (design or judgment, fits an afternoon), or `wait` (nothing to do until someone else acts). `size` is the agent's guess, in the sizes from `CLAUDE.local.md`, or empty.

## During the day: any session, any repository

When work in your session changes the state of something in the plan, record it. Read the file first, change only the lines that are yours, use the Edit tool.

| What happened | What to write |
|---|---|
| A planned item is finished | In `today.js`: `done: true` on the item, and a `status` saying how it ended ("merged 10:12 am"). In `backlog.js`: remove the item and add one to the stream's `done`, or rewrite the item if part remains. |
| An item moved forward but isn't finished, or now waits on someone | `status` on the item in `today.js`, and `state` and `next` on the item in `backlog.js`. |
| A block ran long or short, or was skipped | An entry in `log` with the time and what happened. Change later blocks' times only when he asks for the day to be re-planned. |
| New work appeared (a request from a teammate, a new ticket, a follow-up found while working) | An item in the matching stream of `backlog.js`. Not in today's blocks unless he says so. |
| He asks to re-plan the rest of the day, or to move or drop an item | Rewrite the blocks from now on, keep finished items where they are, add a `log` entry saying why, and bring `today: true` in `backlog.js` in line. |

After any change, set `updated` in the file you changed and run the load check from the morning steps.

His own ticks are in `state.json` under today's date, not in `today.js`, so read both before treating an item as open. When he has the page open as a file and not through the server, ticks stay in his browser: check GitHub or ask.

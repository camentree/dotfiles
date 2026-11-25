---
name: today
description: Camen's day plan - the hour-by-hour page and the backlog at ~/Documents/notes/today/. Use it in the morning when he dictates what he is thinking about ("here's what I'm thinking about today", "plan my day") to rebuild the backlog and the day's plan, when he says "/today", "refresh my day" or "re-plan" with nothing else to re-run it from the backlog, calendar and GitHub, and use it from any session during the day to record that a planned item finished, moved, ran long, or changed state, or to add something to the backlog.
---

# Today

Everything is in `~/Documents/notes/today/`. Agents write the two data files; Camen reads them through the page.

| File | What it is |
|---|---|
| `today.js` | Today's schedule: time blocks, the items in each, links, and things to copy. Rewritten every morning. |
| `backlog.js` | Everything he could be working on, by work stream, with the state and next step of each. Lasts across days. |
| `index.html` | The page: Plan, Backlog, Log and PRs tabs; re-reads the data files every minute. It is a link to `page/index.html` beside this skill, so its history is in the dotfiles repo. He settled its look over a day of recordings on 2026-11-18: planning never touches it, and it changes only when he asks for a change to the page itself. Every block's row is grey except the one happening now and any he has opened, and the current block has extra space above and below, so it stands out (2026-11-19). Text fields match the text around them; only touch screens get 16px, where iOS zooms into anything smaller. The arrows in the header step through the last 7 days that have an archive (asked for 2026-11-23): a past day shows its blocks, backlog snapshot, ticks, Log entries and water and standing counts read-only, and "Back to today" returns. It loads archives as scripts, catching their `window.TODAY` and `window.BACKLOG` by the script's `data-past-date`, so it works served or opened as a file. The browser tab title is always exactly "Today", whatever the day, tab or block (he asked on 2026-11-23). Its icon is a calendar page in the page's accent colour: an inline SVG (lighter in dark mode) and `page/favicon.png` (64px, linked from this folder as `favicon.png`) for browsers that skip SVG icons. The PRs tab (asked for 2026-11-23, since valinor made it unclear who reviews what) is two columns by who acts, You (Needs me, Accepted, Drafted) and Waiting on others (Needs review, Can be reviewed, Wait to review, Blocked), each pull request one unboxed line of number, truncated title, one short note and stack position sharing vertical lines down a column (stack runs marked by a rule in the left gutter), centred up to 1180px and stacked below 900px, because the seven-column card board was hard to read (2026-11-23). Rows in Needs review and Can be reviewed start with a tick that records he asked; "Copy for Jesse" and "Copy for Josh" sit on the Needs review heading and list the not-yet-asked rows. The tab is hidden on past days. |
| `state.json` | His ticks and Log entries, by date, and under `asked` the pull requests he has asked for a review of (`{ "<pr url>": { "<reviewer login>": "<when>" } }`, kept across days), written by the page. Read it; never write it. |
| `prs.js` | His open valinor pull requests as `window.PRS`, written by `node ~/.claude/scripts/my-prs.cjs` (`--json` prints the same): area from the changed paths (backend needs Jesse, frontend Josh; generated protos TypeScript and Slick tables don't count), stack, checks, threads split into person and bot, each reviewer's latest review, `column`, `depth` and the card's `notes`. Column, first match: draft; needs him (person threads, a review not answered by a push, really failing checks); blocked (accepted but the do-not-merge label, for a frontend one its backend half, the pull request below it or a declared dependency is unmerged); accepted; otherwise by depth, its place among the not-yet-accepted pull requests it sits on, counting both the one below it in its stack and any it declares in its description ("do not merge until #100", "depends on", "blocked by", "requires", "merge after", "deployable after"; `dependsOn`), since on 2026-11-23 valinor 86 sat in Needs review though its description waited on valinor 100, 7/10 in a stack: 1 Needs review, up to `reviewDepthLimit` (3) Can be reviewed, beyond that Wait to review, so he and the reviewers aren't overwhelmed. The "Fail for Do Not Merge" check and cancelled runs don't count as failing. An `asked` mark counts until that reviewer reviews again. |
| `thread.js` | The agents' side of the page's Log tab. Agents append to it. |
| `server.cjs` | Serves the folder at `http://localhost:4980` and writes `state.json` (`PUT /state` for a day's ticks and Log, `PUT /asked` for one asked mark). A launchd agent (`today-page`, in the dotfiles' `user.nix`) keeps it running. The file itself lives only in this folder, not in the dotfiles repo. The page's "Re-plan the day" button posts to `/replan`, which starts a background session in `~/Documents/notes` that runs this skill. |
| `archive/` | Earlier days' plans as `<date>.js` and the backlog as it stood that evening as `<date>.backlog.js`, written only by `node ~/.claude/scripts/today-archive.cjs` (backlog snapshots start 2026-11-23). The page reads them for its past days. |

These files replaced `~/Documents/notes/organize.md` on 2026-11-20: the organize skill is gone, the review, manage and find-reviews skills and his work instructions (`~/CLAUDE.local.md`) record progress here, and nothing reads or writes organize.md any more.

## What agents do and don't do here

Every run of this skill (morning, refresh, during the day) starts one worker at the start: the Agent tool with `subagent_type: "worker"` and `model: "opus"`, briefed once with `worker-brief.md` beside this skill (he asked for this on 2026-11-23, so groundwork is done before he reaches it). Every change to code, scripts, the page or this skill goes to the worker, not made by the session; the session reviews what comes back and waits for it before telling him the work is done. The session writes the data files itself.

The worker also does groundwork on his own open pull requests when the refresh turns it up, one thing at a time in the day plan's order:
- a conflict with the base branch: `git merge` the base in, resolve, push;
- a failing check: read the log, tell flaky from real, fix with a new commit, push, watch the checks;
- a stale branch under a stack: merge the branch below in, push;
- a worktree he will need: `wk <branch>` from `~/Projects/valinor`.

Its hard limits, which are his to do:
- never rebase, amend, squash or force-push;
- never merge a pull request, mark one ready, request reviewers, post or resolve review threads, or comment on GitHub, Linear or Slack;
- never touch a teammate's pull request or branch;
- never decide a design question: leave it for him with what each option costs;
- no CloudWatch queries.

What it did goes where he looks: `status` (and `stage`) on the item in `today.js`, `state` and `next` in `backlog.js`, and one `thread.js` message per piece of work saying what it found and what it pushed, with the commit link.

Anything outside that groundwork he starts himself when its slot arrives, from the copy buttons on the page: no app servers, difit or code reviews ahead of a slot, and no browser tabs other than the day page in step 6. Decide the order, the grouping and what to leave out yourself; don't ask him to pick. Moving or dropping an item is something he tells an agent to do; the page has no editing.

Describe items neutrally. No "urgent", "must", "should".

Keep this skill current; any agent running or touching it follows this:
- When it learns something that changes how a later plan or the page is made (a preference he states, a correction, a rule for the page's look, a fact about his tools), write it into the section it belongs to right then, the rule and its why in a clause, editing an existing line over adding one, and tell him in one line: the skill is the only memory the next morning's session has.
- When it finds something wrong or missing in the skill, page or scripts, have the worker fix it in that same run if it matters, and otherwise drop it: nothing is parked in a list, because he would rather not have one lying around (2026-11-23).

## Morning: build the day from his dictation

He dictates loosely what is on his mind. Some of it is work to do today, some is not worth today's time, and sorting that out is the job.

1. Start the worker (see above). Run `node ~/.claude/scripts/today-archive.cjs`, which copies the earlier day's `today.js` and `backlog.js` into `archive/` before anything is rewritten, then read `backlog.js` and that day's plan.
2. Refresh the facts, in parallel (when `gh` is not found in the session's own shell, put `/etc/profiles/per-user/camen/bin` at the front of `PATH`):
   - Linear: issues assigned to him in started, unstarted and backlog states, and projects he is a member of.
   - GitHub, his open pull requests with review decision, mergeable state, CI state, unresolved thread count and base branch (one GraphQL search, `is:pr is:open author:@me org:augusthealth`).
   - `node ~/.claude/scripts/my-prs.cjs`, which rewrites `prs.js` for the PRs tab; its `column` per pull request says where each one stands.
   - The `Reviews` stream, rebuilt from `node ~/.claude/scripts/review-queue.cjs` (JSON, one entry per pull request, across valinor, Experimental-Tools, and august-backend and august-frontend while those still have open ones; a valinor entry with `migratedFrom` is that old pull request moved by `bin/migrate-pr`, and replaces it). The script applies his rules of 2026-11-18: a pull request is listed only when it asked for him by name or for the move-ins team; one that asked for move-ins and already has a review from Jesse or Josh is left out; one he has reviewed stays until it merges, marked as not needing him unless the author pushed since. Write each entry as an item with `summary` (who was asked, who reviewed and how, or "Doesn't need you: ...") and `waiting: true` when `needsMe` is false; only `needsMe` entries go into a day's plan.
   - His meetings, from Apple Calendar (he left them out of the first plan and had to ask): `swift ~/.claude/scripts/calendar-day.swift` prints `start | end | attending or declined | calendar | title` for today, or for a `YYYY-MM-DD` argument. Meetings he has not declined go in `stream: "Meetings"` blocks with an empty `title`: back-to-back meetings share one block spanning them, and each meeting is an item he ticks (`{ id: "meeting-1400", text: "2:00 pm Engineering Weekly" }`). Work is placed around them; all-day entries are other people's time off and are left out. The script leaves out the `Sarit` calendar: it is his partner's, and its "therapy" entry was once planned as his meeting (2026-11-23).
3. Update `backlog.js`: new items from the dictation and the refresh, changed states, finished items removed, `today: true` on exactly the items in today's plan. Set `updated`. Keep `priorities` in his words from the latest dictation.
4. Write the new `today.js` (step 1 archived the old one; `today-check.cjs` reports a plan whose previous day has Log or tick entries but no archive).
5. Run `node ~/.claude/scripts/today-check.cjs` and fix everything it prints. It checks that the files fit the page as he settled it (block and item shape, meetings, no break tasks, command and label rules, links that let ticks sync). A plan is not finished until it prints that the files fit.
6. Reply with the schedule as a table, what was left out and why, and the page path. Give him `http://localhost:4980` and put it on the clipboard. Then open it in Safari (he asked on 2026-11-20, to have the day beside his work): with `osascript`, a new window holding `http://localhost:4980` and a second tab on `https://parallax.smallworkshop.dev/fitness`, the day page the tab showing, bounds `{0, 0, 100, <screen height>}` so Safari clamps it to its narrowest at the left edge. If the server does not answer (`curl -X GET localhost:4980/state.json`), say so and give `open ~/Documents/notes/today/index.html`, where the page works but saves only in his browser.

Choosing what goes in the day:

- His priorities from the dictation come first. Where he gave none, use the ones in `backlog.js`.
- The rules in "Planning my day" in his `CLAUDE.local.md` apply: easy, known-shape work and reviews in the morning, design and thinking in the afternoon, all of his time on move-ins, his own pull requests never in the review list.
- Work that unblocks something already open (review threads, failing CI, conflicts, an approved pull request waiting to merge) goes ahead of starting new work.
- When the PRs tab has cards in Needs review or Can be reviewed not yet marked asked, the morning gets one small task per reviewer, placed early so reviews run while he works: "Ask Jesse to review N backend PRs", its `copy` the same message as the tab's "Copy message for Jesse" (he asked on 2026-11-23 for help getting reviews, since valinor made it unclear who reviews what).
- An approved pull request is a merge task only when everything it depends on has merged (the backend half of a frontend/backend pair, the pull request under it in a stack); otherwise it is `kind: "wait"` and `waiting: true` in the backlog, left out of the day, and the plan's task is the thing it waits on. A pair shares a feature title or a Linear ticket across a backend and a frontend pull request. On 2026-11-23 a plan had him merge the frontend half of copying "Other" uploads to a linked resident while its backend half was unapproved, and the frontend needs the backend.
- A work stream with many open review rounds gets a short slot morning and afternoon rather than one block, so a pull request that needs several rounds turns around twice a day.
- The page shows a block as its start time and `stream` only ("4:30 pm SELF contacts (0/2)"); the `title` appears once he opens it. Ticks sync between the Plan and Backlog tabs for items that share a pull request link, so give both the same PR `url`.
- A block's `title` says the work in plain words ("Answer review comments on the backend PRs"), never a planner's label like "Slot 1": he could not tell what a slot was.
- Posting a review that is already drafted takes him 40 to 60 minutes when the pull request is large, not 20: on 2026-11-18 three drafted reviews took two hours and pushed out the block after them. Plan one large or two small per hour.
- Reviews he already started go before reviews not started. A review is finished when its comments are posted.
- Work on his own tooling gets at most the last half hour, unless he says otherwise.
- Leave room: an hour for lunch at 12:00, and no more items in a block than its sizes add up to (sizes are defined in `CLAUDE.local.md`). Work a session does still costs his time, to start it and to check each result: size a batch by the count of things he checks, and start long-running sessions before lunch or a meeting so they overlap it (on 2026-11-20 a plan gave moving 21 pull requests between repositories three hours and he said it missed the time that takes).
- Everything considered and not scheduled goes in `later`, one line each. The page does not show `later` or `log`; they are the record for the next morning's planning.

The plan tells him how to work, not only what to work on (he asked for this on 2026-11-18), and it does so through the shape of the checkboxes, not through prose: the page shows no block-level notes.

- **One at a time**, when his attention is the slow part (reading a drafted review, a decision per item): flat items in the order to do them, each with its own copy button.
- **Started together**, when one session or one command can carry several things (stacked pull requests worked down in order, several reviews started in the background): one parent item whose `copy` is the single command, with the things it covers as its nested `items`, each with its links and its own box to tick as it finishes. The parent's `text` is a short task title ("Address review comments on the three stacked backend PRs", "Review the room picker stack"), never an instruction about sessions ("Start one session that…"): the nesting already says it.
- **A head start**: when the next thing needs slow setup, its parent item's `note` says when to start it ("Start the command when you begin reading the room picker stack").

No break tasks: the page's header counts water and standing through the day (he asked for that in place of "stand up, drink water" items on 2026-11-18), so never write `kind: "break"` items. Lunch is the only break in the plan, a block of its own (`stream: "Break"`, no items, its `title` shown as the row), except on a day he says he is on edge or finds multitasking hard: then work blocks of 30 to 40 minutes, one piece of work each, with a 10-minute `Break` block between titled for standing, moving and checking in with his body (he asked for this on 2026-11-19).

Unfinished work from an earlier block stays on the page in its block, and the page's refresh button asks for a re-plan. On a re-plan, or the next morning: unfinished items that unblock something (an approved pull request waiting to merge, review threads on a stack others wait on) go first in the next free block; the rest compete with the remaining plan by his priorities, and what no longer fits goes back to the backlog with a line in `log` saying so. Don't stack carried-over work on top of a full block: move something out.

## Refresh: no dictation

The page's refresh button (and "refresh my day", "re-plan") runs this with nothing from him to go on. Look at `date` in `today.js`:

- **An earlier day**: build today's plan as in the morning steps, with the priorities already in `backlog.js` standing in for a dictation, yesterday's unfinished items carried over by the rule above, and his Log entries since the last plan read first.
- **Today**: keep what is done and what is past, and rewrite the blocks from now on: refresh GitHub (with `my-prs.cjs`), Linear and the calendar, read his ticks and Log entries in `state.json`, carry over what is unfinished, and drop to the backlog what no longer fits. Add a `log` line saying what moved.

Either way, finish by answering in `thread.js` with what changed, in two or three lines. Nobody is watching the session, so don't ask anything; decide.

## The Log

The page's third tab is the Log (he calls it the log or log book; it is not the `log` list in `today.js`), shown as a conversation between him and the agents. He writes updates into it: where a ticket stands, what he is thinking, how long something took, what to change in the plan. It is context as much as feedback, so read it whenever this skill runs, and any session that wants to know where a piece of his work stands can read it too.

- His entries are in `state.json` under the date he wrote them: `notes.messages` as `[{ at, text, about }]`. `at` is UTC (ends in `Z`). `about` is absent for a general entry, otherwise `{ kind: "task" | "block" | "stream" | "backlog", id, label }`: a task's `id` is the item `id` in that day's `today.js`, a block's is `block:<HH:MM start>`, a stream's is its name in `backlog.js`, and a backlog item's is its first link's url (or its text when it has no link), with `stream` beside it. `label` is the text he saw.
- The agents' side is `thread.js`: `messages` as `[{ at: "<YYYY-MM-DDTHH:MM, local>", about: "<the label of the entry answered, or a few words>", text }]`.
- An entry is new when it is later than the last message in `thread.js`.

Each time this skill runs, and whenever he says he wrote something:

1. Read the new entries, and the last few days' entries about any stream being planned.
2. Carry what an entry says into the data: a status update on a task goes into that item's `status` in `today.js` and its `state`/`next` in `backlog.js`; "drop this" or "this moved" changes the plan. An entry that would apply to other days (how long a kind of task takes, how he wants commands written, what he never wants scheduled, when breaks help) changes this skill, right then, in the section it belongs to: the rule and its why in a clause.
3. Answer in the thread, one message per entry that led to something: what changed because of it, in a sentence or two, or the answer when he asked something. Say what was done, not that it was received. An entry that is only him thinking aloud needs no reply. Check the file still loads (`node -e 'global.window={};require("./thread.js")'`).
4. Tell him in one line what changed.

## Learning from the day

In the morning, before planning:

1. Read yesterday's `checked` in `state.json` (by item `id`) beside yesterday's plan in `archive/`. A key `backlog:<first link url, or the item's text>` is a backlog item he ticked off himself on the Backlog tab: confirm it against GitHub or Linear, then remove the item from `backlog.js` and add one to its stream's `done`.
2. Work out each block's done count (leaf items). `notes.trackers` in `state.json` has the times he logged water and standing.
3. Use the done counts: a block that finished 1 of 3 was too full or the wrong work for that hour; size and place today's blocks from that.

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
      title: "Answer review comments on the backend PRs",
      items: [
        {
          id: "self-backend-chain",
          text: "Address review comments on the three stacked backend PRs",
          copy: [{ label: "Copy claude command for all three", text: "cd ~/Projects/valinor && claude \"...\"" }],
          items: [
            {
              id: "self-log-merge",
              text: "Answer 1 open thread, then merge the PR that logs a second SELF contact",
              note: "Approved by jessebutterfield, CI green.",
              status: "merged 11:32 am",
              done: true,
              links: [{ label: "valinor 8032", url: "https://github.com/..." }]
            }
          ]
        }
      ]
    },
    { start: "12:00", end: "13:00", stream: "Break", title: "Lunch, away from the desk", items: [] },
    {
      start: "13:45",
      end: "15:00",
      stream: "Meetings",
      title: "",
      items: [
        { id: "meeting-1345", text: "1:45 pm Webform Triggers tb" },
        { id: "meeting-1400", text: "2:00 pm Engineering Weekly" }
      ]
    }
  ],
  log: [{ time: "10:40", text: "Reviews ran 25 minutes over; SELF contacts backend work moved to 11:40" }],
  later: ["one line per thing considered and left out"]
};
```

- Times are 24-hour `HH:MM` in the data; the page shows them as "9:45 am". In text he reads (`note`, `status`, `log`), write times the way the page does.
- Blocks are in order and don't overlap. `stream` matches a stream `name` in `backlog.js` exactly (or is `Meetings` or `Break`): it is the block's name on the page.
- An item's nested `items` have the same shape as an item, one level deep. The block's "(1/3)" counts its top-level items; a parent ticks itself when all its children are ticked. A task row shows only its title, links and first copy button; `note`, `status` and the rest open when he clicks the title, so keep titles self-sufficient.
- `stage`, on any item in `today.js` or `backlog.js` that is one of his own tickets or pull requests (not reviews of others' work, meetings or setup steps), draws a small symbol before the title so he can read where it stands at a glance (asked for 2026-11-19; symbols, not colour-coded circles, because colours were hard to remember): dashed circle, pencil, eye, hourglass, speech bubble, check, merge arrow, in order of `todo` (not started), `dev`, `self-review` (a draft not yet self-reviewed or being self-reviewed), `review` (ready, waiting on reviewers), `comments` (review threads open for him), `approved`, `merged`. Set it from GitHub on every refresh, and to `merged` with `done: true` when a pull request merges; on a parent with nested items, put it on the children (`today-check.cjs` reports a parent that carries one).
- `id` is short, kebab-case, unique in the file, and stays the same all day: his ticks are stored against it.
- `text` says what the work is in words. A pull request number or ticket id never stands alone: "Merge the snapshot index PR" with a link labelled by repository and number, `valinor 7944`, not "Merge 7944".
- `note` is the state when the plan was written. `status` is what has happened since. `done` ticks the box on the page unless he has ticked or unticked it himself.
- `links`: every pull request, ticket, difit and document the item touches, the one the item is about first: `today-set.cjs` matches on the first link only, so a ticket item that mentions a pull request is not finished with it.
- `date` is the day the plan is for. Before a new day's plan replaces it, `today-archive.cjs` copies it to `archive/<date>.js` with the backlog beside it, which is what the page shows for past days.
- `copy`, on an item, is what he pastes to start the work. Give him the thing itself whenever it can be worked out now, and a prompt only when the work needs a session:
  - Something he only has to do (merge an approved pull request, read a page): no `copy`, just the link and a `text` that says to do it.
  - A query or a shell command: the query or command itself, looked up now. Not a prompt asking a session to write it.
  - Work for a session: a prompt, or better a whole command that starts it. Where one of his skills fits, that is the skill call (`/address-comments <url>`, `/review <n>`, `/manage <url>`).
  - A command that starts one session is a plain `claude --model <model> -n "<name>" "<prompt>"`; `--bg` only when one command starts several sessions (he said on 2026-11-20 that a single session doesn't need backgrounding).
  - Every `claude` command that starts a session names its model right after `claude` (he asked on 2026-11-23; `today-check.cjs` reports one without): `fable` for design and judgment where a miss is costly (a self-review with open decisions, a review of a teammate's large or cross-team change, planning a ticket), `opus` for work with a known shape (addressing a person's review threads, implementing a clear ticket, an ordinary review), `sonnet` for mechanical work (review-bot threads, a re-run or lint fix, renames, moving a worktree).
  - `label` says what is being copied: "Copy SQL", "Copy claude attach command", "Copy /address-comments prompt", "Copy review command: valinor (8133)". Never a bare "Copy prompt".
  - Every shell command starts with `cd` to the directory it runs in, from home (`cd ~/Projects/.valinor-worktrees/<owner>/<branch> && claude attach <id>`); check the directory exists.
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
              links: [{ label: "valinor 7944", url: "https://github.com/..." }]
            }
          ]
        }
      ]
    }
  ]
};
```

- An item's optional `summary` is one short line always shown under its title; `waiting: true` greys the item out.
- One stream per project of his, plus `Reviews` (teammates' pull requests) and `Tooling`. `project: true` on the long-running projects, with `done` and `total` as numbers: the page shows them as a progress bar and "2/13", tasks completed out of all the project's tasks. Reviews and Tooling are `project: false` and have neither. The page shows items only: group titles, `priorities`, `kind`, `size` and `today` are for planning and are not displayed.
- One item per pull request or piece of work, so the counts mean something. An item that is finished is removed, not marked, and the stream's `done` goes up by one; a new item raises `total`.
- `kind` is `easy` (known shape, fits a morning), `thought` (design or judgment, fits an afternoon), or `wait` (nothing to do until someone else acts). `size` is the agent's guess, in the sizes from `CLAUDE.local.md`, or empty.

## During the day: any session, any repository

When work in your session changes the state of something in the plan, record it. Read the file first, change only the lines that are yours, use the Edit tool.

For the common case, one of his tickets or pull requests changing stage, one command sets it in both files and runs the check (he asked on 2026-11-20 for a way to update the status symbol):

```bash
node ~/.claude/scripts/today-set.cjs <pull request url, ticket url, or today.js item id> [--stage todo|dev|self-review|review|comments|approved|merged] [--status "<what happened>"] [--next "<next step>"] [--done [--keep]]
```

It finds the items whose first link is that url (or the `today.js` item with that id, and the backlog items sharing its first link) and sets `stage` in both files (never on an item with nested items), `status` and `done` in `today.js`, and `state` (from `--status`) and `next` in `backlog.js`. A url is the whole piece of work: with `--done` it also removes the backlog item and adds one to its stream's `done`, unless `--keep` says part remains. An id is one step: `--done` ticks only that item. When a url is the first link of several `today.js` items, `--status` and `--done` refuse and list their ids, so a step is never finished by its pull request's url. It rewrites both files in JSON layout, so Read a file again before an Edit that follows it.

| What happened | What to write |
|---|---|
| A planned item is finished | In `today.js`: `done: true` on the item, and a `status` saying how it ended ("merged 10:12 am"). In `backlog.js`: remove the item and add one to the stream's `done`, or rewrite the item if part remains. `today-set.cjs <url> --done --status "..."` does both; add `--keep` when part remains. |
| An item moved forward but isn't finished, or now waits on someone | `status` on the item in `today.js`, and `state` and `next` on the item in `backlog.js`. |
| A block ran long or short, or was skipped | An entry in `log` with the time and what happened. Change later blocks' times only when he asks for the day to be re-planned. |
| You want to know where a piece of his work stands, or what he thinks about it | Read the Log (see "The Log"): his entries about that task or stream in `state.json`. Answer in `thread.js` only when an entry asked for something you did. |
| New work appeared (a request from a teammate, a new ticket, a follow-up found while working) | An item in the matching stream of `backlog.js`. Not in today's blocks unless he says so. |
| He asks to re-plan the rest of the day, or to move or drop an item | Rewrite the blocks from now on, keep finished items where they are, add a `log` entry saying why, and bring `today: true` in `backlog.js` in line. |

After any change, set `updated` in the file you changed and run `node ~/.claude/scripts/today-check.cjs`.

His own ticks are in `state.json` under today's date, not in `today.js`, so read both before treating an item as open. When he has the page open as a file and not through the server, ticks stay in his browser: check GitHub or ask.

---
name: find-reviews
description: Rebuild the pull request review queue, the Reviews stream of the day plan's backlog at ~/Documents/notes/today/backlog.js - finds open PRs in valinor and Experimental-Tools, and in august-backend and august-frontend while those still have open ones, that Camen should review or re-review, and opens the ones that need him in Chrome in a tab group named "reviews". Use when he asks what PRs there are to review or act on, asks to refresh the review list, or on the daily scheduled run.
---

# Find reviews

Runs unattended on a schedule as well as on request, so it never asks questions: it decides, writes, and reports what it did in a few lines.

The queue lives in the day plan, as the `Reviews` stream of `~/Documents/notes/today/backlog.js` (he moved it off organize.md on 2026-11-20). The today skill describes that file; read its `backlog.js` section before writing.

## 1. Collect

`node ~/.claude/scripts/review-queue.cjs` prints JSON, one entry per pull request: `repository number title url author asked reviews needsMe why`. The script holds his rules for what is listed (asked for him by name or for the move-ins team; left out once Jesse or Josh has reviewed a move-ins request; one he reviewed stays until it merges, not needing him unless the author pushed since) and follows a pull request moved to valinor by `bin/migrate-pr`. Change the rules there, not here.

## 2. Write the Reviews stream

Read `backlog.js`. Replace only the items of the `Reviews` stream; leave every other stream as it is.

One item per entry:

```js
{
  text: "<author login>: <what the pull request does, in plain words>",
  summary: "<who was asked>. <who reviewed and how>.",
  kind: "easy",
  size: "",
  links: [{ label: "<backend|frontend|valinor|tools> <number>", url: "<url>" }]
}
```

- `needsMe: false`: `summary` starts "Doesn't need you: " with the script's `why`, plus `waiting: true` and `kind: "wait"`.
- Order: entries that need him first, re-reviews (the author pushed since his review) ahead of new ones, then oldest first; the waiting ones last.
- An item already there keeps its `today` flag and anything he said about it in the Log (the today skill's "The Log").
- An item whose pull request is no longer in the script's output is removed.

Set `updated`, then run `node ~/.claude/scripts/today-check.cjs` and fix what it prints. Don't touch `today.js`: what goes into a day is the today skill's call.

## 3. Chrome

The tabs to show are the first five entries that need him, never the waiting ones.

- Close tabs whose url is a PR from this run's output but not among the five. Never close any other tab: his own PRs and other pages stay.
- Open the missing ones with `bash ~/.claude/scripts/chrome-tab-group.sh open <urls>`, which hands focus back to his app afterwards. `open -a "Google Chrome" <many urls>` times out (error -1712).
- Once they're open, group them with the Tab Grouper extension: `bash ~/.claude/scripts/chrome-tab-group.sh match=<url> match=<url> … "title=reviews"`. Check with `bash ~/.claude/scripts/chrome-tab-group.sh list`.

Don't use Claude in Chrome here: its tabs land in its own "Claude (MCP)" group.

## 4. Report

Lead with the ones that need him, one line each: author, what the PR does in plain words, and why it is listed (re-review, asked for him, asked for move-ins). Then one line on what moved: added, dropped, closed tabs.

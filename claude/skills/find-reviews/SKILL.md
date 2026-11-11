---
name: find-reviews
description: Rebuild the pull request review queue in ~/Documents/notes/organize.md under "## Reviews" - finds open PRs in august-backend, august-frontend and Experimental-Tools that Camen should review or re-review, ranks them, puts at most five in "## Reviews" and the rest in "### Backlog", and opens the five in Chrome in a tab group named "reviews". Use when he asks what PRs there are to review or act on, asks to refresh the review list, or on the daily scheduled run.
---

# Find reviews

Runs unattended on a schedule as well as on request, so it never asks questions: it decides, writes, and reports what it did in a few lines.

Org: `augusthealth`. Repos: `august-backend`, `august-frontend`, `Experimental-Tools`. Camen's login: `camentree`. Teammates on move-ins: `jessebutterfield` (Jesse), `jkjustjoshing` (Josh Kramer).

## 1. Collect

One GraphQL query per repo, open PRs, first 100. Per PR fetch: `number title url isDraft headRefName author{login} reviewDecision`, `labels(first:10)`, `reviewRequests(first:15)` (user `login`, team `slug`), `latestReviews(first:20){author state}`, `reviews(first:50, author:"camentree"){state submittedAt}`, `reviewThreads(first:100){isResolved comments(first:1){author}}`, `comments(last:50){author createdAt body}`, `reviews(last:30){author body}` for mentions, `commits(last:1){commit{committedDate}}`, `timelineItems(last:5, itemTypes:[HEAD_REF_FORCE_PUSHED_EVENT]){createdAt}`. Write the responses to the scratchpad and work with `jq`.

`gh pr list --json` with `reviews`/`commits` fails on these repos (GraphQL node limit), so don't use it.

## 2. Filter

Skip: drafts, authors `camentree` or starting `app/` (bots).

Keep a PR when any of these holds:
- review requested from `camentree` or the `move-ins` team
- label `move-ins` or `integrations`, title containing `(move-ins)` or `(integrations)`, or a `MOV-`/`INT-` ticket in the branch or title (any case)
- `camentree` has reviewed or commented on it, or is `@camentree`-mentioned in a comment or review body

Then drop a kept PR when `reviewDecision` is `APPROVED` and `camentree` has no unresolved review threads on it, unless someone other than him `@camentree`-mentioned him and he hasn't replied since.

## 3. Status

The marks are the organize skill's; read it. Set them from Camen's own reviews, not the PR's overall state:

- 💬: he hasn't reviewed, he has a `PENDING` review, or the author pushed after his non-approving review
- 💬 ❓: he reviewed without approving, and the author hasn't pushed since
- 💬 ✅: he approved

## 4. Rank

Highest first:
1. Re-review: he reviewed or commented, and the latest commit or force push is later than his latest review or comment
2. Someone asked him a question he hasn't answered (an unanswered `@camentree` mention)
3. `move-ins` label
4. Backend over frontend over Experimental-Tools (include all of them)
5. Not already reviewed by Jesse or Josh Kramer (a `latestReviews` entry or a comment from them puts it lower)

Ties: oldest PR first.

## 5. Write organize.md

Read `~/Documents/notes/organize.md` first. Replace only the lines between `## Reviews` and `### Backlog`, and between `### Backlog` and the next `## ` heading. Leave every other section as it is.

PRs already listed under `## Reviews` that still qualify stay there, in place. Fill the remaining slots, to five, from the top of the ranking. Everything else goes under `### Backlog`, in rank order.

Line format, one per PR, a blank line after the heading:

```
- [ ] <status> (<author login>) [<PR title>](<url>) `<branch>`
```

## 6. Chrome

The tabs to show are the PRs under `## Reviews`, never the backlog.

- Close tabs whose url is a PR from this run's candidate list but not under `## Reviews`. Never close any other tab: his own PRs and other pages stay.
- Open each missing one with `osascript -e 'tell application "Google Chrome" to tell window 1 to make new tab with properties {URL:"<url>"}'`, one call per url. `open -a "Google Chrome" <many urls>` times out (error -1712).
- Once they're open, group them with the Tab Grouper extension: `bash ~/.claude/scripts/chrome-tab-group.sh match=<url> match=<url> … "title=reviews"`. Check with `bash ~/.claude/scripts/chrome-tab-group.sh list`.

Don't use Claude in Chrome here: its tabs land in its own "Claude (MCP)" group.

## 7. Report

Lead with the five, one line each: status, author, what the PR does in plain words, and why it ranks there (re-review, question for him, move-ins). Then one line on what moved: added, dropped, closed tabs.

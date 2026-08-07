---
name: todo
description: Maintains ~/Documents/notes/ToDo.md. A Linear ID or URL appends that ticket to Up Next; a time and title like "12pm josh" adds a meeting in time order; the word "schedule" rebuilds the Schedule block alone; no argument refreshes the whole day, rewriting Meetings and Schedule and merging Reviewable PRs and Up Next so checked-off entries drop and new ones append. Camen owns the To Do section and this skill never writes it.
---

# Todo

The argument decides the mode.

| Invocation | Effect |
|---|---|
| `/todo` | Refresh the whole day |
| `/todo INT-626` | Append that ticket to `### Up Next` |
| `/todo <linear-url>` | Same, from a URL |
| `/todo 12pm josh` | Add a meeting, kept in time order |
| `/todo schedule` | Rebuild `### Schedule` only |

Recognising the mode: the literal word `schedule`; else a Linear identifier (`ABC-123`) or a `linear.app` URL; else anything starting with a time (`12pm`, `1200`, `1:30pm`, `9am`) is a meeting. Anything else, ask rather than guess.

| Section | `/todo` | `/todo <id>` | `/todo <time> <title>` | `/todo schedule` |
|---|---|---|---|---|
| `### To Do` | untouched | untouched | untouched | untouched |
| `### Up Next` | merged | one entry appended | untouched | untouched |
| `### Meetings` | rewritten | untouched | one entry inserted | untouched |
| `### Reviewable PRs` | merged | untouched | untouched | untouched |
| `### Schedule` | rewritten | untouched | untouched | rewritten |

Merged means checked-off `[x]` entries drop and new ones append. Rewritten means regenerated from the current hour on, preserving earlier `[x]` rows.

Adding a meeting deliberately leaves `### Schedule` alone — run `/todo schedule` when you want the day re-laid around it.

Camen owns `### To Do`. This skill never writes it — he promotes entries up from Up Next himself.

The file is `~/Documents/notes/ToDo.md`. Read it first, always. Preserve every section not named above, verbatim.

## File shape

```
## Today — YYYY-MM-DD

### To Do
### Up Next
### Meetings
### Reviewable PRs
### Schedule
```

Times are 12-hour, zero-padded, no colon: `0900`, `1200`, `0130`.

## Mode 1 — add a ticket

Fetch the issue with `mcp__linear__get_issue`. Write one entry at the end of `### Up Next`:

```
- [(prefix) (type) Title](linear-url)
    - priority: high
    - size: small
```

Then, only when they exist on the issue, append:

```
    - `branch-name`
    - [ ] merge [PR](github-url)
```

Branch name comes from the issue's `gitBranchName`. Only add the PR line if an open PR already references that branch.

**prefix** — from the issue's Linear team:

| Team | Prefix |
|---|---|
| Integrations & Insights (INT) | `ext` |
| Billing / Move-ins (BILL) | `mov` |

Any other team: first three letters of the team name, lowercased. If the team is unclear, omit the prefix rather than guess — `(feature) Title` is a valid entry and several exist in the file already.

**type** — Linear labels are usually empty, so infer from the title and description: `bug` when it describes something broken, `design` for a design doc or spike, `feature` otherwise. Omit if genuinely unclear.

**priority** — Linear priority: 1 → `urgent`, 2 → `high`, 3 → `medium`, 4 → `low`. Priority 0 (none) → omit the line. Camen sometimes runs an entry at a different priority than Linear carries; when adding, use Linear's and mention the value in chat so he can override.

**size** — Linear's `estimate.name`, mapped directly: `XS` → `x-small`, `S` → `small`, `M` → `medium`, `L` → `large`, `XL` → `x-large`. No estimate set → omit the line and say so in chat.

**title** — Linear titles are sometimes too terse to stand alone (`design doc`). When the title wouldn't identify the work in a list, prefix it with the project name (`linked residents design doc`).

Do not reorder or reformat existing entries in any section.

## Mode 2 — add a meeting

`/todo 12pm josh` inserts one row into `### Meetings`, in time order:

```
- [ ] 1200 josh
```

Normalise the time to four digits, 12-hour, no colon and no meridiem — `12pm` → `1200`, `1:30pm` → `0130`, `9am` → `0900`. Sort on the real 24-hour value, not the printed string, so `0130` follows `1200`. With no meridiem given, assume the workday: 9 through 12 are morning, 1 through 5 are afternoon.

Everything after the time is the title, verbatim and lowercase as written.

## Mode 3 — rebuild the schedule

`/todo schedule` regenerates `### Schedule` alone, using the meetings already in the file. Same rules as the schedule part of a full refresh: start at `max(now, 0900)`, preserve earlier `[x]` rows, no other section touched. Do not ask about meetings — read them from the file.

## Mode 4 — refresh the day

### Meetings and Schedule — always rewritten

Ask, as a single message with no tool calls, and wait: **"What work meetings do you have today?"**

Then fetch in one batch:

- `mcp__claude_ai_Google_Calendar__list_events` for today, filtered to 09:00–17:00 (personal calendar; the work account isn't reachable).
- The current local time.

**Meetings** — work meetings from his reply plus personal events, sorted by time:

```
### Meetings

- [ ] 1200 josh
- [ ] 0130 doctor
```

**Schedule** — hourly blocks from `max(now, 0900)` to `1700`. Meetings occupy their real slot. Work blocks name the To Do items they cover, separated by ` | `. Preserve any already-checked `- [x]` rows from earlier in the day exactly as they are; only rewrite from the current hour forward.

```
### Schedule

- [x] 0900 -- orient
- [ ] 1200 -- josh | admission history | resident biography bug
```

Order with judgment: overdue and due-today items early, items with a non-code dependency early enough for it to resolve, PR-comment responses as mid-day fill, group work in the same repo. Include a lunch row. If it's already past 1700, skip the rewrite and say the day is done.

### Reviewable PRs and Up Next — merged, not rewritten

For both: **drop entries Camen has checked off (`- [x]`), keep unchecked entries that are still valid, append anything new.** Never remove an unchecked entry that still qualifies.

**Reviewable PRs** — the pool is open backend PRs with the `integrations` label, not authored by Camen, not yet approved:

```
gh pr list --repo augusthealth/august-backend \
  --search "is:open is:pr label:integrations -author:@me -review:approved" \
  --limit 50 --json number,title,author,createdAt,url,reviewDecision,reviewRequests,latestReviews,files
```

Score and keep the top 5:

| Factor | Score |
|---|---|
| Review requested from Camen | +5 |
| Changed files overlap Camen's recent backend work | +2 |
| Older than a week | +1 |
| No reviews yet | +2 |
| Non-approving review activity already | −3 |
| Camen already reviewed it | −3 |

For the overlap signal, get his recent file set from `gh pr list --repo augusthealth/august-backend --author @me --state all --limit 30 --json files,mergedAt,state`, keeping open PRs and those merged within 90 days.

```
### Reviewable PRs

- [ ] [#6842 Title](url) — author (requested, familiar)
```

Signals are short comma-separated tags — `requested`, `familiar`, `unreviewed`, `stale 3d`, `changes-requested` — and only appear when they fired.

**Up Next** — unstarted Linear tickets: assigned to Camen, or in projects where he has recent work, or in the Ad Hoc project. Drop anything blocked or assigned to someone else, and anything already in `### To Do`.

| Factor | Score |
|---|---|
| Assigned to Camen | +5 |
| Camen leads the project | +5 |
| Camen has recent work in the project | +3 |
| Ad Hoc project | +1 |
| No recent work, not assigned or lead | −5 |
| Untouched over 30 days | −2 |

Top 3. Match the existing To Do entry format so items can be moved up by hand.

## Chat output

Short. What changed in the file, and anything worth knowing that isn't in it — a missing estimate, an overdue ticket, a PR needing an SME beyond its reviewer, a calendar conflict. No schedule rationale, no per-item scoping, no closing question.

## Constraints

- Read-only with respect to Linear and GitHub. The only write is ToDo.md.
- No emoji. Linear IDs as plain text; the link carries the target.
- Update `## Today — <date>` to today's date whenever the file is touched.
- Never write, reorder, or reword `### To Do`.

## Failure modes

Never block the whole pass on one source. If `gh` isn't authed, skip Reviewable PRs. If Linear is disconnected, skip Up Next. If the calendar is unreachable, use his reply alone. Note each skip in one trailing line.

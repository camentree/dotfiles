---
name: todo
description: Maintains ~/Documents/notes/ToDo.md. Branches on the date at the top of the file - if it is today, the file gets a light refresh (calendar meetings, reviewable PRs) plus whatever the argument asks for; if it is an older date, the day rolls over - the old file is archived, To Do drops into Up Next, meetings and PRs are rebuilt, and a new schedule is laid out. A Linear ID or URL adds or updates a ticket in Up Next; a time and title like "12pm josh" adds a meeting; the word "schedule" rebuilds the Schedule block alone.
---

# Todo

The file is `~/Documents/notes/ToDo.md`. **Read it first, always** — the date on its first line decides which half of this skill runs.

```
## Today — YYYY-MM-DD
```

- Date is today → [Same day](#same-day).
- Date is older → [New day](#new-day), then apply the argument if there was one.

Preserve every section not named as written-to. Never reorder or reformat entries you aren't told to touch.

## File shape

```
## Today — YYYY-MM-DD

### To Do
### Up Next
### Meetings
### Reviewable PRs
### Schedule
```

Times are 12-hour, zero-padded, no colon, no meridiem: `0900`, `1200`, `0130`. Sort on the real 24-hour value, so `0130` follows `1200`.

## Reading the argument

| Invocation | Mode |
|---|---|
| `/todo` | nothing beyond the date branch |
| `/todo INT-626` or `/todo <linear-url>` | [add a ticket](#add-a-ticket) |
| `/todo 12pm josh` | [add a meeting](#add-a-meeting) |
| `/todo schedule` | [rebuild the schedule](#rebuild-the-schedule) |

The literal word `schedule`; else a Linear identifier (`ABC-123`) or a `linear.app` URL; else anything starting with a time (`12pm`, `1200`, `1:30pm`, `9am`). Anything else, ask rather than guess.

---

## Same day

The date at the top is today. Do both of these, then whatever the argument asked for.

- **Meetings** — check the personal calendar for events not already in the file and add them. Don't remove anything already there.
- **Reviewable PRs** — [rebuild the section](#reviewable-prs).

`### To Do`, `### Up Next`, and `### Schedule` stay untouched unless the argument says otherwise.

---

## New day

The date at the top is older than today. Run these in order.

**1. Archive.** Copy the file verbatim to `~/Documents/notes/archive/todo/{old-date}.md`, using the date currently at the top. Create the directory if it isn't there. Don't overwrite an existing archive file — if one exists, say so and stop.

**2. Bump the date** to today.

**3. Roll To Do down.** Move every `### To Do` entry, verbatim and in order, to the end of `### Up Next`. `### To Do` ends up empty.

**4. Rebuild Meetings.** Clear the section. Ask, as a single message with no tool calls, and wait: **"What work meetings do you have today?"** Then add his answer plus timed events from the personal calendar between 09:00 and 17:00, sorted by time. The work Google account isn't reachable, so his reply is the only source for work meetings.

```
### Meetings

- [ ] 1200 josh
- [ ] 0130 doctor
```

**5. Rebuild Reviewable PRs.** See [Reviewable PRs](#reviewable-prs).

**6. Top up Up Next.** See [Up Next](#up-next).

**7. Lay out the Schedule.** See [Rebuild the schedule](#rebuild-the-schedule).

**8. Promote the day's work.** Every Up Next entry that the new schedule names moves — verbatim — into `### To Do`, in schedule order. It leaves Up Next.

---

## Reviewable PRs

The pool is open, non-draft backend PRs labelled `move-ins` or `integrations` that nobody has approved:

```
gh pr list --repo augusthealth/august-backend \
  --search "is:pr is:open draft:false label:move-ins,integrations -review:approved" \
  --limit 50 --json number,title,author,createdAt,url,reviewDecision,reviewRequests,latestReviews,files
```

Every PR the search returns goes in the file — no cap — ordered by these signals:

| Factor | Score |
|---|---|
| Review requested from Camen | +5 |
| No reviews yet | +2 |
| Open longer than a week | +1 |
| Non-approving review activity already | −3 |
| Camen already reviewed it | −3 |
| Camen wrote it | −5 |

Drop entries he has checked off (`- [x]`); keep unchecked ones that still match the search; append the rest.

```
### Reviewable PRs

- [ ] [support the rest of vital fields under august_field_type_latest_vital_](https://github.com/augusthealth/august-backend/pull/6909) wsu — open 3d, no reviews
```

**title** — lowercased, exactly as GitHub has it otherwise.

**author** — first initial plus last name, no space: Kevin Tham is `ktham`, Will Su is `wsu`. Take it from the author's display name; if only a login is available, use the login.

**notes** — a short comma-separated trail after an em dash, covering how long it has been open and where review stands. `open 3d`, `open 2w`, `no reviews`, `1 review`, `changes requested`, `requested from you`, `you reviewed`, `yours`. Only include what actually applies.

## Up Next

Candidates are Linear issues assigned to Camen that haven't been started — his PM assigns everything to him, so assignment is the only filter that matters. Don't infer from project membership or past work.

`mcp__linear__list_issues` with `assignee: "me"`, or the same view at https://linear.app/august-health/my-issues/assigned.

Drop anything blocked, anything already in `### To Do`, and anything already in `### Up Next`. Add the top 3 by priority, then by due date, in the [entry format](#entry-format).

## Add a ticket

Fetch the issue with `mcp__linear__get_issue` and write it to `### Up Next` in the [entry format](#entry-format).

If the ticket is **already in Up Next**, merge rather than duplicate: refresh the title, priority, size, and branch from Linear, and keep his status line and every checkbox exactly as he left them. Otherwise append at the end of the section.

## Entry format

```
- [(ext) (feature) Add financial start date to admission history endpoints](https://linear.app/august-health/issue/INT-675/...)
    - priority: high
    - size: x-small
    - `camen/int-675-add-financial-start-date-to-admission-history-endpoints`
    - *not started*
    - [ ] plan
    - [ ] implement
    - [ ] self-review
    - [ ] merge PR
```

Every line is required except the PR link. Add `- [ ] merge [PR](github-url)` in place of `- [ ] merge PR` only when an open PR already references the branch.

**team label** — from the issue's Linear team. `ext` for Integrations & Insights (INT), `mov` for Billing / Move-ins (BILL). He is not on both teams, so one of the two always applies; if the team is genuinely something else, use the first three letters of the team name, lowercased.

**work label** — inferred from the title and description, since Linear labels are usually empty:

| Label | When |
|---|---|
| `(bug)` | something is broken and this fixes it |
| `(feature)` | new behaviour or a change to existing behaviour |
| `(design)` | a design doc, spike, or other write-up with no code work |

**priority** — Linear's, mapped 1 → `urgent`, 2 → `high`, 3 → `medium`, 4 → `low`.

**size** — Linear's `estimate.name`: `XS` → `x-small`, `S` → `small`, `M` → `medium`, `L` → `large`, `XL` → `x-large`.

When Linear is missing either one, guess and [confirm the guess](#confirming-a-guess).

**branch** — the issue's `gitBranchName`, in backticks.

**title** — Linear titles are sometimes too terse to stand alone (`design doc`). When the title wouldn't identify the work in a list, prefix it with the project name (`linked residents design doc`).

## Confirming a guess

A ticket with no priority or no estimate in Linear still gets both lines. Guess from the ticket's own content, write the entry, then ask him — one question per missing field, all of them in a single round, never one ticket at a time. He answers by accepting the guess or naming the value he wants; correct the file if he names one.

Keep each question to four lines: the ticket link, the guess, a one-sentence summary of what the ticket asks for, and a clause on why that guess. Options are the guess itself plus the neighbouring values.

> **INT-534** — https://linear.app/august-health/issue/INT-534/...
> Guessing **priority: low**. Cognito returns a 500 instead of a 400 when a token request has a bad parameter, so callers can't tell a client mistake from an outage. One endpoint, wrong status code, nobody blocked.

## Add a meeting

`/todo 12pm josh` inserts one row into `### Meetings`, in time order:

```
- [ ] 1200 josh
```

Normalise the time — `12pm` → `1200`, `1:30pm` → `0130`, `9am` → `0900`. With no meridiem given, assume the workday: 9 through 12 are morning, 1 through 5 are afternoon. Everything after the time is the title, verbatim and lowercase as written.

Adding a meeting deliberately leaves `### Schedule` alone — run `/todo schedule` when you want the day re-laid around it.

## Rebuild the schedule

Hourly blocks from `max(now, 0900)` to `1700`, using the meetings already in the file. Meetings occupy their real slot. Work blocks name the items they cover, separated by ` | `. Preserve any already-checked `- [x]` rows from earlier today exactly as they are and rewrite only from the current hour forward. Include a lunch row. If it's already past 1700, skip the rewrite and say the day is done.

```
### Schedule

- [x] 0900 -- orient | review prs
- [ ] 1200 -- josh | admission history | resident biography bug
```

**The first block of the day is always orient.** Half an hour of it, so the rest of that block goes to something else; Mondays take the full hour. If the day starts late enough that 0900 is gone, orient still leads whatever block it does start on.

**Reviewing PRs is work like anything else** and belongs on the schedule most days, preferably first thing — it shares the orient block well. Skip it only when `### Reviewable PRs` is empty or everything in it is already checked off.

Draw the rest from `### To Do` and `### Up Next`, reading each entry's status line (the `*italic*` line), priority, size, and any Linear due date. Order with judgment: overdue and due-today items early, items with a non-code dependency early enough for it to resolve, PR-comment responses as mid-day fill, group work in the same repo. A status line that says to hold off (*pause on this until…*) is binding.

Invoked on its own as `/todo schedule`, this touches nothing else and doesn't ask about meetings — it reads them from the file.

## Chat output

Short. What changed in the file, and anything worth knowing that isn't in it — an overdue ticket, a PR wanting an SME beyond its reviewer, a calendar conflict. No schedule rationale, no per-item scoping, no closing question.

## Constraints

- Read-only with respect to Linear and GitHub. The only writes are ToDo.md and the archive copy.
- No emoji. Linear IDs as plain text; the link carries the target.
- `### To Do` is Camen's. The only time this skill writes it is the new-day rollover — emptying it in step 3, filling it in step 8. Never reword an entry it moves.

## Failure modes

Never block the whole pass on one source. If `gh` isn't authed, skip Reviewable PRs. If Linear is disconnected, skip Up Next. If the calendar is unreachable, use his reply alone. Note each skip in one trailing line.

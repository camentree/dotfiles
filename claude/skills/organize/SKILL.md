---
name: organize
description: How to write ~/Documents/notes/organize.md, Camen's list of projects and the pull requests in each - the status marks on a PR line, the line formats, and which lines get a status. Read it before changing any line in organize.md, whether he asks in any words ("update organize", "mark it done", "add the PR") or another skill (manage, find-reviews) writes there.
---

# Organize

`~/Documents/notes/organize.md` is a heading per project (`## SELF contacts`, `## Linked Residents`), a checklist of the project's work under it, and `## Reviews` with `### Backlog` for teammates' pull requests. Read the file before editing: he edits it by hand too. Edit with the Edit tool, one line at a time, and leave every line you were not asked to change as it is.

## Which lines get a status

Only a line that is one pull request. A parent line that groups several pull requests gets none. A line of notes under a pull request gets none.

## Status marks

| Mark | Means |
|---|---|
| 📋 | not started |
| 👨🏾‍💻 | being worked, by an agent or by him |
| 💬 | needs his review: he hasn't reviewed, he is mid-review, or he reviewed without accepting and the comments have since been addressed |
| ❓ | needs review or work from a teammate |
| ⁉️ | blocked, on anything: another pull request merging, a production step, a quiet log, an agent that needs him. Say what in a sub-bullet. |
| ✅ | merged to master, or finished because it won't be done |

Marks compose, 💬 first when he has been in review on it:

- 💬 👨🏾‍💻 his review comments are being addressed by an agent
- 💬 ❓ he reviewed but didn't accept; the teammate needs to address comments
- 💬 ✅ accepted, not merged

Not every combination happens. When the state isn't known, leave the mark off and ask him. Markers he writes by hand that aren't in this table (📚 ‼️ on old lines) stay as he wrote them.

## Line formats

His own work, under a project heading:

```
- [ ] <status> <what it does> ([in draft](<url>)) `<branch>`
```

The link text says the pull request's state: `in draft`, `awaiting review`, `approved`. A line with no pull request yet has no link.

A teammate's pull request, under `## Reviews` or `### Backlog` (the find-reviews skill owns those two sections):

```
- [ ] <status> (<author login>) [<PR title>](<url>) `<branch>`
```

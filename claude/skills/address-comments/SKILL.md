---
name: address-comments
description: Turns a reviewed pull request into one commit per review comment. Gathers every comment the user hasn't replied to, sorts them by how much of their attention they need, handles trivial ones unattended, walks the rest with the user one at a time, then opens a difit server per commit with the reviewer's context pinned to the diff. Posts bare commit shas only after the user green-lights each one, and never writes prose on GitHub. Use when addressing, responding to, or working through PR feedback, review comments, or reviewer requests on a pull request.
---

# Address PR comments

## What this is for

Turning a reviewed PR into commits costs more attention than it should. Today the whole review lands
as one undifferentiated pile, every fix gets the same amount of thought whether it needs it or not,
small notes come back overbuilt, and the same preferences get restated every time.

This skill sorts the review by how much of the user's attention each comment actually deserves, and
spends that attention only where it changes the outcome.

- **Trivial** — the ask is clear and there is nothing to decide. Done in the background, no check-in.
- **Medium** — a decision is needed. The user sees the proposed fix and why the reviewer asked, one at a time, and answers yes or no.
- **Hard, and any medium they said no to** — planned together, one at a time, before code.
- **Theirs** — the comment wants an answer, not a change.

Every comment becomes its own commit. The user reviews the result in difit. Only after that does a
bare sha go back as a reply — nothing else. Every sentence a reviewer reads comes from the user's own
hand, so the skill hands them links for the comments that are theirs to answer.

## Inputs

`/address-comments` with no argument resolves the PR from the current branch
(`gh pr view --json number,title,url,headRefName`). `/address-comments <number|url>` overrides it.

Stop and say so if the branch has no PR, the branch is the default branch, or the resolved PR's head
branch isn't the one you're on. Don't guess, and don't check anything out.

## Process

State is easy to lose here — trivial work runs while the user answers questions, and green lights
arrive one commit at a time. Keep a checklist and update it as you go:

```
- [ ] Gathered — N comments after dropping ones the user replied to
- [ ] Triaged — _ trivial, _ medium, _ hard, _ theirs
- [ ] Trivial committed (background)
- [ ] Medium walked — yes: ___  no: ___
- [ ] Hard planned and committed
- [ ] difit launched — one server per commit
- [ ] Green-lit and sha posted: (one line per commit)
- [ ] User handed their links, with a drafted answer for each
```

### 1. Gather

Pull every review comment on the PR, then drop any the user has already replied to. Their reply is
the signal that a comment is handled or is theirs to handle — a sha from a previous run, a
disagreement, a question, anything. Resolved-vs-unresolved is not the filter; their participation is.

This makes re-runs safe. A second run over the same PR sees only what's still open.

### 2. Triage

**Size is not complexity.** A clear ask is trivial no matter how much code it touches — a new test,
a rename across ten files, a deletion. The question is whether anything is left to decide, not how
much work it is. The bar for trivial is lower than it feels.

Trivial when any of these hold:

- The reviewer supplied the change — a GitHub `suggestion` block, or code in the comment body.
- It's a deletion. Removing code has no style component.
- A project rule already settles it (`CLAUDE.md`, a documented convention, an established pattern in the repo).
- The reviewer is qualified to make the call and made it. A direct instruction is not a debate.
- It duplicates an earlier comment whose decision is already made.

Medium when a decision is genuinely open: the right answer depends on the user's intent, or the
reviewer proposed an approach that has to be accepted before it's built. A blocking review with an
implementation attached is still medium — the implementation removes the work, not the decision.

A refactor the reviewer fully specified is trivial, even when it changes a signature. What makes
something medium is an unmade decision, never the shape or size of the change.

Hard is rare. Reserve it for consequences invisible from the diff: cross-repo breakage, ops and
deploy implications, semantics that ripple past this PR.

Theirs when the comment wants an answer rather than a change — a question about intent, a domain
question, praise, an emoji. Don't write these. Read the code, work out what the answer probably is,
and hand it over with the link so the user replies in their own words. They'll confirm whether the
read was right.

Some questions need research before they can be answered ("does this library support audience
validation?"). Do the research, hand over the finding, let the user post it.

When unsure, escalate one level. The user reviews everything anyway, so a miss is annoying, not
dangerous.

### 3. Plan

No triage screen. Open with three lines and go straight to the first question:

```
PR 6871 — 9 comments.
4 trivial handled in background.
5 need you.
```

Then one comment at a time, in this shape and no longer:

```
[1/5] josh on PersonService:96
  "Can this go through the existing
   validator instead?"

  Why: there's already a validation path
  for person fields; this adds a second one.

  I'd do: drop the inline check, call
  PersonFieldValidator.validate.

  yes / no ?
```

Reviewer's words verbatim, one line of why they asked, one line of what you'd do, then wait. Don't
show code. Don't stack two questions. Don't summarize what came before.

Mediums first, since they're cheap. A `no` moves that comment to the hard queue rather than
reopening it — the alternative is discussed when its turn comes.

Then the hard queue, still one at a time, but planned rather than answered: propose an approach,
give whatever context is missing, and settle it before writing anything.

### 4. Implement

Trivial comments are already being worked while the user walks the medium queue. Everything else
starts once its decision is made.

One commit per comment. Subject describes the change, not the comment. Nothing else rides along —
no drive-by cleanups, no adjacent fixes, no reformatting of untouched lines.

Exception: duplicates and near-duplicates share a commit. Reviewers flag these themselves — "similar
to <link>", the same note on two call sites — and splitting them produces two commits with identical
diffs. Its sha gets posted to every comment it answers.

Compile after each commit through the fastest checker the project has. In Scala repos with Metals
running, that's `metals:compile-file` on what changed, or `metals:compile-module` when the change
crosses a module boundary — Bloop is already warm and shared with the editor, so this costs seconds
where a cold `sbt compile` costs minutes. Don't fall back to the slow path for a routine check.

The user runs preflight themselves. Don't run it, don't offer to.

The fix answers the comment and stops there. A one-line note gets a one-line change. If the fix seems
to need a new helper, a new layer, or a doc block that nobody asked for, that is the signal it has
outgrown the comment — stop and say so rather than building it. When a reviewer asks for one
outright, write it; their request beats the user's standing preference on their own review.

### 5. Hand off

difit is mandatory, one server per commit, all launched together — not one at a time.

Each server opens with the context already pinned to the diff, so the user isn't rebuilding it from
memory. For every commit, inject a `thread` comment at the line the reviewer commented on:

```bash
npx difit <sha> <sha>~1 --no-open --comment '{"type":"thread","filePath":"<path>","position":{"side":"new","line":<n>},"body":"<annotation>"}'
```

No `--keep-alive`. Closing the tab is how the user submits: difit exits on browser disconnect and
hands back whatever they wrote on the diff. `--keep-alive` holds the server open past that point, so
the comments never come back and they have to retype them into chat. The cost is that each server is
good for one look — relaunch it when they want another pass at the same commit.

Target first, base second. Reversed, difit reports "No differences found" and serves an empty page.
Don't pipe the command through `head`/`tail` — that kills the server as soon as it prints.

`line` must be a line the commit itself added or changed on the new side, read off that commit's own
hunk headers rather than carried over from where the reviewer commented upstream. Anchoring to a
context line kills the process. `--comment` also dies on a commit carrying a very large generated
diff, a regenerated `openapi.json` being the usual one — when a server won't start, relaunch it bare
and put that annotation in the hand-off text instead.

The annotation carries, in this order: the reviewer's comment verbatim and who wrote it, why they
asked, what was decided and by whom (backgrounded as trivial / approved in the medium round /
planned together), and what changed.

Print one line per commit: sha, subject, difit URL, and the comment it answers. Print the whole
`http://localhost:<port>` every time — the terminal turns a full URL into something clickable, and a
bare port is a retype. Never print the port on its own, and never collapse several servers into a
range like "ports 4966-4969". Send a single macOS notification when all servers are up.

Then wait. Green lights come per commit, not all at once — the user reviews one difit, approves it,
and that commit gets pushed and its sha posted while they move to the next.

**A green light is an explicit approval written somewhere in that commit's difit comments** — `LGTM`,
`✅`, `approved`, or anything else plainly meaning it. It can sit on any line; the marker is what
counts, not where it landed. Comments in the same batch that ask for changes override it — address
those and relaunch instead.

**An empty comment set is never approval.** A difit server exits on browser disconnect, but it also
exits when it crashes, when the session is torn down, or when something kills the process, and every
one of those returns the same empty result as a deliberate close. Report that the server came back
with nothing and wait. Never infer consent from silence, here or anywhere.

On approval, in this order: push the branch, then post the sha. Re-derive the sha from git at posting
time — they may amend or squash during review, so the value printed at launch is not the value to
post. Post the bare sha, nothing else. If the push fails, say so and post nothing; an unpushed sha is
nothing a reviewer can click.

Then close by handing over every comment that is theirs to answer, and write nothing on them. One
bullet each, carrying a clickable permalink, who wrote it, what it asks, and the answer you'd give —
so they can open it and reply in their own words without rereading the thread.

Build the permalink from the comment id the API already returned:
`https://github.com/<owner>/<repo>/pull/<number>#discussion_r<comment_id>`. Print it as a bare URL on
its own line. Markdown link syntax renders as its label in the terminal and swallows the address —
the same reason difit URLs go out whole. Never hand over a bare `file:line`, a reviewer's name, or
"the question about X" — anything that makes them go find the comment defeats the point. Include the
ones that only want a reaction; a 👍 is still theirs to leave.

This list is not optional and not conditional on the review going well. It ships in the same message
as the shas, every run, even when there is exactly one comment on it.

## Constraints

- **Never write prose on GitHub.** Bare commit shas only, and only after the user's green light. No
  replies, no review submissions, no resolving threads, no reactions. Every sentence a reviewer reads
  is one the user wrote.
- **Comments the user has replied to are theirs.** Don't reopen them, address them, or mention them.
- **Push only on an explicit approval marker**, and only the commit that earned it. One commit per
  comment is the job. Silence is not approval — see the hand-off section.
- **Don't run preflight.** The user does.
- **Answer the comment, nothing more.** Scope creep here is the failure mode this skill exists to fix.
- **No new helpers, layers, or doc blocks** unless the comment explicitly asked for one.

## Style

Read before writing:

- Page content and altitude: `~/.claude/skills/writing-style/references/artifacts.md`
- Anything he'll engage with in conversation: `~/.claude/skills/writing-style/references/conversation.md`, with the `prose-grader` agent on real questions

Do not restate those rules here. A skill that copies them drifts from them, then enforces the older version.

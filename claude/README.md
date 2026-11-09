# The harness

## One task's path

One session per task that Camen talks to, and a second for his review, so the review never sits on top of the build's context. The first session is a manager that never reads code: every step that produces bulk runs in a background subagent and returns a paragraph, so the work carries on while he talks to it.

```
/manage            Camen's session, context = the plan and the agents' reports
   design            the plan; questions about the code go to scouts           scout each
   review design     /critique: what a teammate would push back on             worker
   build loop, once for each group of work:
     build group       builds it, runs its tests, reads its diff against       worker
                       the repo's rules, commits; never the app
     check behavior    what the group made visible, tried in the running app   driver
   then once, on the whole branch:
     agent review      /verify per worktree: tests over the whole change,      worker each
     |                 scope, rules and criteria read fresh, and /code-review
     |                   findings ............... the build loop again, with `fixes` as the group
     demonstrate       /proof, on finished work: the proof page                driver
   hand over         the proof page, what needs Camen, and the URL to try
   |                   unclear what is wanted ........... Camen is asked before it is built
   |
/task-review       session two, started by /manage when Camen says to review
   /review           Camen in difit, walkthrough comments, fixes in place      in session
   |                   "good" ................... rules proposed from his comments
   /verify           the repo's pre-push checks                                worker
   /pr               push and open, description from the plan
   |
/address-comments  teammates' comments with Camen: changes, replies, rules proposed

/review-pr         a teammate's pull request: run it, findings with collateral in difit,
                   his marked comments posted as one review
```

`/manage` has seven things it can have done: design, review the design, code, review the code, check behavior in the app, demonstrate, and ask Camen. Which a task needs, in what order, how often, and when to stop is the manager's call: no loop or token limit is set for it. Four things are not:

- It never reads code. Findings go, whole, to a `fixes` build, with the manager's ruling beneath any that meets the plan; the builder, which has the code in front of it, fixes or answers each one, and the manager reads the answers.
- Nothing reaches Camen unreviewed or unproven: `/verify` by a worker that did not build it, and a proof page built after the last fix.
- Only a driver uses the running app, and never while a builder is changing that worktree.
- It never guesses what the feature is. Which way is best it decides itself and logs in the plan; when it cannot tell what is wanted, it asks before building.

`critique`, `verify`, `proof`, `review` and `pr` never start another step, so each runs by hand and does the same thing it does inside a session that sequences them. `/manage <plan>` run again reads the plan and carries on.

## The agents

Three kinds, in `agents/`, each with its brief and default model. The manager picks the model per job by what it needs, never above opus.

- `scout` (sonnet) answers a question about the code and cannot edit.
- `worker` (opus) builds a group or runs a check. It never starts the app.
- `driver` (opus) is the only kind that uses the running app, and it did not write the code. It checks lists of behavior while the task is built and records the demonstration at the end. A new one starts for each request and knows the app through its memory.

What agents learn is written down where the next one will find it, by how far it reaches:

- True in any app: the skill that was run. `/proof` holds what it takes to prove frontend or backend behavior anywhere, and how the page is built.
- True of one app as a whole: a skill named for the app. `/august` holds how the August apps are run, signed in to, seeded, and got around.
- True of one screen: the driver's memory, `~/.claude/agent-memory/driver/`, a file per app and area.
- True of one task: `checked.md` in the task's proof directory, the paths the checks took and the data they created.

An agent writes only when what it was given was wrong or missing and cost it time. Skill edits land as uncommitted changes in this repo's main checkout, which is where they get reviewed.

## The proof page

`~/.claude/tasks/<name>.proof/index.html`, built by `/proof`. One self-contained file: each acceptance criterion with its status (`shown`, `failed`, `not shown`) and something to look at — a recording of the app with its steps beside it, screenshots, or a request and response.

- `scripts/proof/walkthrough.cjs` drives a headless Chromium at a person's pace (a visible pointer, key-by-key typing, pauses) and records it, with a screenshot per step.
- `scripts/proof/page.cjs` builds the page from `proof.json` and embeds every recording and image.
- Playwright lives outside the repo in `~/.claude/proof-runtime`: `npm install --prefix ~/.claude/proof-runtime playwright`, then `~/.claude/proof-runtime/node_modules/.bin/playwright install chromium`. `ffmpeg` converts recordings to mp4; without it they stay webm.

## The plan file

`~/.claude/tasks/<name>.md`, written by `/manage`, which holds the template. Six sections:

- the task restated, with its source, branch, and worktrees
- Acceptance Criteria: checkable sentences about behavior, numbered
- Files
- Groups: what gets built together, each marked `done <sha>` as it lands, plus `fixes` for what the checks found
- Decisions: the alternative rejected, what a builder added, and each finding answered and not fixed
- Out of scope

It is the manager's memory and the only thing a subagent is given. An acceptance criterion is what everything grades against: the build stops on it, the review and the proof page check it, the reviewer reads it, and the PR's test plan is the list.

## Where Camen is needed

- A request that leaves what he wants unclear. The manager engages him on behavior and outcomes, in one question or a short discussion, before it is built, and works the code out itself. It asks about code when the code is the subject: a refactor, a request that cuts against how the codebase is built, a change far bigger than the task implied. Whether to raise something is its call.
- The hand-over: the proof page to look at, whatever is under "Needs you", and up to three decisions made for him that he may want reversed.
- Code review in difit, before anything is pushed. The walkthrough is comments in the diff, his comments get answered in place, and a comment saying the branch is good ends it.
- Any review comment that isn't a simple change.
- Picking which proposed rules get written.
- A step that is stuck, or fixing that has stopped getting closer.

## Self-improvement

Every skill ends with: if you hit a blocker this skill didn't anticipate, solve it and update the skill.

Review comments become rules. `/review` and `/address-comments` each end by proposing, for every comment that would apply to later work, one line for the repo's `## Code style checks`, or a lint rule when a machine could check it. Camen picks which are written. Builders read that section before they write and `/verify` grades against it.

## Layout

```
CLAUDE.md          who Camen is, how to write, how to code, what done means
settings.json      deny list, status line
scripts/           status line, proof recorder and page builder
skills/            manage, critique, verify, proof, review, review-pr, difit, address-comments, pr, task-review, todo, august, scrawl
skills/archive/    skills no longer used: plan, build, task-build, dispatch, monitor-prs, explain
agents/            scout, worker and driver, the subagents /manage starts
```

Project-specific knowledge lives in each project's CLAUDE.md or CLAUDE.local.md: how to run its checks, where the logs are, and a `## Code style checks` section. Verify reads that section from every CLAUDE.md and CLAUDE.local.md on the path from the repo root to each changed file, so a sub-project's rules apply only inside it.

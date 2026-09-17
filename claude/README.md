# The harness

## One task's path

Two background sessions per task, so the review never sits on top of the build's context. Steps that produce bulk run in subagents and return a paragraph; steps that may need Camen run in the session.

```
/dispatch        worktree + background session running /task-build <url>
   |
/task-build      session one, context = the plan
   /plan           read the task, read the code, write criteria and plan       in session
   |                 decision left open ........ ask Camen, stop
   |                 a day of work or more ..... Camen reads the plan, stop
   /build          split criteria into groups, then per group                  subagent each
   |                 decide tests, code, tests, loop compile / tests / run, commit
   |                 question ................. ask Camen, answer into Decisions, rerun
   /verify         compile, in-scope, criteria and style                       subagent
   |                 fail ..................... /build <group>, 3 passes max
   |
/task-review     session two, started by task-build with --bg
   /review         Camen in difit, walkthrough comments, fixes in place        in session
   |                 "good" ................... done
   /verify         same, plus the repo's pre-push checks                       subagent
   /pr             push and open, description from the plan
   |
/monitor-prs     CI, conflicts, comments, close-out on merge
                   approach questioned ........ ask Camen
```

Primitives (`plan`, `build`, `verify`, `review`, `pr`) never start another step, so each runs by hand and does the same thing it does inside a bundle. Only the bundles (`task-build`, `task-review`) sequence and launch. `/task-build` run again on the same branch reads the plan and carries on.

## The plan file

`~/.claude/tasks/<name>.md`. Example at `example-plan.md`. Six sections:

- the task restated, with its source and branch
- Acceptance Criteria: checkable sentences about behavior, one per line
- Files
- Groups: what ships together, each marked `done <sha>` as it lands; build writes it
- Decisions: placement, interfaces, the alternative rejected, and anything build added
- Out of scope

An acceptance criterion is what everything grades against. The build stops on it, the evaluator proves it, the reviewer reads it, and the PR's test plan is the list.

## Where user is needed

- An acceptance criterion that is still a decision after reading the task and the code. Asked with a recommendation first.
- Reading the plan, for tasks of a day or more.
- Code review in difit, before anything is pushed. The walkthrough is comments in the diff, his comments get answered in place, and a comment saying the branch is good ends it.
- Any review comment that isn't a simple change.
- Anything that trips a limit.

## Guards

- Build loop, 10 passes per group, in `skills/build`. Stops and says what was tried.
- Verify loop, 3 passes, in `skills/task-build` and `skills/task-review`. Same.
- Questions from a build group, 1 per group, in `skills/build`. A second means the plan is wrong.
- Token budget, `scripts/autonomous-task-guard.sh`, pre-tool-use hook. Blocks the next tool call past `CLAUDE_SESSION_BUDGET_TOKENS`. Counts input, output, cache writes, and cache reads at a tenth, across the session and its sub-agents; cache reads are most of a long session's usage. Only on when dispatch sets the variable, so hand-started sessions have no budgets.
- Available memory. 
- A passing default branch.

## Routines

```
/loop 10m /monitor-prs
/loop 30m /dispatch
```

Both are plain skills and run by hand too.

## Self-improvement

Every skill ends with: if you hit a blocker this skill didn't anticipate, solve it and update the skill. The monitor's close-out writes a retrospective per merged task and proposes the CLAUDE.md or skill change that would have prevented what went wrong. Proposals wait for Camen.

## Layout

```
CLAUDE.md          who Camen is, how to write, how to code, what done means
settings.json      deny list, the guard hook, status line
example-plan.md    a plan file, filled in
scripts/           autonomous task guard, status line
skills/            plan, build, verify, review, pr, task-build, task-review, dispatch, monitor-prs, todo
archive/           archived skills 
```

Project-specific knowledge lives in each project's CLAUDE.md or CLAUDE.local.md: how to run it, how to hit it, how to seed state, where the logs are, and a `## Code style checks` section. Verify reads that section from every CLAUDE.md and CLAUDE.local.md on the path from the repo root to each changed file, so a sub-project's rules apply only inside it.

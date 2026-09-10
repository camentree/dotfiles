# The harness

## One task's path

```
/dispatch      worktree + background session running /task <url>
   |
/task
   plan        read the task, read the code, write criteria and plan
   |             decision left open ........ ask Camen, stop
   |             a day of work or more ..... Camen reads the plan, stop
   build       per group: decide tests, code, tests, loop compile / behavior / tests  / run, commit
   |
   /verify     compile, in-scope, full test suite, acceptance criteria and style sub-agent
   |             fail ....................... back to build, 3 passes max
   /review     user-review. agent-seeded comments to aid review
   |             user's comment ................ fix, reply in the thread, validate behavior
   |             "good" ..................... done
   /pr         push and open, description from the plan
   |
/monitor-prs   CI, conflicts, comments, close-out on merge
                 approach questioned ........ ask user
```

`/task` takes a ticket URL, a file path, freeform text, or nothing and asks. Run it again on the same branch and it reads the plan and git and carries on.

## The plan file

`~/.claude/tasks/<name>.md`. Example at `example-plan.md`. Five sections:

- the task restated, with its source and branch
- Acceptance Criteria: checkable sentences about behavior, one per line
- Files
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

- Build loop, 10 passes per group, in `skills/task`. Stops and says what was tried.
- Verify loop, 3 passes, in `skills/verify`. Same.
- Token budget, `scripts/autonomous-task-guard.sh`, pre-tool-use hook. Blocks the next tool call past `CLAUDE_SESSION_BUDGET_TOKENS`. Counts input, output, and cache writes across the session and its sub-agents. Only on when dispatch sets the variable, so hand-started sessions have no budgets.
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
skills/            task, verify, review, pr, monitor-prs, dispatch, todo
archive/           archived skills 
```

Project-specific knowledge lives in each project's CLAUDE.md or CLAUDE.local.md: how to run it, how to hit it, how to seed state, where the logs are, and a `## Code style checks` section. Verify reads that section from every CLAUDE.md and CLAUDE.local.md on the path from the repo root to each changed file, so a sub-project's rules apply only inside it.

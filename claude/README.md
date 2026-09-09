# The harness

Claude Code does the coding. This directory makes that safe to leave alone: one path every task walks, a plan file per task, gates where Camen is needed, and two loops that run while nobody is watching.

## One task's path

```
/dispatch      worktree + background session running /task <url>
   |
/task
   plan        read the task, read the code, write criteria and plan
   |             decision left open ........ ask Camen, stop
   |             a day of work or more ..... Camen reads the plan, stop
   build       per group: decide tests, code, tests, loop compile / tests / run, commit
   |
   /verify     compile, scope, full suite, style sub-agent, criteria sub-agent
   |             fail ....................... back to build, 3 passes max
   /review     walkthrough as comments in difit, one server for the whole review
   |             his comment ................ fix, reply in the thread, /verify
   |             "good" ..................... done
   /pr         push and open, description from the plan
   |
/monitor-prs   CI, conflicts, comments, close-out on merge
                 approach questioned ........ ask Camen
```

`/task` takes a ticket URL, a file path, freeform text, or nothing and asks. Run it again on the same branch and it reads the plan and git and carries on.

## The plan file

`~/.claude/tasks/<name>.md`. Example at `example-plan.md`. Five sections:

- the task restated, with its source and branch
- Criteria: checkable sentences about behavior, one per line
- Files
- Decisions: placement, interfaces, the alternative rejected, and anything build added
- Out of scope

A criterion is what everything grades against. The build stops on it, the evaluator proves it, the reviewer reads it, and the PR's test plan is the list.

## Where Camen is needed

- A criterion that is still a decision after reading the task and the code. Asked with a recommendation first.
- Reading the plan, for tasks of a day or more.
- Code review in difit, before anything is pushed. The walkthrough is comments in the diff, his comments get answered in place, and a comment saying the branch is good ends it.
- Any review comment that questions the approach.
- Anything that trips a cap.

## Guards

- Build loop, 10 passes per group, in `skills/task`. Stops and says what was tried.
- Verify loop, 3 passes, in `skills/verify`. Same.
- Token budget, `scripts/autonomous-guard.sh`, pre-tool-use hook. Blocks the next tool call past `CLAUDE_SESSION_BUDGET_TOKENS`. Counts input, output, and cache writes across the session and its sub-agents. Only on when dispatch sets the variable, so hand-started sessions have no cap.
- Dispatch gates, in `skills/dispatch`. Free memory and a green default branch.

## The loops

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
scripts/           autonomous guard, status line
skills/            task, verify, review, pr, monitor-prs, dispatch, todo
archive/           explain, kept for later
```

Project-specific knowledge lives in each project's CLAUDE.md or CLAUDE.local.md: how to run it, how to hit it, how to seed state, where the logs are, and a `## Code style checks` section that verify reads alongside the global one.

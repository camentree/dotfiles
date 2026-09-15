---
name: task
description: Do one task end to end: plan, build, verify, review, PR. Takes a ticket URL, a file path, freeform text, or nothing, in which case it asks. Run inside a worktree on the task's branch.
---

# Task

The task is the argument: a URL to fetch, a file to read, or text as given. With no argument, ask what to work on.

`<name>` is the ticket id when there is one, otherwise a short slug of the task. The plan lives at `~/.claude/tasks/<name>.md`. If it already exists, read it and the branch and carry on from wherever they are.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

## 1. Plan

1. Read the task and everything it links to.
2. Read the code it touches, the project's CLAUDE.{local}.md, and the nearest precedent for the same kind of change.
3. Write the plan, shaped like `~/.claude/example-plan.md`. Each criterion is a checkable sentence about behavior. Include what the code forces that the task forgot. Fifteen lines is a normal plan.
4. Ask Camen only about something that passes both tests:
   - The task, its links, and the code don't answer it.
   - Different answers would change what gets built.

   That covers a criterion still open, a fact the task assumes you have, and an approach with more than one precedent in the code. It never covers confirming a plan you're confident in: write the assumption under Decisions and go. Ask with AskUserQuestion, a recommendation first, and end the turn.
5. If the task is a day of work or more, ask Camen to read the plan and end the turn.

## 2. Build

Split the criteria into groups that ship together. For each group:

1. Decide the tests that prove the group's criteria.
2. Write the code.
3. Write the tests.
4. Loop, at most ten times. On failure fix and re-loop:
   - Compile.
   - Run the group's tests.
   - Run the code and confirm the new behavior directly.
5. Commit. The message says what behavior changed.
6. Add any decision the plan didn't cover to the plan file's Decisions.

Ten passes without a clean loop means the plan is wrong. Say what is stuck and what you tried, and end the turn.

## 3. Verify

`/verify`. A failure comes back to Build for that fix.

## 4. Review

`/review`. Runs until he says the branch is good.

## 5. PR

`/pr`. Print the URL and end the turn. From here `/monitor-prs` owns the branch.

---
name: plan
description: Write the plan file for a task. Takes a ticket URL, a file path, freeform text, or nothing, in which case it asks. Asks Camen only what the task and the code cannot answer. Starts nothing else.
---

# Plan

The task is the argument: a URL to fetch, a file to read, or text as given. With no argument, ask what to work on.

`<name>` is the ticket id when there is one, otherwise a short slug of the task. The plan lives at `~/.claude/tasks/<name>.md`. If it already exists, read it and improve it rather than starting over.

1. Read the task and everything it links to.
2. Read the code it touches, the project's CLAUDE.{local}.md, and the nearest precedent for the same kind of change.
3. Write the plan, shaped like `~/.claude/example-plan.md`. Each criterion is a checkable sentence about behavior. Include what the code forces that the task forgot. Fifteen lines is a normal plan. Leave Groups empty; `/build` fills it.
4. Ask Camen only about something that passes both tests:
   - The task, its links, and the code don't answer it.
   - Different answers would change what gets built.

   That covers a criterion still open, a fact the task assumes you have, and an approach with more than one precedent in the code. It never covers confirming a plan you're confident in: write the assumption under Decisions and go. Ask with AskUserQuestion, a recommendation first, and end the turn.
5. If the task is a day of work or more, ask Camen to read the plan and end the turn.

Print the plan path. The plan is the only thing `/build` gets, so anything it would need to know goes in the file, not in this conversation.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

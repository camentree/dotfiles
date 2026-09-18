---
name: build
description: Build a plan file's criteria on the current branch. With the plan alone, splits the criteria into groups and builds each in a fresh subagent. With a group name too, builds that one group here, which is what the subagents run. Starts nothing else.
---

# Build

Input: the plan file, and optionally a group name.

## All groups: `/build <plan>`

1. If the plan has no Groups, write them: split the criteria into groups that ship together, one commit's worth each, named, each listing the criteria it covers.
2. For each group not yet marked `done <sha>`, in order, run a general-purpose subagent whose whole prompt is `Run /build <plan> <group>`. Nothing from this conversation goes in the prompt; what a group needs is in the plan.
3. The subagent returns one of:
   - `done <sha>` and a paragraph. Keep the paragraph, move on.
   - `question: ...`. Ask Camen with AskUserQuestion, a recommendation first, write the answer under Decisions, run the group again. A second question from the same group means the plan is wrong: say so and end the turn.
   - `stuck: ...`. Say what is stuck and what was tried, end the turn.
4. Report the shas.

A group that could not be built from the plan alone is a hole in the plan, and the plan is what gets fixed.

## One group: `/build <plan> <group>`

1. Read the plan, the CLAUDE.{local}.md files from the repo root down to the files the group touches, and those files.
2. Decide the tests that prove the group's criteria.
3. Write the code.
4. Write the tests.
5. Loop, at most ten times. On failure fix and re-loop:
   - Compile.
   - Run the group's tests.
   - Run the code and confirm the new behavior directly.
6. Commit. The message says what behavior changed.
7. In the plan: mark the group `done <sha>`, and add any decision the plan didn't cover to Decisions.
8. Return `done <sha>` and one paragraph: what changed and what proves it.

A fact the plan and the code don't settle, and that would change what gets built: stop before writing code and return `question:` with the question, the options, and a recommendation. Ten passes without a clean loop: return `stuck:` with what was tried. Neither commits.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

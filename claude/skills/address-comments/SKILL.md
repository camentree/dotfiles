---
name: address-comments
description: Work through the review comments on one of Camen's pull requests. Fetches every open thread, makes the clear changes a commit each, drafts the replies, and decides or asks about the rest. With --unattended it proves the fixes and leaves them on the work page for him to look at; pushes and posts only on his publish. A comment that would apply to later work ends as a proposed rule for the repo's notes.
---

# Address comments

Input: a pull request number or URL, else the current branch's pull request, and `--unattended` when the work page or another session started it. Run from the branch's worktree. The task directory is `~/.claude/tasks/<repo>/<branch>/`, where `<repo>` is the `basename` of `git remote get-url origin` without `.git` and `<branch>` is `git branch --show-current`; the plan, when there is one, is `plan.md` there. Every reply is written as `~/.claude/skills/assistant/writing.md` says.

1. Find the pull request and who wrote it: `gh pr view --json number,url,author,baseRefName,headRefName,title`.
2. Fetch every thread, with who said what and where:

   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved isOutdated path line comments(first:50){nodes{databaseId author{login} body url}}}}}}}' -F owner=<owner> -F repo=<repo> -F number=<number>
   ```

   Review summaries and comments on the pull request as a whole come from `gh pr view <number> --json reviews,comments`. Open is a thread that is not resolved and whose last message is not the author's.
3. For each open thread, read the code it points at and the plan's Decisions, then sort it:
   - A change that is clear: make it, a commit of its own, never an amend or a rebase, since the branch is already pushed. Run the tests that cover it. Draft the reply `Done in <sha>` and one line on what changed.
   - A question: draft the answer from the code and the plan.
   - A disagreement, a question about the approach, or anything that could go two ways: by the rule below.
4. Bring him the result (Interactive or Unattended, below).
5. Post nothing and push nothing until he says to: the replies go out under his name. Then push, a plain push with no force, and reply in each thread with `gh api --method POST repos/<owner>/<repo>/pulls/<number>/comments/<databaseId of the thread's first comment>/replies -f body=<reply>`. Leave resolving a thread to whoever opened it, unless the project's notes say otherwise.
6. Turn what the reviewers asked for into rules, so the next pull request does not earn the same comment. Leave out what was about this change only. For each comment that would apply to other work in this repo and is not already in its notes, write one line, the rule and a one-line why, for the `## Code style checks` section of the repo's CLAUDE.md if it is his, else its CLAUDE.local.md: builders read that section before they write, and `/verify` grades against it. A rule that holds in every repo goes to his own CLAUDE.md. One that a linter or a test could enforce: say so, and propose that in place of a line. Don't wait for a comment to repeat. Propose, never write unasked, and write only the ones he picks, editing an existing entry over adding one. With nothing to propose, say nothing.

## Interactive

When he ran it himself in the terminal. Step 4 is one summary, a line per thread: who, where, what they asked, quoted, and what you did or drafted. A comment that could go two ways gets its options, what each costs, and a recommendation, all in one AskUserQuestion; build what he decides as in the first pile. Step 5 waits for him to say so in the terminal. Step 6's proposed lines go in one AskUserQuestion.

## Unattended

Nobody is at the terminal. This session is the only writer of the task's `task.json`, through `node ~/.claude/scripts/task-set.cjs` as `~/.claude/skills/assistant/data.md` says: at the start `--title --kind mine --pull <url> --state working`, then `--doing` at least every 10 minutes.

- **Deciding** a comment that could go two ways: easily reversible, or not but what the change should do is clear, decide which is best, build it, and record it with `--decision` (what was chosen, why, the alternative). When it turns on what a user should be able to do or see, ask with `--question` (the question, options with what each costs, why it could not be decided), carry on with every other thread, and end the turn; the answer arrives as `[answer]`.
- **Drafts**: every reply goes into `replies.json` in the task directory, `[{ "databaseId", "path", "line", "comment", "reply" }]`, so the page and difit can show them before anything is posted.
- **Proof**: a `driver` with `Run /proof <plan>` (or, with no plan, the comments as its criteria) for what the fixes changed that a user would see; a test run for the rest. Record `--explanation` (what the reviewers asked and what changed, two to four sentences), each `--proof`, and each decision.
- **Rules**: step 6's lines are recorded as one `--decision` ("Proposed rules", each line and where it goes, alternative "write none"), and written only when a later `[note]` picks them.
- **Prepare the look**: the per-commit difit servers as the review skill's "Fixes for PR review comments" says, prepared as the difit skill's Prepared threads says, recorded with `--review-file`. Then `--ready fixes --state ready --doing "fixes ready"`, and end the turn.
- `[open review]`: open it as the review skill's Open says. `[comments sent]`: answer his threads as one batch as the review skill's Answer him says, his branch's rules, and update `replies.json`. `[publish]`: step 5, a plain push (never force) and the replies from `replies.json`, then close as the review skill's Close says and `--ready none --state done`.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

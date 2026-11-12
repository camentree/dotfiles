---
name: address-comments
description: Work through the review comments on a pull request with Camen. Fetches every open thread, makes the clear changes a commit each, drafts the replies, and brings him the ones that are a decision. Posts and pushes only when he says. A comment that would apply to later work ends as a proposed rule for the repo's notes.
---

# Address comments

Input: a pull request number or URL, else the current branch's pull request. Run from the branch's worktree. The plan file, when there is one, is `~/.claude/tasks/<repo>/<branch>/plan.md`, where `<repo>` is the `basename` of `git remote get-url origin` without `.git` and `<branch>` is `git branch --show-current`.

1. Find the pull request and who wrote it: `gh pr view --json number,url,author,baseRefName,headRefName`.
2. Fetch every thread, with who said what and where:

   ```
   gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$number){reviewThreads(first:100){nodes{isResolved isOutdated path line comments(first:50){nodes{databaseId author{login} body url}}}}}}}' -F owner=<owner> -F repo=<repo> -F number=<number>
   ```

   Review summaries and comments on the pull request as a whole come from `gh pr view <number> --json reviews,comments`. Open is a thread that is not resolved and whose last message is not the author's.
3. For each open thread, read the code it points at and the plan's Decisions, then sort it:
   - A change that is clear: make it, a commit of its own, never an amend or a rebase, since the branch is already pushed. Run the tests that cover it. Draft the reply `Done in <sha>` and one line on what changed.
   - A question: draft the answer from the code and the plan.
   - A disagreement, a question about the approach, or anything that could go two ways: change nothing. Write the options, what each costs, and a recommendation.
4. Bring Camen one summary, a line per thread: who, where, what they asked, quoted, and what you did or drafted. Everything in the third pile goes in one AskUserQuestion. Build what he decides the same way as the first pile.
5. Post nothing and push nothing until he says to in the terminal: the replies go out under his name. Then push, a plain push with no force, and reply in each thread with `gh api --method POST repos/<owner>/<repo>/pulls/<number>/comments/<databaseId of the thread's first comment>/replies -f body=<reply>`. Leave resolving a thread to whoever opened it, unless the project's notes say otherwise.
6. Turn what the reviewers asked for into rules, so the next pull request does not earn the same comment. Leave out what was about this change only. For each comment that would apply to other work in this repo and is not already in its notes, write one line, the rule and a one-line why, for the `## Code style checks` section of the repo's CLAUDE.md if it is his, else its CLAUDE.local.md: builders read that section before they write, and `/verify` grades against it. A rule that holds in every repo goes to his own CLAUDE.md. One that a linter or a test could enforce: say so, and propose that in place of a line. Don't wait for a comment to repeat. Propose, never write unasked: one AskUserQuestion listing each line and where it would go, and write only the ones he picks, editing an existing entry over adding one. With nothing to propose, say nothing.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

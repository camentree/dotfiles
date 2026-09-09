---
name: monitor-prs
description: One pass over every open PR of mine. Keeps CI green, resolves conflicts, handles review comments, closes out merged tickets. Meant to run on a loop.
---

# Monitor PRs

For each open PR authored by me, in its worktree:

1. **CI red.** Read the failing job's log, fix, commit, push.
2. **Conflicts.** Rebase onto the default branch, resolve, run `/verify`, push.
3. **Unanswered review comments**, sorted into three piles:
   - Mechanical and unambiguous: rename, typo, a missing null check. Fix it, commit, reply with only `done in <sha>`.
   - Clear but larger: implement and commit, do not push. Add it to the report for Camen.
   - Questions the approach, asks why, or could go two ways: do nothing. Add it to the report.
4. **Merged.** Move the ticket to Done, `wk rm` the worktree, and write a retrospective: what this run needed that it didn't have, and what Camen corrected, read from `~/.claude/tasks/<name>.comments.json` and the PR's review comments. Propose the diff to a skill or CLAUDE.md that would have prevented it. Do not apply it.

End with one report grouped by PR. For each item Camen needs: the comment text quoted, the relevant context from the code, and the options with a recommendation first. Written so he can answer in a word.

Never post prose to GitHub beyond `done in <sha>`. Never force-push.

If you hit a blocker this skill didn't anticipate, solve it, then update this skill so the next run doesn't hit it.

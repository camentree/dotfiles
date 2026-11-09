---
name: monitor-prs
description: One pass over every open PR of mine. Keeps CI green, resolves conflicts, handles review comments, closes out merged tickets. Meant to run on a loop.
---

# Monitor PRs

For each open PR authored by me, in its worktree:

1. **CI red.** Read the failing job's log, fix, commit, push.
2. **Conflicts.** Rebase onto the PR's base branch (`gh pr view --json baseRefName`), resolve, run `/verify`, push. A stacked PR whose parent has merged (`git config branch.<branch>.gh-merge-base` names a branch whose PR is merged): `git rebase --onto origin/<default branch> <parent's last head, headRefOid from gh pr list --state merged --head <parent>>`, so the parent's pre-squash commits drop out, then `gh pr edit --base <default branch>` if GitHub has not retargeted it, `git config --unset branch.<branch>.gh-merge-base`, `/verify`, push. A rebased branch can only be published with `git push --force-with-lease`, so that is the one force allowed below.
3. **Unanswered review comments**, sorted into three piles:
   - Mechanical and unambiguous: rename, typo, a missing null check. Fix it, commit, reply with only `done in <sha>`.
   - Clear but larger: implement and commit, do not push. Add it to the report for Camen.
   - Questions the approach, asks why, or could go two ways: do nothing. Add it to the report.
4. **Merged.** Move the ticket to Done, `wk rm` the worktree, and write a retrospective: what this run needed that it didn't have, and what Camen corrected, read from `~/.claude/tasks/<name>.comments.json` and the PR's review comments. Propose the diff to a skill or CLAUDE.md that would have prevented it. Do not apply it.

End with one report grouped by PR. For each item Camen needs: the comment text quoted, the relevant context from the code, and the options with a recommendation first. Written so he can answer in a word.

Never post prose to GitHub beyond `done in <sha>`. Never force-push.

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

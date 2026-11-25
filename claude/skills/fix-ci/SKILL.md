---
name: fix-ci
description: Get one of Camen's own pull requests green again - failing checks, a conflict with the base branch, or a stacked branch gone stale under its parent. Reads the failing job's log, re-runs a flaky job once, fixes a real failure with a new commit, merges a moved base in, pushes, and watches the checks. Never rewrites history or touches a teammate's branch. Use for "/fix-ci <pull request url>", or when the work page starts it.
---

# Fix CI

Input: a pull request url. Read `~/.claude/skills/assistant/data.md` and `~/.claude/skills/assistant/writing.md` first.

Only his own pull requests: the author is `camentree`. Anyone else's: stop, `--state done` with a decision line saying it was not his, and touch nothing.

## Limits

- Never rebase, amend, squash or force-push, `--force-with-lease` included: review replies and threads point at the old commits.
- Never touch a teammate's branch, merge a pull request, mark one ready, request reviewers, or post, resolve or comment on GitHub, Linear or Slack.
- No CloudWatch queries.
- A failure that needs a design choice: easily reversible, or not but what the change should do is clear, decide which is best, build it, and record it with `--decision`. When it turns on what a user should be able to do or see, ask with `--question` (writing.md's Question), carry on with anything else, and end the turn; the answer arrives as `[answer]`.

## Reporting

This session is the only writer of the task's `task.json`: `node ~/.claude/scripts/task-set.cjs` from the worktree. At the start `--pull <url> --kind mine --state working --doing "fixing CI: reading logs"`, then `--doing` at least every 10 minutes, always starting "fixing CI:" so the card says which kind of agent it is (he asked, 2026-11-25).

## Steps

1. `gh pr view <url> --json number,author,headRefName,baseRefName,mergeable,mergeStateStatus,statusCheckRollup,url`. Work in the branch's worktree (`git worktree list`), else `wk <branch>` from the repo's primary checkout (`~/Projects/valinor` for August). Leave an uncommitted change you find there alone, and say so in the decision line.
2. `git fetch origin`, and make the local branch match `origin/<branch>` with `git merge --ff-only`; when it cannot fast-forward, someone committed locally: stop and record why.
3. **A stale stacked branch**: when `git config branch.<branch>.gh-merge-base` (or the pull request's base) is another of his branches and `origin/<that branch>` has commits this one lacks, `git merge origin/<that branch>`.
4. **A conflict or a moved base**: `git merge origin/<base branch>`, resolve each conflict from both sides' intent (read the commits on each side that touched the lines), run the tests that cover the resolved files, and commit the merge.
5. **Failing checks**: for each failing job, `gh run view <run id> --log-failed` (job ids from `statusCheckRollup`), and tell flaky from real:
   - Flaky: a timeout, a network or registry error, a runner lost, a test that fails on code the branch did not touch and passes on the base branch. Re-run that job once, `gh run rerun <run id> --failed`. A second failure is real.
   - Real: the branch's own code, or a base it now merges in. Reproduce it locally as the repo's notes say, fix it in a new commit whose message says what behavior was broken, and run the tests that cover it.
   - Neither: a package not yet published, a secret or infra outside the repo. Record it; do not work around it.
6. Push, a plain `git push`.
7. Watch the checks: `gh pr checks <number> --watch --fail-fast --interval 60` in a background Bash (the default 10s interval helped trip GitHub's rate limit, 2026-11-25), and stop it before you end. A new failure goes back to step 5; the same failure after a different fix is stuck: record what was tried.
8. `task-set.cjs --decision "<what it did, in a few words>" --why "<what was failing and why>" [--alternative "..."] --state done --doing "<checks passing | what is still failing>"`, one decision per thing done (merged the base, fixed a test, re-ran a flaky job), each with the commit or run link in `why`. Write no `--material`: a CI fix pushes without his look, and materials would queue the card for him (2026-11-25).

If a step here fails or is missing, fix it, then record the fix once: how to do the step → this skill; a fact about the repo → its CLAUDE.md if mine, else CLAUDE.local.md; how I want you to work → my CLAUDE.md. Rule and one-line why, edit an existing entry over adding one.

---
allowed-tools: [Bash]
description: Run difit to do local code review before committing
---

# Difit

If there are uncommitted changes (including untracked files via `git status --porcelain`),
run `npx difit working --clean --include-untracked`.
Otherwise run `npx difit @ master --clean --include-untracked`.

Wait for any comments. If none -- that's fine -- just means I didn't have comments.

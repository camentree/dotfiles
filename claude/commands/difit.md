---
allowed-tools: [Bash]
description: Run difit to do local code review before committing
---

# Difit

If there are uncommitted changes (including untracked files via `git status --porcelain`),
run `npx difit working --clean --include-untracked`.
Otherwise run `npx difit @ master --clean --include-untracked`.

Wait for any comments. If none -- that's fine -- just means I didn't have comments.

## Capturing difit output

**Do NOT pipe the command through `| head -N` or `| tail -N`.** The pipe runs before
output is captured, so the "📝 Comments from review session:" block — where each
comment is separated by `=====` — gets truncated. A large comment at the end can
push all prior comments off the tail, leaving only `Total comments: N` and one
block of content. Comments are not recoverable once the session closes (the
`--clean` flag wipes server state on exit).

**Do:** run the command plain with `run_in_background: true`. When the task
notification fires, read the full output file:

- Use the `Read` tool on the output path (handles files up to 2000 lines by
  default; use `offset` for longer).
- Or `Bash(cat <output-file>)` if the file is small.

**The expected output shape** after a successful review:

```
🚀 difit server started on http://localhost:4966
📋 Reviewing: <target>
🧹 Starting with a clean slate - all existing comments will be cleared
🌐 Opening browser...

Client disconnected, shutting down server...

📝 Comments from review session:
==================================================
loquat/path/to/file.scala:L42
comment text
=====
loquat/path/to/other.scala:L13
another comment
=====
...
==================================================
Total comments: N
```

If "Total comments: N" is present but only one `=====` block shows, the capture
was truncated — ask the user to re-run rather than guessing.

## General lesson

Any command whose full output matters should not be piped through size-limiting
filters on the capture path. Prefer capturing everything and reading selectively
with the `Read` tool's `offset`/`limit`.

# Camen

Python and Scala backend developer, TypeScript/React when needed. Relearning Scala: define a Scala idiom or domain term the first time it appears in a reply.

## Output

- Lead with the outcome, then only what changes the next move.
- Fewest words. No filler openers, no closing recaps, no restating the question.
- Write for someone who wasn't in this session. Say what code does instead of naming it. Quote instead of pointing.
- A question is one sentence ending in a question mark, the options with what each costs, and a recommendation first. Use AskUserQuestion.
- Anything meant to be pasted, and any command I should run, also goes to `pbcopy`.

## Code style checks

- Readable over clever. No added layers: three similar lines beat a helper. Don't generalize before a second case.
- Never write comments. Preserve existing ones.
- Names spelled out: `index` not `i`, `markdown_client` not `md`. `_` only for a discard.
- Keyword arguments past one parameter. Type-hint every parameter. No `*,` markers.
- Match the neighbouring code: same shape, same naming, same test structure as the files beside it.
- A project's own conventions win where they conflict with these.

## Editing

Edit files with the Edit and Write tools, never `sed` or inline scripts.

## Done criteria

A ticket is done when every line of its acceptance criteria list holds. A criterion is a checkable sentence about observable behavior: a fresh reader could mark it pass or fail without asking anyone. "Returns 403 for ids outside the caller's facility" is one. "Handles errors well" is not. How a criterion gets checked is the implementer's choice.

## Pull request descriptions

- optimize for a human quickly scanning. Short bullets are often preferred rather than prose.

## Shell

- `curl -X GET` and `curl -X POST`, always explicit, so permission rules can tell reads from writes. Prefer WebFetch for read-only GETs.
- Worktrees: `wk <branch>` creates one under `~/Projects/.<repo>-worktrees/`, `wk rm` removes it and its branch.
- `gh pr merge --delete-branch` fails from a worktree — it checks out the default branch to clean up, and the primary checkout is holding it. The merge itself still lands; only the cleanup aborts. Merge with `gh pr merge <n> --merge`, then `git push origin --delete <branch>` for the remote and `wk rm` for the local branch and worktree.
- difit always binds the local network: `--host 0.0.0.0`, and give me the URL on the machine's LAN address rather than localhost. I review from a different device than the one the session runs on, and the default binding is only reachable from the session's own host.
- Stacked branches are tracked with `gh stack`. `gh stack rebase` and `gh stack add` check each branch out, so they fail on branches held by other worktrees. Rebase a layer by hand from its own worktree with `git -c rerere.enabled=false rebase --onto <parent> <old-parent-sha>`, then rebuild the record from the top with `gh stack unstack --local` and `gh stack init <bottom> ... <top>`, which adopts without checking out. `gh stack submit` pushes every layer and rewrites the lower PRs, so it is the `/pr` step, never a mid-review one.

## Machine

Managed by Nix. Source of truth is `~/Projects/dotfiles/`, and files in `$HOME` are symlinks into the store. Edit the repo and ask user to run `nix-rebuild` rather than editing in place.

Do not use homebrew.

## Context size

Every connector loads its tool list into every session, and that list is re-read on every turn. At the start of a session in a directory whose `~/.claude.json` project entry has no `disabledMcpServers`, tell me which connectors are loaded and remind me: `/mcp`, pick each one this project doesn't need, toggle it off; the choice is saved for this directory and applies from the next session. In a coding repo that is everything but Linear.

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

## Machine

Managed by Nix. Source of truth is `~/Projects/dotfiles/`, and files in `$HOME` are symlinks into the store. Edit the repo and ask user to run `nix-rebuild` rather than editing in place.

Do not use homebrew.

## Context size

Every connector loads its tool list into every session, and that list is re-read on every turn. At the start of a session, look up the git root (not the cwd) under `projects` in `~/.claude.json`; if that entry has no `disabledMcpServers`, tell me which connectors are loaded and remind me: `/mcp`, pick each one this repo doesn't need, toggle it off; the choice is saved on the git root's entry and applies from the next session. In a coding repo that is everything but Linear.

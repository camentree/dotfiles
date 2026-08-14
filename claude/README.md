# Claude Code config

Global Claude Code config, live-linked into `~/.claude/` by home-manager. Edits to existing files apply immediately (skills and references on next load, the output style at next session start); brand-new files need one `nix-rebuild` to get their symlink.

## The writing system

It feels like many parts. It is two mechanisms:

1. **Injected context** — text placed in front of Claude before it writes. The output style (`output-styles/writing-for-humans.md`) is always in the system prompt: a short floor that shapes every sentence. The reference files (`skills/writing-style/references/`) are canon: the full per-surface standard, loaded next to the work by whichever skill produces that surface.
2. **A grader that sometimes runs** — the `writing-audit` skill fixes finished writing in-session, and dispatches the `cold-reader` agent (`agents/cold-reader.md`), which reads the text with no session context and reports what it couldn't understand. Triggered by steps inside the producing skills, and backstopped by `scripts/writing-gate.sh`, a Stop hook that refuses to end a session that wrote 4000+ characters of prose without auditing it.

| Surface | Steering context | Check afterward |
|---|---|---|
| Chat to Camen | The floor only | None — the floor is the only lever |
| Code | Floor + `references/code.md` | `style-pass` skill; `scripts/comment-check.sh` warns on added comments |
| PR descriptions, commits | Floor + `references/as-me.md` | `writing-audit` + cold reader |
| Pages, plans, questions | Floor + `references/artifacts.md`, `questions.md`, `explain`'s `format.md` | `writing-audit` + cold reader, enforced by the gate |

## When output annoys you

Paste it back and ask what a reader without the session's context would have needed. That names a concrete rule; then it goes in exactly one place:

- **A claudeism or verbosity in chat** — name the exact phrase in the floor's Voice section. Takes a new session to apply, and the floor only gets shorter: condense or replace a line, never append.
- **A comment or clever code** — the rule lives in `references/code.md`; if the comment hook stayed silent, its extension list in `scripts/comment-check.sh` is missing the language.
- **A page or PR body that assumes knowledge** — check `writing-audits` (shell alias) first. The audit never ran: the gate. Ran and missed it: the cold reader's prompt in `agents/cold-reader.md`. Flagged it and got argued away: the don't-argue rule in `references/cold-reader.md`.
- **The same finding recurring in the log** — the rule's wording is failing as prose. Rewrite it in its reference, or make it a script if a grep could check it.

## Rules that keep it small

- References are canon; a rule changes there. The floor carries only what must shape every sentence of every session.
- Mechanical rules (greppable ones) become scripts, not prose.
- `writing-audits` renders the audit log — the scoreboard for whether any of this is working.

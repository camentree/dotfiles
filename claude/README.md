# Claude Code config

Global Claude Code config, live-linked into `~/.claude/` by home-manager. Edits to existing files apply immediately (skills and references at next load, the output style at next session start); new or renamed files need one `nix-rebuild` to fix their symlinks.

## How the writing system fires

Every path is one of two kinds. **Deterministic**: a script or the harness does it, every time, no judgment involved. **Claude's call**: an instruction Claude is expected to follow — reliable when fresh, skippable under end-of-task pull.

### Paths that inject reference material into context

| Path | Kind |
|---|---|
| `output-styles/writing-for-humans.md` — in the system prompt of every session, with mid-conversation adherence reminders | Deterministic |
| Skill steps saying "read `references/<surface>.md` before writing" — in explain, plan-feature, plan-pr, open-pr, execute-pr, style-pass, and the audit itself | Claude's call |
| `scripts/comment-check.sh` — injects a warning when an edit adds comment lines to Python/Scala/TS/SQL | Deterministic |
| `scripts/writing-gate.sh`'s block message — injects "run the audit" at the moment of stopping | Deterministic |

### Paths that call /writing-audit

The invocation is always Claude calling the Skill tool; what differs is the prompt behind it.

| Path | Kind |
|---|---|
| `scripts/writing-gate.sh` — Stop hook refuses to end a session that wrote 4000+ characters of `.html`/`.md` until the audit has run (per-session escape: `touch <state>/skip`; gives up after 3 refusals) | Deterministic detection; Claude complies |
| Final step of explain, open-pr, execute-pr, plan-feature, plan-pr | Claude's call |
| Typing `/writing-audit` | You |

### Paths that call the prose-grader agent

| Path | Kind |
|---|---|
| writing-audit — dispatched on page bodies, questions, and PR descriptions as part of the pass | Claude's call, prompted by the skill |
| Any real question put to Camen — the floor and `references/questions.md` both require a grade first, audit or no audit | Claude's call |
| Ad hoc — the agent is registered, so Claude may dispatch it whenever its description fits | Claude's call |

## Everything that tries to affect Claude's style

```
agents/
  prose-grader.md          The grader: haiku, one turn, no lookups. Reads prose with zero
                           session context, returns what it couldn't understand. Tune it
                           when graded prose still assumes knowledge.
output-styles/
  writing-for-humans.md    The floor: ~60 always-on lines — voice, context-independence,
                           the to-Camen / as-Camen split. The only lever chat has.
                           It only gets shorter: condense or replace, never append.
skills/
  writing-style/
    SKILL.md               Index of the references below. They are canon; rules change here.
    references/
      artifacts.md         Pages and plans: verdict up top, two screens, folds for proof.
      questions.md         How to ask Camen something answerable.
      as-me.md             PR descriptions, commits, review comments. His voice lives here.
      code.md              Full code rules; style-pass judges against this.
      prose-grader.md      The grading protocol: when to dispatch, how to act on findings.
  writing-audit/SKILL.md   The audit procedure. Pointers only, no rules of its own.
  style-pass/SKILL.md      The code review pass, run before Camen sees a diff.
scripts/
  writing-gate.sh          The Stop-hook gate: kind + size, 4000-char threshold.
  comment-check.sh         Warn-only comment detection on code edits.
  writing-audit-log.sh     The audit trail; `writing-audits` in the shell renders it.
```

Hook wiring lives in `settings.json`: the gate on Stop and PostToolUse, comment-check on PostToolUse.

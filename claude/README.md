# Claude Code config

Live-linked into `~/.claude/` by home-manager. Edits apply on next load; new or renamed files need `nix-rebuild`.

## Paths

### Paths that call prose-grader

**writing-audit**
(claude decides) grades page bodies, questions, and PR descriptions during the audit

**questions to Camen**
(claude decides) floor and `questions.md` require a grade before any real question

**ad hoc**
(claude decides) registered agent; dispatched whenever its description fits

### Paths that call /writing-audit

**writing-gate.sh**
(deterministic) Stop hook; blocks ending a session with 4000+ unaudited chars of `.html`/`.md`

**skill final steps**
(claude decides) explain, open-pr, execute-pr, plan-feature, plan-pr

**/writing-audit**
(you)

### Paths that inject reference material into context

**output style**
(deterministic) system prompt of every session, with adherence reminders

**skill style steps**
(claude decides) "read `references/<surface>.md` before writing"

**comment-check.sh**
(deterministic) warning injected when a code edit adds comments

**writing-gate.sh block message**
(deterministic) "run the audit" injected at the moment of stopping

## Structure

```
agents/
  prose-grader.md          haiku, no context, one turn; reports what it couldn't understand
output-styles/
  writing-for-humans.md    always-on floor; chat's only lever; only gets shorter
skills/
  writing-style/
    SKILL.md               index of the references
    references/            canon; rules change here
      artifacts.md         pages and plans
      questions.md         questions to Camen
      as-me.md             PR descriptions, commits, review comments
      code.md              code rules; style-pass judges against it
      prose-grader.md      when to dispatch the grader, how to act on findings
  writing-audit/SKILL.md   audit procedure; pointers, no rules
  style-pass/SKILL.md      code review pass before Camen sees a diff
scripts/
  writing-gate.sh          the Stop-hook gate
  comment-check.sh         comment warnings on code edits
  writing-audit-log.sh     the log; `writing-audits` renders it
settings.json              hook wiring
```

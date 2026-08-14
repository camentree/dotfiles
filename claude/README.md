# Claude Code Style Configuration

We have a couple methods for affecting claude code's output

1. context-injection
2. agents
3. skills
4. tool hooks


## Paths into style

1. context-injection
  - writing-style/references
    - artifacts.md
      - _style rules for how artifacts should be created_
      - /explain (called by user)
      - /plan-feature (called by user)
      - /plan-pr (called by user)
      - /writing-audit (sometimes injected by claude when auditing a finished page)
    - conversation.md
      - _style rules for conversation prose Camen engages with — explanations, findings, questions_
      - /explain (called by user)
      - /plan-feature (called by user)
      - /plan-pr (called by user)
      - /execute-pr (called by user)
      - /address-comments (called by user)
      - writing-for-humans output style (sometimes injected by claude when writing something for Camen to engage with)
      - /writing-audit (sometimes injected by claude when auditing a question)
    - as-me.md
      - _style rules for prose written as Camen_
      - /open-pr (called by user)
      - /writing-audit (sometimes injected by claude when auditing a PR description or commit message)
    - code.md
      - _style rules for code_
      - /execute-pr, before the first file (called by user)
      - /style-pass (called by user)
  - output-styles/writing-for-humans.md
    - _always-on style rules; the only lever for chat_
    - every session's system prompt (deterministic)
  - CLAUDE.md
    - _user-level instructions; points at the output style_
    - every session (deterministic)
2. agents
  - prose-grader.md
    - _grades prose with no session context; reports what it couldn't understand_
    - /writing-audit (sometimes called by claude when grading a page, question, or PR description)
    - writing-for-humans output style (sometimes called by claude before a real question reaches Camen)
    - ad hoc (sometimes called by claude when its description fits the task)
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader_
    - writing-gate.sh (deterministic)
    - /explain (called by user)
    - /open-pr (called by user)
    - /execute-pr (called by user)
    - /plan-feature (called by user)
    - /plan-pr (called by user)
    - typed directly (called by user)
  - style-pass
    - _reviews and fixes the working diff against code.md_
    - /execute-pr (called by user)
    - /writing-audit (sometimes called by claude when the audit reaches code)
    - typed directly (called by user)
  - writing-style
    - _index of the references_
    - ad hoc (sometimes called by claude when defining or polishing a style)
4. tool hooks
  - writing-gate.sh
    - _blocks ending a session with 4000+ unaudited chars of .html/.md_
    - Stop and PostToolUse events (deterministic)
  - comment-check.sh
    - _warns when a code edit adds comments_
    - PostToolUse on Write/Edit (deterministic)
  - writing-audit-log.sh
    - _keeps the audit log_
    - PreToolUse on Skill (deterministic)
    - `writing-audits` alias (called by user)


## Structure


- agents/
  - prose-grader.md                                    
  - output-styles/
    - writing-for-humans.md   
  skills/
    writing-style/
      SKILL.md               
      references/
        artifacts.md                 
        conversation.md      
        as-me.md            
        code.md              
    writing-audit/SKILL.md   
    style-pass/SKILL.md      
scripts/
  writing-gate.sh          
  comment-check.sh         
  writing-audit-log.sh     
settings.json


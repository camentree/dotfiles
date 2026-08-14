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
      - _artifact creation rules_
      - /explain (injected by user when called)
      - /plan-feature (injected by user when called)
      - /plan-pr (injected by user when called)
      - /writing-audit (can be injected by claude after writing an artifact)
    - conversation.md
      - _style rules for conversation prose Camen engages with — explanations, findings, questions_
      - /explain (injected by user when called)
      - /plan-feature (injected by user when called)
      - /plan-pr (injected by user when called)
      - /execute-pr (injected by user when called)
      - /address-comments (injected by user when called)
      - writing-for-humans output style (can be injected by claude when responding to camen)
      - /writing-audit (can be injected by claude after responding to Camen with something he should engage with)
    - as-me.md
      - _style rules for prose written as Camen_
      - /open-pr (injected by user when called)
      - /writing-audit (can be injected by claude when auditing a PR description or commit message)
    - code.md
      - _style rules for code_
      - /execute-pr (injected by user when called; read again right before code gets written)
      - /style-pass (injected by user when called)
  - output-styles/writing-for-humans.md
    - _always-on style rules; the only lever for chat_
    - every session's system prompt (deterministic)
  - CLAUDE.md
    - _user-level instructions; points at the output style_
    - every session (deterministic)
2. agents
  - prose-grader.md
    - _grades prose with no session context; reports what it couldn't understand_
    - /writing-audit (can be called by claude when grading a page, a PR description, or something Camen should engage with)
    - writing-for-humans output style (can be called by claude before a real question reaches Camen)
    - ad hoc (can be called by claude when its description fits the task)
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader_
    - writing-gate.sh (deterministic)
    - /explain (injected by user when called)
    - /open-pr (injected by user when called)
    - /execute-pr (injected by user when called)
    - /plan-feature (injected by user when called)
    - /plan-pr (injected by user when called)
    - typed directly (injected by user when called)
  - style-pass
    - _reviews and fixes the working diff against code.md_
    - /execute-pr (injected by user when called)
    - /writing-audit (can be called by claude when the audit reaches code)
    - typed directly (injected by user when called)
  - writing-style
    - _index of the references_
    - ad hoc (can be called by claude when defining or polishing a style)
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
    - `writing-audits` alias (injected by user when called)


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


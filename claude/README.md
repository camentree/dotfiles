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
      - /explain (user decides)
      - /plan-feature (user decides)
      - /plan-pr (user decides)
      - /writing-audit (claude decides)
    - questions.md
      - _style rules for how questions to Camen should be asked_
      - any skill about to ask a question (claude decides)
      - /writing-audit (claude decides)
    - as-me.md
      - _style rules for prose written as Camen_
      - /open-pr (user decides)
      - /writing-audit (claude decides)
    - code.md
      - _style rules for code_
      - /style-pass (user decides)
    - prose-grader.md
      - _protocol for grading prose without session context_
      - /writing-audit (claude decides)
  - output-styles/writing-for-humans.md
    - _always-on style rules; the only lever for chat_
    - every session's system prompt (deterministic)
  - CLAUDE.md
    - _user-level instructions; points at the output style_
    - every session (deterministic)
2. agents
  - prose-grader.md
    - _grades prose with no session context; reports what it couldn't understand_
    - /writing-audit (claude decides)
    - questions before Camen sees them (claude decides)
    - ad hoc (claude decides)
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader_
    - writing-gate.sh (deterministic)
    - /explain (user decides)
    - /open-pr (user decides)
    - /execute-pr (user decides)
    - /plan-feature (user decides)
    - /plan-pr (user decides)
    - typed directly (user decides)
  - style-pass
    - _reviews and fixes the working diff against code.md_
    - /execute-pr (user decides)
    - /writing-audit (claude decides)
    - typed directly (user decides)
  - writing-style
    - _index of the references_
    - defining or polishing a style (claude decides)
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
    - `writing-audits` alias (user decides)


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
        questions.md      
        as-me.md            
        code.md              
        prose-grader.md      
    writing-audit/SKILL.md   
    style-pass/SKILL.md      
scripts/
  writing-gate.sh          
  comment-check.sh         
  writing-audit-log.sh     
settings.json


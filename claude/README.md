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
      - automatic
        - sometimes injected by claude after writing an artifact (/writing-audit)
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
    - conversation.md
      - _style rules for conversation prose Camen engages with — explanations, findings, questions_
      - automatic
        - always imported by CLAUDE.md when session starts
        - sometimes injected by claude when responding to camen (writing-for-humans output style)
        - sometimes injected by claude after responding with something Camen should engage with (/writing-audit)
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
        - /execute-pr
        - /address-comments
    - as-me.md
      - _style rules for prose written as Camen_
      - automatic
        - sometimes injected by claude when auditing a PR description or commit message (/writing-audit)
      - by user
        - /open-pr
    - code.md
      - _style rules for code_
      - automatic
        - always imported by CLAUDE.md when session starts
      - by user
        - /execute-pr (read again right before code gets written)
        - /style-pass
  - output-styles/writing-for-humans.md
    - _always-on style rules; the only lever for chat_
    - automatic
      - always added to the system prompt when session starts
    - by user
      - none
  - CLAUDE.md
    - _user-level instructions; imports conversation.md and code.md every session_
    - automatic
      - always loaded when session starts
    - by user
      - none
2. agents
  - prose-grader.md
    - _grades prose with no session context; reports what it couldn't understand_
    - automatic
      - sometimes called by claude when grading a page, a PR description, or something Camen should engage with (/writing-audit)
      - sometimes called by claude before a real question reaches Camen (writing-for-humans output style)
      - sometimes called by claude when its description fits the task (ad hoc)
    - by user
      - none
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader_
    - automatic
      - always demanded when a session tries to stop with 4000+ unaudited chars of prose (writing-gate.sh)
    - by user
      - /explain
      - /open-pr
      - /execute-pr
      - /plan-feature
      - /plan-pr
      - typed directly
  - style-pass
    - _reviews and fixes the working diff against code.md_
    - automatic
      - sometimes called by claude when the audit reaches code (/writing-audit)
    - by user
      - /execute-pr
      - typed directly
  - writing-style
    - _index of the references_
    - automatic
      - sometimes called by claude when defining or polishing a style (ad hoc)
    - by user
      - none
4. tool hooks
  - writing-gate.sh
    - _blocks ending a session with 4000+ unaudited chars of .html/.md_
    - automatic
      - always run on Stop and PostToolUse events
    - by user
      - none
  - comment-check.sh
    - _warns when a code edit adds comments_
    - automatic
      - always run on PostToolUse for Write/Edit
    - by user
      - none
  - writing-audit-log.sh
    - _keeps the audit log_
    - automatic
      - always run on PreToolUse for Skill
    - by user
      - `writing-audits` alias


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


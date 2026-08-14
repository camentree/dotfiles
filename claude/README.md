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
        - none
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
      - by claude
        - /writing-audit (after writing an artifact)
    - conversation.md
      - _style rules for conversation prose Camen engages with — explanations, findings, questions_
      - automatic
        - every session (imported by CLAUDE.md)
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
        - /execute-pr
        - /address-comments
      - by claude
        - writing-for-humans output style (when responding to camen)
        - /writing-audit (after responding to Camen with something he should engage with)
    - as-me.md
      - _style rules for prose written as Camen_
      - automatic
        - none
      - by user
        - /open-pr
      - by claude
        - /writing-audit (when auditing a PR description or commit message)
    - code.md
      - _style rules for code_
      - automatic
        - every session (imported by CLAUDE.md)
      - by user
        - /execute-pr (read again right before code gets written)
        - /style-pass
      - by claude
        - none
  - output-styles/writing-for-humans.md
    - _always-on style rules; the only lever for chat_
    - automatic
      - every session's system prompt
    - by user
      - none
    - by claude
      - none
  - CLAUDE.md
    - _user-level instructions; imports conversation.md and code.md every session_
    - automatic
      - every session
    - by user
      - none
    - by claude
      - none
2. agents
  - prose-grader.md
    - _grades prose with no session context; reports what it couldn't understand_
    - automatic
      - none
    - by user
      - none
    - by claude
      - /writing-audit (when grading a page, a PR description, or something Camen should engage with)
      - writing-for-humans output style (before a real question reaches Camen)
      - ad hoc (when its description fits the task)
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader_
    - automatic
      - writing-gate.sh
    - by user
      - /explain
      - /open-pr
      - /execute-pr
      - /plan-feature
      - /plan-pr
      - typed directly
    - by claude
      - none
  - style-pass
    - _reviews and fixes the working diff against code.md_
    - automatic
      - none
    - by user
      - /execute-pr
      - typed directly
    - by claude
      - /writing-audit (when the audit reaches code)
  - writing-style
    - _index of the references_
    - automatic
      - none
    - by user
      - none
    - by claude
      - ad hoc (when defining or polishing a style)
4. tool hooks
  - writing-gate.sh
    - _blocks ending a session with 4000+ unaudited chars of .html/.md_
    - automatic
      - Stop and PostToolUse events
    - by user
      - none
    - by claude
      - none
  - comment-check.sh
    - _warns when a code edit adds comments_
    - automatic
      - PostToolUse on Write/Edit
    - by user
      - none
    - by claude
      - none
  - writing-audit-log.sh
    - _keeps the audit log_
    - automatic
      - PreToolUse on Skill
    - by user
      - `writing-audits` alias
    - by claude
      - none


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


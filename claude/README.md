# Claude Code Style Configuration

We have a couple methods for affecting claude code's output

1. context-injection
2. agents
3. skills


## Paths into style

1. context-injection
  - writing-style/references
    - code.md
      - _style rules for code_
      - automatic
        - always imported by CLAUDE.md when session starts
      - by user
        - /execute-pr (read again right before code gets written)
        - /style-pass
    - artifacts.md
      - _artifact creation rules_
      - automatic
        - none
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
    - conversation.md
      - _style rules for conversation prose Camen engages with — explanations, findings, questions_
      - automatic
        - always imported by CLAUDE.md when session starts
        - can be injected by agent when responding to camen (writing-for-humans output style)
      - by user
        - /explain
        - /plan-feature
        - /plan-pr
        - /execute-pr
        - /address-comments
        - /writing-audit
    - colleagues.md
      - _style rules for prose Camen's colleagues read — PR descriptions, commits, review comments, tickets_
      - automatic
        - none
      - by user
        - /open-pr
        - /writing-audit
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
      - sometimes called by claude before a real question reaches Camen (writing-for-humans output style)
      - sometimes called by claude when its description fits the task (ad hoc)
    - by user
      - /writing-audit — on pages, PR descriptions, and anything he's meant to engage with
3. skills
  - writing-audit
    - _rewrites finished prose against the references; wraps prose-grader. Prose only — never code, never on claude's own initiative_
    - automatic
      - none
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
      - none
    - by user
      - /execute-pr
      - typed directly
  - writing-style
    - _index of the references_
    - automatic
      - sometimes called by claude when defining or polishing a style (ad hoc)
    - by user
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
        code.md              
        artifacts.md                 
        conversation.md      
        colleagues.md            
    writing-audit/SKILL.md   
    style-pass/SKILL.md      
settings.json

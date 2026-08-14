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
      - pages and plans: verdict up top, two screens, folds for proof
      - called by explain, plan-feature, plan-pr, writing-audit (claude decides)
    - questions.md
      - how to ask Camen something answerable
      - called by any skill about to ask him something, writing-audit (claude decides)
    - as-me.md
      - PR descriptions, commits, review comments in his voice
      - called by open-pr, writing-audit (claude decides)
    - code.md
      - full code rules
      - called by style-pass (claude decides)
    - prose-grader.md
      - when to dispatch the grader, how to act on findings
      - called by writing-audit (claude decides)
  - output-styles/writing-for-humans.md
    - the always-on floor: voice, context-independence, to-Camen vs as-Camen; chat's only lever
    - in every session's system prompt (deterministic)
  - CLAUDE.md
    - machine and workflow context; points at the output style
    - loaded every session (deterministic)
2. agents
  - prose-grader.md
    - haiku, no session context, one turn; reports what it couldn't understand
    - called by writing-audit, by any real question before Camen sees it, ad hoc (claude decides)
3. skills
  - writing-audit
    - rewrites finished prose against the references; wraps prose-grader
    - called by writing-gate.sh's stop block (deterministic), final steps of explain / open-pr / execute-pr / plan-feature / plan-pr (claude decides), /writing-audit (you)
  - style-pass
    - fixes the working diff against code.md
    - called by execute-pr and writing-audit (claude decides), /style-pass (you)
  - writing-style
    - index of the references
    - called when defining or polishing a style (claude decides)
4. tool hooks
  - writing-gate.sh
    - Stop: blocks ending a session with 4000+ unaudited chars of .html/.md (deterministic)
  - comment-check.sh
    - PostToolUse: warns when a code edit adds comments (deterministic)
  - writing-audit-log.sh
    - PreToolUse: announces the audit and keeps the log behind `writing-audits` (deterministic)


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


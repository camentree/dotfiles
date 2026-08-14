# Claude Code Style Configuration

We have a couple methods for affecting claude code's output

1. context-injection
2. agents
3. skills
4. tool hooks


## Paths into style

1. context-injection
  - writing-style/refereces
    - artifacts.md
      - _brief description of how it affects style_
      - list of ways it's called...
      - 
    - as-me.md...
    - 
  - output-styles/writing-for-humans.md
    - _brief_description.._
    - list of ways it's called....
    - 
  - CLAUDE.md
    - _brief description.._
    - list of ways its called...
    - 
2. agents
  - prose-grader.md
    - _brief description.._
    - list of ways it's called...
    - 
3. skills
  - writing-audit
    - _brief description.. wraps prose-grader and..._
    - list of ways its called
  - 
  - 
4. tools hooks ...


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


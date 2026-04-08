export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""
plugins=(history)

source $ZSH/oh-my-zsh.sh

# Starship prompt
eval "$(starship init zsh)"

# Aliases
alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias cov-clean="rm .coverage.*"
alias git-open="open \`git config --get remote.origin.url\`"
alias vim="nvim"
alias vd="deactivate"
alias g="git"
alias gaa="git add --all"
alias gc="git commit -m"
alias gco="git checkout"

# Functions
function loadenv () { set -o allexport; source "${1:-.env}"; set +o allexport ; }
function git-clean () { git branch | grep -v "master\|main\|*" | xargs git branch -D ; }
function ls-ports () { lsof -PiTCP -sTCP:LISTEN ; }
function touch2 () { mkdir -p "$(dirname "$1")" && touch "$1" ; }

# Python virtual environment helpers
function vn () {
  local python="${1:-3.13}"
  uv venv --python "$python" ".venv"
  echo "Created .venv (python $python)"
  source .venv/bin/activate
}
function va () { source .venv/bin/activate ; }
function vdd () {
  deactivate 2>/dev/null
  rm -rf .venv
  echo "Removed .venv"
}

# Tab title (directory name)
function set_terminal_title() { print -Pn '\e]0;%1~\a' }
precmd_functions+=(set_terminal_title)

# Key bindings
bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo


# load nvm and completion
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Remove . from word characters so Option+Delete stops at periods
WORDCHARS=${WORDCHARS//.}

# Agent workflow (tmux + git worktrees)
[[ -f ~/agent-windows.sh ]] && source ~/agent-windows.sh

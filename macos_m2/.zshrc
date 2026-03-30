# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(history)

source $ZSH/oh-my-zsh.sh

# Aliases
alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias cov-clean="rm .coverage.*"
alias git-open="open \`git config --get remote.origin.url\`"
alias vim="nvim"
alias vd="deactivate"

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

# Key bindings
bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# load nvm and completion
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Remove . from word characters so Option+Delete stops at periods
WORDCHARS=${WORDCHARS//.}

# Agent workflow (tmux + git worktrees)
[[ -f ~/agent-windows.sh ]] && source ~/agent-windows.sh

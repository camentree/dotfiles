export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(history)

source $ZSH/oh-my-zsh.sh

alias vim="nvim"
alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias vd="conda deactivate"
alias vl="conda info --envs"
alias vr="conda activate r_4_0"
alias cov-clean="rm .coverage.*"
alias pytest="python -m pytest -v"
alias git-open="open `git config --get remote.origin.url`"

function virtualenv_name () { echo "${PWD##*/}${1-3.9}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.9} ; }
function va () { source activate "$(virtualenv_name $1)" ; envexport .env ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all -y ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }
function git-clean () { git branch | grep -v "master\|*" | xargs git branch -D ; }
function ls-ports () { lsof -PiTCP -sTCP:LISTEN ; }
function vm () { gcloud compute ssh --zone ${2:-us-east4-b} camen@${1:-ingestion-services} --project "lvl11a-core" ; }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

export HOMEBREW_NO_AUTO_UPDATE=1
export PYTHON_EGG_CACHE=/Users/cpiho/miniconda/Library/Cachces/Python-Eggs
export PYTHONDONTWRITEBYTECODE=1
export PATH=/opt/homebrew/bin:$PATH

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/camen/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/camen/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/camen/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/camen/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

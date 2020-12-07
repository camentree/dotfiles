export ZSH="/root/.oh-my-zsh"
export HOME="/home/camen"

ZSH_THEME="robbyrussell"
plugins=(git brew docker history)

source $ZSH/oh-my-zsh.sh

alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias vd="conda deactivate"
alias vl="conda info --envs"

function virtualenv_name () { echo "${PWD##*/}${1-3.8}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.8} ; }
function va () { source activate "$(virtualenv_name $1)" ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all -y ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }
function gclean () { git branch | grep -v "master\|*" | xargs git branch -D ; }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

export PATH="$HOME/miniconda/bin:$PATH"


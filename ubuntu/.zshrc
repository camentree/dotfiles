export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git brew docker history)

source $ZSH/oh-my-zsh.sh

alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias vd="conda deactivate"
alias vl="conda info --envs"
alias vr="conda activate r_4_0"

function virtualenv_name () { echo "${PWD##*/}${1-3.8}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.8} ; }
function va () { source activate "$(virtualenv_name $1)" ; envexport .env ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all -y ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }
function git-clean () { git branch | grep -v "master\|*" | xargs git branch -D ; }
function ls-ports () { lsof -PiTCP -sTCP:LISTEN ; }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

export PATH=$PATH:$HOME/OTB-7.2.0-Darwin64/bin
export OTB_APPLICATION_PATH=$HOME/OTB-7.2.0-Darwin64/lib/otb/applications
export OTB_LOGGER_LEVEL="CRITICAL"
export PATH="$HOME/miniconda3/bin:$PATH"

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

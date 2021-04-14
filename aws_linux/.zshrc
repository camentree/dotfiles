export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git docker history)

source $ZSH/oh-my-zsh.sh

alias pyc="rm *.pyc && rm __pycache__"
alias vd="source deactivate"
alias vl="conda info --envs"

function virtualenv_name () { echo "${PWD##*/}${1-3.6}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.6} ; }
function va () { source activate "$(virtualenv_name $1)" ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.google_cloud_platform/camen-piho-lea.json"
export PATH="$HOME/miniconda3/bin:$PATH"
export OTB_APPLICATION_PATH="$HOME/OTB-7.2.0-Darwin64/lib/otb/applications"

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

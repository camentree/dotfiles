export ZSH="/Users/camen/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git brew docker history)

source $ZSH/oh-my-zsh.sh

export PATH="/Users/camen/miniconda3/bin:$PATH"

alias pyc="rm *.pyc && rm __pycache__"
alias vd="source deactivate"
alias vl="conda info --envs"

function virtualenv_name { echo "${PWD##*/}${1-3.7}" ; }
function vn { conda create --name "$(virtualenv_name $1)" python=${1-3.7} ; }
function va { source activate "$(virtualenv_name $1)" ; }
function vdd { conda remove --name "$(virtualenv_name $1)" --all ; }
function envexport {set -o allexport; source .env; set +o allexport ; }


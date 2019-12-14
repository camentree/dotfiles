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

PROMPT="%{$fg[cyan]%}%n@%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"
module use -a /u/analytix/tools/modulefiles
module load miniconda3/v4

source activate /home7/analytix/tools/opt/miniconda3

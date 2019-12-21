export PFE_HOME="/nasa/u/${USER}"
export ZSH="$PFE_HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git history)

source $ZSH/oh-my-zsh.sh

alias pyc="rm *.pyc && rm __pycache__"
alias vd="conda deactivate"
alias vl="conda info --envs"
alias tmux="tmux -u"

function virtualenv_name () { echo "${PWD##*/}${1-3.6}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.6} ; }
function va () { source activate "$(virtualenv_name $1)" ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

# modules can only be loaded from pleiades front ends
if [[ "pfe" < ${(%):-%M} ]]
then
  module use -a /u/analytix/tools/modulefiles
  module load miniconda3/v4
  source activate $PFE_HOME/.conda/envs/${USER}3.6
fi
module load pkgsrc/2018Q3

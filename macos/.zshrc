export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"
plugins=(git brew docker history)

source $ZSH/oh-my-zsh.sh

alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias vd="conda deactivate"
alias vl="conda info --envs"
alias vr="conda activate r_4_0"
alias ec2="ssh -i ~/.ssh/camen-home.pem ec2-user@ec2-54-185-148-80.us-west-2.compute.amazonaws.com"

function virtualenv_name () { echo "${PWD##*/}${1-3.8}" ; }
function vn () { conda create -y --name "$(virtualenv_name $1)" python=${1-3.8} ; }
function va () { source activate "$(virtualenv_name $1)" ; envexport .env ; }
function vdd () { conda remove --name "$(virtualenv_name $1)" --all -y ; }
function envexport () { set -o allexport; source $1; set +o allexport ; }
function git-clean () { git branch | grep -v "master\|*" | xargs git branch -D ; }
function ls-ports () { lsof -PiTCP -sTCP:LISTEN ; }
function remote-jupyter () { ssh $1 -L 7070:localhost:${2-8888} ; }
function vm () { gcloud compute ssh --zone ${2:-us-east4-b} ${1:-ingestion-services} --project "lvl11a-core" ; }
function google-lea () { export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.google_cloud_platform/camen-piho-lea.json" }
function google-risq () { export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.google_cloud_platform/camen-piho-risq.json" }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.google_cloud_platform/camen-piho-lea.json"
export PATH=$PATH:/Users/camen/OTB-7.2.0-Darwin64/bin
export OTB_APPLICATION_PATH=/Users/camen/OTB-7.2.0-Darwin64/lib/otb/applications
# export PATH="$HOME/miniconda/bin:$PATH"  # commented out by conda initialize

# add username and hostname to zsh prompt
PROMPT="%{$fg[green]%}%m%{$reset_color%} ${PROMPT}"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/camen/miniconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/camen/miniconda/etc/profile.d/conda.sh" ]; then
        . "/Users/camen/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/Users/camen/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/camen/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/camen/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/camen/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/camen/google-cloud-sdk/completion.zsh.inc'; fi

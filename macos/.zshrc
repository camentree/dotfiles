P10K_FILEPATH="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
ZSH_FILEPATH="$HOME/.oh-my-zsh"
DEFAULT_PYTHON="3.11"

# DO FIRST
export ZSH=$ZSH_FILEPATH
[ -r "$P10K_FILEPATH" ] && source "$P10K_FILEPATH"

ZSH_THEME="powerlevel10k/powerlevel10k"
source $ZSH/oh-my-zsh.sh

alias vim="nvim"
alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
alias vd="conda deactivate"
alias vls="conda info --envs"
alias pytest="python -m pytest -v"
alias gs="git status"

function venv_name () { echo "${PWD##*/}${1:-$DEFAULT_PYTHON}" ; }
function vn () { conda create -y --name "$(venv_name $1)" python=${1:-$DEFAULT_PYTHON} ; }
function va () { source activate "$(venv_name $1)" ; envexport ; }
function vdd () { conda remove --name "$(venv_name $1)" --all -y ; }
function envexport () {
    filepath=${1:-.env}
    [[ -e $filepath ]] && {
        echo "Sourcing $filepath..."
        set -o allexport
        source $filepath
        set +o allexport
    }
}
function git-clean () { git branch | grep -v "main\|*" | xargs git branch -D ; }

bindkey "^X\\x7f" backward-kill-line
bindkey "^X^_" redo

export HOMEBREW_NO_AUTO_UPDATE=1
export PYTHON_EGG_CACHE="$HOME/miniconda/Library/Cachces/Python-Eggs"
export OTB_LOGGER_LEVEL=CRITICAL
export PYTHONDONTWRITEBYTECODE=1
export PATH=/opt/homebrew/bin:$PATH

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

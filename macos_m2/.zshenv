# Environment variables — sourced by ALL zsh invocations (interactive, non-interactive, scripts)
# Keep this file lightweight. Interactive-only config belongs in .zshrc.

export HOMEBREW_NO_AUTO_UPDATE=1
export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"

# mise (manages java, sbt, etc.)
export JAVA_HOME="$HOME/.local/share/mise/installs/java/temurin-17.0.16+8"
eval "$(mise activate zsh)"

# Apple Shortcuts sets this variable which crashes JVM native socket binding
unset DIRHELPER_USER_DIR_SUFFIX

# Base python virtual environment
export VIRTUAL_ENV="$HOME/.venvs/base3.13"
export PATH="$VIRTUAL_ENV/bin:$PATH"

# Machine-specific overrides and secrets (not tracked in git)
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

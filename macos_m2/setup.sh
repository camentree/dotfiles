#!/bin/bash
set -e # exit on error

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

ZSH_URL="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"
TPM_REPO="https://github.com/tmux-plugins/tpm"

# ====================
# Xcode Command Line Tools
# ====================
echo -e "\nXcode Command Line Tools"
if ! xcode-select -p &> /dev/null; then
  echo "Installing..."
  xcode-select --install
  echo "Waiting for Xcode CLT installation to complete..."
  echo "Press any key once the installation dialog finishes."
  read -n 1 -s
else
  echo "Already Installed"
fi

# ====================
# Oh My Zsh
# ====================
echo -e "\nOh My Zsh"
if [[ ! -e "$HOME/.oh-my-zsh" ]]; then
  echo "Installing..."
  sh -c "$(curl -fsSL $ZSH_URL)"
  mv "$HOME/.zshrc" "$HOME/.zshrc_old"
else
  echo "Already Installed"
fi

# Powerlevel10k theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
  echo "Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "Powerlevel10k already installed"
fi

# ====================
# Homebrew
# ====================
echo -e "\nHomebrew"
if ! which brew > /dev/null; then
  echo "Installing..."
  /bin/bash -c "$(curl -fsSL $BREW_URL)"
else
  echo "Already Installed"
fi

echo "Updating..."
brew update

echo "Installing Packages..."
packages=(
    awscli
    buf
    gh
    git
    jq
    neovim
    nvm
    postgresql@14
    podman
    sqlite
    tmux
    uv
    yarn
)
for pkg in "${packages[@]}"; do
  if ! brew ls --versions "$pkg" > /dev/null 2>&1; then
      brew install "$pkg"
  else
    echo "$pkg already installed"
  fi
done

# ====================
# Fonts (Powerlevel10k)
# ====================
echo -e "\nNerd Fonts"
fonts=(
    font-meslo-lg-nerd-font
)
brew tap homebrew/cask-fonts 2>/dev/null || true
for font in "${fonts[@]}"; do
  if ! brew ls --cask --versions "$font" > /dev/null 2>&1; then
    brew install --cask "$font"
  else
    echo "$font already installed"
  fi
done

# ====================
# mise (for JVM / sbt)
# ====================
echo -e "\nmise"
if ! command -v mise &> /dev/null; then
  echo "Installing..."
  curl https://mise.jdx.dev/install.sh | sh
else
  echo "Already Installed"
fi

echo "Installing Java and sbt via mise..."
mise use --global java@temurin-17.0.16+8
mise use --global sbt@1.12.5

# ====================
# Tmux Plugin Manager
# ====================
echo -e "\nTmux Plugin Manager"
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "Installing..."
  git clone "$TPM_REPO" "$HOME/.tmux/plugins/tpm"
else
  echo "Already Installed"
fi

# ====================
# NVM default node
# ====================
echo -e "\nNode (via nvm)"
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
if ! nvm ls default > /dev/null 2>&1; then
  echo "Installing latest LTS Node..."
  nvm install --lts
  nvm alias default lts/*
else
  echo "Default node already set"
fi

# Global npm packages
echo "Installing global npm packages..."
for pkg in typescript eslint; do
  if ! npm list -g --depth=0 "$pkg" &> /dev/null 2>&1; then
    npm install -g "$pkg"
  else
    echo "$pkg already installed globally"
  fi
done

# ====================
# Base Python environment
# ====================
echo -e "\nBase Python virtual environment"
VENV_DIR="$HOME/.venvs/base3.13"
if [[ ! -d "$VENV_DIR" ]]; then
  echo "Creating base venv at $VENV_DIR..."
  mkdir -p "$HOME/.venvs"
  uv venv --python 3.13 "$VENV_DIR"
else
  echo "Base venv already exists"
fi

# ====================
# SSH key
# ====================
echo -e "\nSSH key"
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
  echo "Generating ed25519 SSH key..."
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
  echo "Add this key to GitHub: https://github.com/settings/keys"
  cat "$HOME/.ssh/id_ed25519.pub"
else
  echo "SSH key already exists"
fi

# ====================
# Neovim config
# ====================
echo -e "\nNeovim config"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ ! -e "$NVIM_CONFIG_DIR" ]]; then
  echo "Symlinking nvim config..."
  mkdir -p "$HOME/.config"
  ln -s "$THIS_DIR/nvim" "$NVIM_CONFIG_DIR"
else
  echo "Neovim config already exists"
fi

# ====================
# VSCode config
# ====================
echo -e "\nVSCode config"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if [[ -d "$VSCODE_DIR" ]]; then
  for f in settings.json keybindings.json; do
    target="$VSCODE_DIR/$f"
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$THIS_DIR/vscode/$f" ]]; then
      echo "$f already symlinked"
    else
      if [[ -L "$target" ]] || [[ -e "$target" ]]; then
        mv "$target" "$target.bak"
      fi
      echo "Symlinking $f..."
      ln -s "$THIS_DIR/vscode/$f" "$target"
    fi
  done
else
  echo "VSCode not installed yet — skipping config symlinks"
fi

# ====================
# iTerm2 config
# ====================
echo -e "\niTerm2 config"
ITERM_PLIST="$HOME/com.googlecode.iterm2.plist"
ITERM_SRC="$THIS_DIR/com.googlecode.iterm2.plist"
if [[ -L "$ITERM_PLIST" ]] && [[ "$(readlink "$ITERM_PLIST")" == "$ITERM_SRC" ]]; then
  echo "iTerm2 plist already symlinked"
else
  if [[ -L "$ITERM_PLIST" ]] || [[ -e "$ITERM_PLIST" ]]; then
    mv "$ITERM_PLIST" "$ITERM_PLIST.bak"
  fi
  echo "Symlinking iTerm2 plist..."
  ln -s "$ITERM_SRC" "$ITERM_PLIST"
fi
# Tell iTerm2 to load prefs from custom folder
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# ====================
# Symlink Dotfiles
# ====================
echo -e "\nDotfiles"
dotfiles=(
  .vimrc
  .zshrc
  .zshenv
  .gitignore_global
  .gitconfig
  .tmux.conf
  .p10k.zsh
)

for filename in "${dotfiles[@]}" ; do
  filepath="$THIS_DIR/$filename"
  if [[ ! -e "$filepath" ]]; then
    echo "$filepath does not exist"
    exit 1
  fi

  target="$HOME/$filename"
  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$filepath" ]]; then
    echo "$filename already symlinked"
  else
    if [[ -L "$target" ]] || [[ -e "$target" ]]; then
      echo "$filename exists, backing up to $target.bak"
      mv "$target" "$target.bak"
    fi
    echo "Symlinking $filename"
    ln -s "$filepath" "$target"
  fi
done

git config --global core.excludesfile "$HOME/.gitignore_global"

# ====================
# Local env file (~/.zshenv.local)
# ====================
echo -e "\nLocal env file"
ZSHENV_LOCAL="$HOME/.zshenv.local"
if [[ ! -f "$ZSHENV_LOCAL" ]]; then
  echo "Creating ~/.zshenv.local..."
  cat > "$ZSHENV_LOCAL" << 'LOCAL_EOF'
# Machine-specific environment variables and secrets
# This file is gitignored and not tracked in dotfiles
LOCAL_EOF
  echo "Edit ~/.zshenv.local to fill in your secrets"
else
  echo "Already exists"
fi

# ====================
# macOS defaults
# ====================
echo -e "\nmacOS defaults"

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Dock: autohide, small icons, no recents
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 47
defaults write com.apple.dock show-recents -bool false

# Keyboard shortcuts: Cmd+B for sidebar toggle (global, Calendar, Notion)
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide Sidebar" "@b"
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Sidebar" "@b"
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Toggle Sidebar" "@b"
defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Hide Calendar List" "@b"
defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Show Calendar List" "@b"
defaults write notion.id NSUserKeyEquivalents -dict-add "Show/Hide Sidebar" "@b"

# iTerm2: remap Open Quickly
defaults write com.googlecode.iterm2 NSUserKeyEquivalents -dict-add "Open Quickly..." '@^$9'

# Keyboard modifier keys: Caps Lock → Control, Left Control → Left Command, Left Command → Left Option
# Uses -array (not -array-add) to overwrite rather than append, making this idempotent
defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array \
  '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771300</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer></dict>' \
  '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771302</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771300</integer></dict>' \
  '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771298</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771296</integer></dict>'

# Restart Dock to apply
killall Dock 2>/dev/null || true

# ====================
# Claude Code env variables
# ====================
echo -e "\nClaude Code settings"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  echo "Claude settings already exist — verifying env vars"
else
  echo "Creating Claude settings with env variables..."
  mkdir -p "$HOME/.claude"
  cat > "$CLAUDE_SETTINGS" << 'CLAUDE_EOF'
{
  "env": {
    "JAVA_HOME": "$HOME/.local/share/mise/installs/java/temurin-17.0.16+8",
    "PATH": "$HOME/.local/share/mise/installs/java/temurin-17.0.16+8/bin:$HOME/.local/share/mise/installs/sbt/1.12.5/bin:/bin:/usr/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$HOME/.local/bin",
    "DIRHELPER_USER_DIR_SUFFIX": ""
  }
}
CLAUDE_EOF
fi

# Ensure env vars are set in existing Claude settings
if command -v jq &> /dev/null && [[ -f "$CLAUDE_SETTINGS" ]]; then
  JAVA_HOME_VAL="$HOME/.local/share/mise/installs/java/temurin-17.0.16+8"
  UPDATED=$(jq --arg jh "$JAVA_HOME_VAL" \
    --arg path "$JAVA_HOME_VAL/bin:$HOME/.local/share/mise/installs/sbt/1.12.5/bin:/bin:/usr/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$HOME/.local/bin" \
    '.env.JAVA_HOME = $jh | .env.PATH = $path | .env.DIRHELPER_USER_DIR_SUFFIX = ""' \
    "$CLAUDE_SETTINGS")
  echo "$UPDATED" > "$CLAUDE_SETTINGS"
  echo "Claude env variables updated"
fi

echo -e "\nAll done!"
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshenv && source ~/.zshrc)"
echo "  2. Run 'tmux' and press prefix + I to install tmux plugins"
echo "  3. Set iTerm2 font to MesloLGS NF in Preferences > Profiles > Text"

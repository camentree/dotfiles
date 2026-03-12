#!/bin/bash
set -e # exit on error

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"


ZSH_URL="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"

# ZSH
echo -e "\nOh My Zsh"
if [[ ! -e "$HOME/.oh-my-zsh" ]]; then
  echo "Installing..."
  sh -c "$(curl -fsSL $ZSH_URL)"
  mv "$HOME/.zshrc" "$HOME/.zshrc_old"
else
  echo "Already Installed"
fi

# Homebrew
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
    git
    postgresql
    gh
    scala
    uv
    sbt
    jq
)
for pkg in "${packages[@]}"; do
  if ! brew ls --versions "$pkg" > /dev/null; then
      brew install "$pkg"
  else
    echo "$pkg already installed"
  fi
done

# Symlink Files
echo -e "\nDotfiles"
dotfiles=( .vimrc
           .zshrc
           .gitignore_global
           .gitconfig
           .tmux.conf
           .p10k.zsh
           # https://stackoverflow.com/questions/6205157/iterm-2-how-to-set-keyboard-shortcuts-to-jump-to-beginning-end-of-line/29403520#29403520
          com.googlecode.iterm2.plist
         )

if [[ -e "$HOME/com.googlecode.iterm2.plist" ]] ; then
  mv "$HOME/com.googlecode.iterm2.plist" "$HOME/com.googlecode.iterm2.plist-old"
fi

for filename in "${dotfiles[@]}" ; do
  echo "$filename"
  filepath="$THIS_DIR/$filename"
  if [[ ! -e "$filepath" ]];
    then
      echo "$filepath does not exist"
      exit 1;
  fi

  target="$HOME/$filename"
  if [[ ! -e $target ]]; then
    echo "Symlinking $target to $filepath"
    ln -s $filepath $target
  fi
done

git config --global core.excludesfile "$HOME/.gitignore_global"

echo -e "\nAll done!"

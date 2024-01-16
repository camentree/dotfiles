#!/bin/bash
set -e # exit on error

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

ZSH_URL="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install.sh"

# ZSH
echo -e "\nOh My Zsh"
if [[ -n "$HOME/.oh-my-zsh" ]]; then
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

echo "Installing homebrew Packages..."
packages=(git)
for pkg in "${packages[@]}"; do
    if ! brew ls --versions "$pkg" > /dev/null; then
        brew install "$pkg"
    else
        echo "$pkg already installed"
    fi
done

# Miniconda
echo -e "\nMiniconda3"
if [[ -n "$HOME/Miniconda" ]]; then
    echo "Installing..."
    curl -fsSL $CONDA_URL -o ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
    rm ~/miniconda.sh
else
    echo "Already Installed"
fi

# Symlink Files
echo -e "\nDotfiles"
dotfiles=(
    .emacs.d
    .vimrc
    .zshrc
    .gitignore_global
    .gitconfig
    .condarc
    nvim
    .tmux.conf
    .p10k.zsh
    com.googlecode.iterm2.plist
)

if [[ -e "$HOME/com.googlecode.iterm2.plist" ]] ; then
    mv "$HOME/com.googlecode.iterm2.plist" "$HOME/com.googlecode.iterm2.plist-old"
fi
for filename in "${dotfiles[@]}" ; do
    echo "Symlinking $target_filepath to $source_filepath"
    source_filepath="$THIS_DIR/$filename"
    target_filepath="$HOME/$filename"
    [[ -e $target_filepath]] && mv $target_filepath "${target_filepath}_old"
    ln -s $source_filepath $target_filepath
done

# https://github.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist
echo -e "\nAdding hosts file"
sudo cp "$THIS_DIR/hosts" "/etc/hosts"

git config --global core.excludesfile "$HOME/.gitignore_global"
echo -e "\nAll done!"

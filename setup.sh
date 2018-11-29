#!/bin/bash
set -e # exit on error

zsh_url="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"
conda_url="https://repo.continuum.io/miniconda"
conda_url="$conda_url/Miniconda3-latest-MacOSX-x86_64.sh"
brew_url="https://raw.githubusercontent.com/Homebrew/install/master/install"

# Zsh
if ! which zsh > /dev/null; then
  echo "Installing Zsh"
  sh -c "$(curl -fsSL $zsh_url)"

else
  echo "Zsh already installed"
fi

# Conda
if ! which conda > /dev/null; then
  echo -e "\nInstalling Conda"
  curl -fsSL $conda_url -o ~/miniconda.sh
  bash ~/miniconda.sh -b -p $HOME/miniconda
  rm ~/miniconda.sh
  echo "Creating conda python3.6 environment"
  vn 3.6

else
  echo -e "\nConda already installed"
fi

# Homebrew
if ! which brew > /dev/null; then
  echo -e "\nInstalling Homebrew"
  /usr/bin/ruby -e "$(curl -fsSL $brew_url)"

else
  echo -e "\nHomebrew already installed"
fi

echo -e "\nUpdating Homebrew"
brew update

echo -e "\nInstalling Homebrew packages"
brew_packages=( git
		postgresql
   		emacs
		aspell
		the_silver_searcher
		pandoc
		ruby
		ripgrep
	      )
for pkg in "${brew_packages[@]}"; do
  if ! brew list -1 | grep -q "^${pkg}\$"; then
    echo "Installing $pkg"
    brew install "$pkg"
  else
    echo "$pkg Already installed"
  fi
done

# Python
# we get python through miniconda

# Symlink dotfiles
echo -e "\nSymlinking dotfiles"
dotfile_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dotfiles=( .emacs.d
           .vimrc
           .zshrc
           .gitignore_global
         )

for filename in "${dotfiles[@]}" ; do
  file="$dotfile_dir/$filename"
  if [[ ! -e "$file" ]]; then
	  echo "$file does not exist"
	  exit 1;
  fi

  target="$HOME/$filename"
  if [[ ! -e $target ]]; then
    echo "Making symlink for $target"
    ln -s $file $target
  else
    echo "$target or symlink already exists"
  fi
done


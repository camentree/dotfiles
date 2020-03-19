#!/bin/bash
set -e # exit on error

NASA_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

echo -e "\nSymlinking some files"
FILES_TO_LINK=(
  ".vimrc"
  ".zshrc"
  ".gitignore_global"
)
for filename in "${FILES_TO_LINK[@]}"; do
  file="${NASA_DIR}/${filename}"
  if ! [ -f "${file}" ]; then
    echo "${file} does not exist!  Exiting..."
    exit 1;
  fi

  target="${HOME}/${filename}"
  if ! [ -f "${target}" ]; then
    echo "Making symlink for $file"
    ln -s "${file}" "${target}";
  else
    echo "${target} already exists"
  fi
done

echo -e "\nInstalling Oh My Zsh"
if ! [ -d "${HOME}/.oh-my-zsh" ]; then
  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh
  chsh -s `which zsh`
  exec zsh

else
  echo "Oh My Zsh already installed"
fi

echo -e "\nInstalling base conda environment"
env_name="base3.6"
if ! [ -d "${HOME}/.conda/envs/${env_name}" ]; then
  conda create -y --name "${env_name}" python=3.6
  source activate "${env_name}"
  conda install -c conda-forge jupyterlab --yes
  pip install callisto
  conda deactivate

else
  echo "Base conda environment already installed"
fi

if ! [ -f "${HOME}/.git-credentials" ]; then
  git config --global credential.helper store
fi

git config --global core.excludesfile "${HOME}/.gitignore_global"

echo -e "\nAll done!"

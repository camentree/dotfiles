#!/bin/bash
set -e # exit on error

PFE_HOME="/nasa/u/${USER}"

echo -e "\nSymlinking some files"
FILES_TO_LINK=(
  ".vimrc"
  ".zshrc"
  ".gitignore_global"
)
for filename in "${FILES_TO_LINK[@]}"; do
  file="${PFE_HOME}/documents/dotfiles/nasa/${filename}"
  if ! [ -f "${file}" ]; then
    echo "${file} does not exist!  Exiting..."
    exit 1;
  fi

  target="${filename}"
  if ! [ -f "${target}" ]; then
    echo "Making symlink for $file"
    ln -s "${file}" "${target}";
  else
    echo "${target} already exists"
  fi
done

if [ -z ${ZSH} ]; then
  exec zsh
fi

echo -e "\nAll done!"

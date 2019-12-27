#!/bin/bash
set -e # exit on error

PFE_HOME="/nasa/u/${USER}"
NASA_DIR_PFE="$(dirname "$(readlink -f ${PFE_HOME}/.zshrc)")"

echo -e "\nSymlinking some files"
FILES_TO_LINK=(
  ".vimrc"
  ".zshrc"
  ".gitignore_global"
)
for filename in "${FILES_TO_LINK[@]}"; do
  file="${NASA_DIR_PFE}/${filename}"
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

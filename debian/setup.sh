#!/bin/bash
set -eu  # exit on error

HOME_DIR=$1
ZSH_URL="https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh"

echo -e "\nUpdate apt"
apt-get update

echo -e "\nInstalling packages from apt"
APT_PACKAGES=(
  "bash"
  "vim"
  "wget"
  "zsh"
  "tmux"
)

for pkg in "${APT_PACKAGES[@]}"; do
  if ! dpkg-query -W -f='${Status}' "${pkg}" 2>/dev/null | grep -c "ok installed";
  then
    echo "Installing $pkg"
    apt-get -y install "$pkg"
  else
    echo "$pkg already installed"
  fi
done

echo -e "\nInstalling python versions"
if conda --version > /dev/null 2>&1;
  then
    echo "conda appears to already be installed"
  else
    INSTALL_FOLDER="${HOME_DIR}/miniconda3"
    if [ ! -d ${INSTALL_FOLDER} ] || [ ! -e ${INSTALL_FOLDER/bin/conda} ];
      then
        DOWNLOAD_PATH="miniconda.sh"
        wget http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ${DOWNLOAD_PATH};
        echo "Installing miniconda to ${INSTALL_FOLDER}"
        bash ${DOWNLOAD_PATH} -b -f -p ${INSTALL_FOLDER}
        rm ${DOWNLOAD_PATH}
      else
        echo "Miniconda already installed at ${INSTALL_FOLDER}"
    fi
fi


echo -e "\nSymlinking some files"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FILES_TO_LINK=(
  ".vimrc"
  ".zshrc"
  ".condarc"
  ".gitconfig"
  ".gitignore_global"
)

for filename in "${FILES_TO_LINK[@]}"; do
  file="${DIR}/${filename}"
  if ! [ -f "${file}" ]; then
    echo "${file} does not exist!  Exiting..."
    exit 1;
  fi
  target="${HOME_DIR}/${filename}"
  if ! [ -f "${target}" ];
  then
    echo "Making symlink for $file"
    ln -s "${file}" "${target}";
  else
    echo "${target} already exists"
  fi
done

echo -e "\nOh My Zsh"
if [[ ! -e "${HOME_DIR}/.oh-my-zsh" ]]; then
  echo "Installing..."
  sh -c "$(curl -fsSL $ZSH_URL)"
else
  echo "Already Installed"
fi

if [[ ! -e "${HOME_DIR}/.git-credentials" ]]; then
	  git config --global credential.helper store
  fi

  git config --global core.excludesfile "${HOME_DIR}/.gitignore_global"

echo -e "\nAll done! You may need to add \`source ~/.bashrc\` in ~/.bash_profile"

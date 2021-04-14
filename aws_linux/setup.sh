#!/bin/bash
set -e # exit on error

THIS_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

ZSH_URL="https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh"
CONDA_URL="http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
OTB_URL="https://www.orfeo-toolbox.org/packages/OTB-7.2.0-Linux64.run -O ~/OTB-7.2.0-Linux64.run"

# Linux Setup
echo -e "\nSetting up linux..."
sudo passwd ec2-user
sudo yum install util-linux-user -y

# ZSH
echo -e "\nInstalling Oh My Zsh"
if ! [ -d "${HOME}/.oh-my-zsh" ];
  then
    sudo yum -y install zsh
    wget $ZSH_URL -O - | zsh
    mv "$HOME/.zshrc" "$HOME/.zshrc_old"
    chsh -s $(which zsh)
  else
    echo "Oh My Zsh already installed"
fi

# Miniconda
echo -e "\nInstalling Miniconda 3"
if conda --version > /dev/null 2>&1;
  then
    echo "conda appears to already be installed"
  else
    INSTALL_FOLDER="$HOME/miniconda3"
    if [ ! -d ${INSTALL_FOLDER} ] || [ ! -e ${INSTALL_FOLDER/bin/conda} ];
      then
        DOWNLOAD_PATH="miniconda.sh"
        wget $CONDA_URL -O ${DOWNLOAD_PATH};
        echo "Installing miniconda to ${INSTALL_FOLDER}"
        bash ${DOWNLOAD_PATH} -b -f -p ${INSTALL_FOLDER}
        rm ${DOWNLOAD_PATH}
      else
        echo "Miniconda already installed at ${INSTALL_FOLDER}"
    fi
fi

# Git
echo -e "\nInstalling git"
if git --version > /dev/null 2>&1;
  then
    echo "Git already isntalled"
  else
    sudo yum install -y git
fi

if ! [ -f "${HOME}/.git-credentials" ];
  then
    git config --global credential.helper store
fi

# OrfeoToolBox
echo -e "\nInstalling OrfeoToolBox"
if ! [ ! -d "${HOME}/OTB-7.2.0-Darwin64" ];
  then
    echo "OTB appears to already be installed"
  else
    INSTALL_FOLDER="$HOME/OTB-7.2.0-Darwin64"
    if [ ! -d ${INSTALL_FOLDER} ];
      then
        DOWNLOAD_PATH="OTB-Linux64.run"
        wget $OTB_URL -O ${DOWNLOAD_PATH};
        echo "Installing OTB to ${INSTALL_FOLDER}"
        bash ${DOWNLOAD_PATH} --target ${INSTALL_FOLDER} --accept
        rm ${DOWNLOAD_PATH}
      else
        echo "OTB already installed at ${INSTALL_FOLDER}"
    fi
fi

# Packages
echo -e "\nInstalling some packages"
PACKAGES=(
  "tmux"
)
for package in "${PACKAGES[@]}"; do
  sudo yum install ${package}
done


# Symlink Files
echo -e "\nSymlinking some files"
FILES_TO_LINK=(
  ".vimrc"
  ".zshrc"
  ".gitignore_global"
  ".gitconfig"
  ".condarc"
)
for filename in "${FILES_TO_LINK[@]}"; do
  file="${THIS_DIR}/${filename}"
  if ! [ -f "${file}" ];
    then
      echo "${file} does not exist!  Exiting..."
      exit 1;
  fi

  target="${HOME}/${filename}"
  if ! [ -f "${target}" ];
    then
      echo "Making symlink for $file"
      ln -s "${file}" "${target}";
    else
      echo "${target} already exists"
  fi
done


echo -e "\nAll done!"

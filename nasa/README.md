# Install Scripts for NAS

1. SSH into the Pleiades Secure Frontend (PFE)
2. run `./nasa/setup_pfe.sh`
  1. sets up zsh with this repo's `nasa/.zshrc`
  2. sets up vim with this repo's `nasa/.vimrc`
  3. sets up global gitignore with this repo's `nasa/.gitignore-global`
  4. installs oh-my-zsh for useful plugins, themes, and aliases
  5. creates and sets up the base conda environment which is activated by the
     .zshrc
3. SSH into the Lou Secure Frontend (LFE)
4. run `/nasa/u/${USER}/<path to dotfile directory on PFE>/nasa/setup_lfe.sh`
  1. symlinks the home directory's config files to the config files on the PFE
  2. NOTE: conda is not available in Lou

## Useful Commands

1. `vn`create virtual environment with name of the current directory
2. `va` activate virtural environment with name of current directory
3. `vd` deactivate current virtual environment
4. `envexport <path to env>` export contents of a `.env` file to environment
5. `tmux` activate tmux


## Documentation

- [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [zsh](https://linuxconfig.org/learn-the-basics-of-the-zsh-shell)
- [callisto](https://pypi.org/project/callisto/)
- [vim](https://vim.rtorr.com/)
- [tmux](https://tmuxcheatsheet.com/)

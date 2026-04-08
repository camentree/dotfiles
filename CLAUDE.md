# Dotfiles

Personal dotfiles repo with configs organized by machine/environment.

## Structure

- `nix/` — next-gen config, actively migrating to (Nix/home-manager based)
- `macos_m2/` — current active config (M2 Mac), being migrated to `nix/`
- `macos_m1/`, `macos/`, `debian/`, `ubuntu/`, `aws_linux/`, `nasa/`, `bu/` — older/archived environments

## Current setup (`macos_m2/`)

- `setup.sh` — idempotent bootstrap script. Installs tools and symlinks configs to `$HOME`. Uses `$THIS_DIR` for paths so it works from any location.
- `nvim/init.lua` — single-file neovim config (kickstart-based, lazy.nvim)
- `ghostty` — Ghostty terminal config
- `starship.toml` — Starship prompt config
- `.zshrc` / `.zshenv` — shell config. Machine-specific secrets go in `~/.zshenv.local` (gitignored).
- `.tmux.conf` — tmux config with TPM plugins
- `vscode/` — VSCode settings and keybindings (symlinked into `~/Library/Application Support/Code/User/`)
- `claude/` — Claude Code global settings (CLAUDE.md, settings.json)

## Conventions

- Symlinks are managed by `setup.sh` — don't hardcode `~/Projects/dotfiles` paths in config files; use `$THIS_DIR` or relative paths in scripts.
- `setup.sh` is idempotent — safe to re-run. It checks before installing and backs up existing files to `.bak`.
- Never commit `.zshenv.local` or other secret files.

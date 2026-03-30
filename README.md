# Dotfiles

Declarative system config for my Macs using [Nix](https://nixos.org/),
[nix-darwin](https://github.com/LnL7/nix-darwin), and
[home-manager](https://github.com/nix-community/home-manager).

## Quick Start (new machine)

```bash
# 1. Clone
git clone git@github.com:camentree/dotfiles.git ~/Documents/dotfiles

# 2. Run setup (installs Nix, builds config)
cd ~/Documents/dotfiles/nix && bash setup.sh        # defaults to "server"
cd ~/Documents/dotfiles/nix && bash setup.sh work    # for work machine

# 3. Restart terminal

# 4. After any config change
rebuild
```

## File Structure

```
nix/
  flake.nix              ← Entry point. Only touch when adding a new machine.
  macos.nix              ← macOS settings shared across ALL machines.
  shell.nix              ← User config shared across ALL machines.
  hosts/
    server.nix           ← Intel server: nginx, postgres, always-on power.
  dotfiles/              ← Raw config files. Edit directly, then `rebuild`.
    tmux.conf
    vimrc
    p10k.zsh
    gitignore_global
    agent-status.sh      ← Colors tmux tabs by Claude Code state.
    agent-windows.sh     ← Agent workflow: tmux + git worktrees.
    iterm2.plist
    vscode/
      settings.json
      keybindings.json
  claude/
    settings.json        ← Claude Code permissions and preferences.
    CLAUDE.md            ← User-level instructions for Claude.
```

### What goes where?

| I want to change...              | Edit this file               |
|----------------------------------|------------------------------|
| Zsh aliases or functions         | `nix/shell.nix`              |
| Git config                       | `nix/shell.nix`              |
| Add/remove a tmux plugin         | `nix/shell.nix`              |
| Tmux keybindings or theme        | `nix/dotfiles/tmux.conf`     |
| Vim settings                     | `nix/dotfiles/vimrc`         |
| VSCode settings                  | `nix/dotfiles/vscode/settings.json` |
| VSCode keybindings               | `nix/dotfiles/vscode/keybindings.json` |
| Dock, keyboard, Finder, trackpad | `nix/macos.nix`              |
| Add a package to ALL machines    | `nix/macos.nix`              |
| Add a server-only package        | `nix/hosts/server.nix`       |
| Powerlevel10k prompt             | `nix/dotfiles/p10k.zsh`      |
| iTerm2 settings                  | `nix/dotfiles/iterm2.plist`  |
| Claude Code settings             | `nix/claude/settings.json`   |
| Claude instructions              | `nix/claude/CLAUDE.md`       |
| Agent tmux coloring              | `nix/dotfiles/agent-status.sh` |
| Agent workflow functions          | `nix/dotfiles/agent-windows.sh` |

## What Nix Manages

### Packages
git, gh, jq, tmux, vim, uv, mise, htop, curl, wget (all machines)
nginx, postgresql, sqlite, yarn (server only)

### Dotfiles (symlinked into ~/)
.zshrc, .zshenv, .vimrc, .tmux.conf, .p10k.zsh, .gitignore_global,
.gitconfig (via ~/.config/git/config), .ssh/config,
VSCode settings.json + keybindings.json, iTerm2 plist

### macOS Settings
- Dock: autohide, small icons, no recents
- Keyboard: fast repeat (KeyRepeat=2, InitialKeyRepeat=15)
- Keyboard modifier keys: Caps Lock→Control, LCtrl→LCmd, LCmd→LOpt
- Keyboard shortcuts: Cmd+B for sidebar toggle
- Finder: show extensions, list view, path bar, status bar, folders first
- Trackpad: tap to click, two-finger right click
- Screen saver: require password immediately, 5 min idle
- Login: no guest account
- Screenshots: PNG to Desktop
- Server power: never sleep, wake on network, auto-restart after power failure

### Shell Setup
- Oh-my-zsh + Powerlevel10k (with MesloLGS NF font)
- Tmux with plugins (sensible, resurrect, continuum, yank, etc.)
- Node.js via mise (not nvm)
- Python via uv
- Java/sbt via mise

## What Nix Does NOT Manage

These need manual install/configuration:

### Applications (download manually)
- **1Password** — https://1password.com/downloads
- **Claude** — https://claude.ai/download
- **Google Chrome** — https://google.com/chrome
- **iTerm2** — https://iterm2.com (config is managed, app is not)
- **Rectangle** — https://rectangleapp.com
- **Slack** — https://slack.com/downloads/mac
- **Spotify** — https://spotify.com/download
- **Visual Studio Code** — https://code.visualstudio.com (config is managed, app is not)

### Manual Configuration
- **Rectangle** — Open, grant accessibility permissions, set meta key to cmd+ctrl
- **1Password** — Sign in, enable Safari extension
- **Slack** — Sign into workspaces
- **Claude Code** — Run `claude` in terminal to authenticate
- **GitHub CLI** — Run `gh auth login`
- **iTerm2** — Set font to **MesloLGS NF** in Preferences > Profiles > Text

### Settings NOT in Nix (set manually in System Settings)
- Desktop wallpaper
- Display resolution / scaling
- Wi-Fi / network config
- Notification preferences per app
- Default browser
- iCloud settings
- Sound / input-output devices
- Login items (which apps open at startup)

### Tools Managed Outside Nix
- **Node.js versions** — `mise use --global node@lts` (mise, not Nix)
- **Python versions** — `uv venv --python 3.13 .venv` (uv, not Nix)
- **Java/sbt** — `mise use --global java@temurin-17` (mise, not Nix)

## Claude Code Settings

Managed by Nix. Settings and CLAUDE.md are symlinked into `~/.claude/`
automatically on rebuild. Edit `nix/claude/settings.json` and `nix/claude/CLAUDE.md`.

## Old Machine Configs

Pre-Nix configs are preserved in the repo for reference:
- `macos/` — original Intel MacBook
- `macos_m1/` — M1 MacBook
- `macos_m2/` — M4 MacBook (most recent pre-Nix)
- `aws_linux/`, `debian/`, `ubuntu/` — Linux configs

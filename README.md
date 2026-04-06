# Dotfiles

Declarative system config for my Macs using [Nix](https://nixos.org/),
[nix-darwin](https://github.com/LnL7/nix-darwin), and
[home-manager](https://github.com/nix-community/home-manager).

## Quick Start (new machine)

```bash
# 1. Clone
git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles

# 2. Run setup (installs Nix, builds config)
cd ~/Projects/dotfiles/nix && bash setup.sh        # defaults to "server"
cd ~/Projects/dotfiles/nix && bash setup.sh work    # for work machine

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

## Wallpaper

The Sombrero Galaxy (Messier 104) is around 30 million light-years away in the Virgo constellation. Tilted nearly edge-on from Earth we see it as a broad-brimmed hat. It contains 100 billion stars — similar to the Milky Way — and a supermassive black hole at its center about 9 billion times the mass of our sun. The bright white glow is the galaxy's dense core of billions of older stars. Around that is an orbiting dustring of carbon and silicon mixed with hydrogen and helium gas, where new stars are still forming. Over billions of years, the galaxy will exhaust its gas and dust, star formation will cease, and its stars will slowly burn out one by one, leaving it a dim, reddening ghost. The source image is a Hubble Space Telescope mosaic from 2003, reprocessed in 2025 for Hubble's 35th anniversary.

[original](esahubble.org/images/heic2506a)

```bash
convert ~/Downloads/sombrero_2025_hubble.tif \
  -level 55%,100% \
  -gravity center \
  -crop 16:9 +repage \
  -resize 7680x4320 \
  ~/Downloads/sombrero_2025_55p.png
```

- `-level {black_point%} {white_point%}`
  - black point: take everything X% brightness and lower and crush it to pure black. Take the remaining X% to 100% and stretch it to 0 to 100%.
  - white point: similar but on the hight end
- `-gravity center` set the anchor point
- `crop 16:9` crop to a particular ratio
- `+repage` retain metadata about the original image
- `-resize` re-scale the image respecting aspect ratio if set
- infers the output file type from the output path and respects it
- other ones I could care about
  - `-gamma` darkens midtones instead of the lowtones (kind of the opposite of level)
  - `-quality` if jpeg or some other lossy file type, affects quality
  - `-strip` strip metadata
  - `-colorspace` change the colorspace (most often want `sRGB`)
  - `-extent` pads instead of crops the image. pads with a color
  - `-modulate {brightness} {saturation} {hue}`


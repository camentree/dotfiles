Declarative system config for my Macs using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Layout

```
flake.nix           ← Entry point. Touch when adding a new machine.
user.nix            ← home-manager user config: git, tmux, symlinked dotfiles.
os/macos.nix        ← macOS system settings and packages shared across all machines.
machines/           ← Per-machine modules (hostname, packages, machine-only config).
home/               ← Plain dotfiles. Edit directly, then rebuild.
claude/             ← Claude Code settings and instructions (symlinked into ~/.claude/).
setup.sh            ← First-time bootstrap for a new Mac.
```

### What goes where

| To change... | Edit this |
| --- | --- |
| Zsh aliases / functions | `home/zshrc` |
| Git config | `user.nix` (`programs.git.settings`) |
| Tmux plugins | `user.nix` (`programs.tmux.plugins`) |
| Tmux keybindings | `home/tmux.conf` |
| Neovim | `home/nvim/init.lua` |
| VSCode settings / keybindings | `home/vscode/` |
| Ghostty | `home/ghostty` |
| Starship prompt | `home/starship.toml` |
| macOS defaults (dock, finder, keyboard) | `os/macos.nix` |
| Packages on every machine | `os/macos.nix` (`environment.systemPackages`) |
| Packages on one machine | `machines/<name>.nix` |
| Claude Code settings | `claude/settings.json` |
| Claude user-level instructions | `claude/CLAUDE.md` |

## Color palette

| Hex | Role |
| --- | --- |
| `#1c1a1e` | background |
| `#d5d0cb` | foreground (body text) |
| `#e06c75` | red / coral |
| `#98c379` | green |
| `#e5c07b` | yellow |
| `#7ec8e3` | blue |
| `#c678dd` | purple |
| `#86c9c0` | teal |
| `#b0aaa0` | light grey |

## First-time setup (new Mac)

Prereqs:
1. **Xcode Command Line Tools** — `xcode-select --install`
2. **Clone** — `git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles`

Bootstrap:
```bash
cd ~/Projects/dotfiles
bash setup.sh mac-arm-work    # or mac-arm-personal, mac-intel-server
```

Restart the terminal. From then on, after any config change:
```bash
nix-rebuild mac-arm-work
```

## Applications to install manually

Nix manages configs but not GUI apps (no Homebrew casks).

### All machines

- [1Password](https://1password.com/downloads) (+ Safari extension from App Store)
- [Claude](https://claude.ai/download)
- [Google Chrome](https://google.com/chrome)
- [Ghostty](https://ghostty.org)
- [Notion](https://notion.so/desktop)
- [Rectangle](https://rectangleapp.com)
- [Slack](https://slack.com/downloads/mac)
- Tadama (App Store)
- [VS Code](https://code.visualstudio.com)
- [Zoom](https://zoom.us/download)

### `mac-arm-work` only

- [Podman Desktop](https://podman-desktop.io)
- [Tuple](https://tuple.app/downloads)

## Manual configuration

### All machines

- **Rectangle** — grant accessibility permissions; set meta key to `cmd+ctrl`
- **1Password** — sign in; enable Safari extension; unset `cmd+\` autofill shortcut
- **1Password SSH Agent** — Settings → Developer → enable "SSH Agent", set display to "key names"
- **SSH key** — in 1Password, create an Ed25519 SSH Key item if one doesn't exist
- **Slack** — sign into workspaces
- **Claude Code** — run `claude` to authenticate
- **GitHub CLI** — `gh auth login`
- **Base Python venv** — `mkdir -p ~/.venvs && uv venv --python 3.13 ~/.venvs/base3.13`
- **Mail shortcuts** — System Settings → Keyboard → App Shortcuts → Mail:
  - "Mailbox Search" → `Cmd+\`
  - "Send" → `Ctrl+Cmd+Return`
- **Desktop wallpaper** — set to `sombrero_2025_45p.png`

### `mac-arm-work` only

- **AWS CLI** — `aws configure` or set up SSO in `~/.aws/config`
- **Podman** — `podman machine init && podman machine start`

### `mac-intel-server` only

- **Remote Login** — System Settings → General → Sharing → Remote Login
- **GPU switching** — the AMD Radeon Pro 5500M causes GPU restart storms when active headless. Disable it when running as a server: `switch-gpu-off`. Re-enable before connecting a monitor: `switch-gpu-on`. (Aliases defined in `~/.zshenv.local`.)

## Tools managed outside Nix

- Node.js — `mise use --global node@lts`
- Java / sbt — `mise use --global java@temurin-17`
- Python venvs — `uv venv --python 3.13 .venv`

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
  - white point: similar but on the high end
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

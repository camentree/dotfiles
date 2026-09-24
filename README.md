Declarative system config for my Macs using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [home-manager](https://github.com/nix-community/home-manager).

## Layout

```
flake.nix           ← Entry point. Touch when adding a new machine.
user.nix            ← home-manager user config: git, tmux, symlinked dotfiles.
os/macos.nix        ← macOS system settings and packages shared across all machines.
os/server.nix       ← Home-server services (tunnel, nginx, apps, deploys, backups); imported by *-server machines.
machines/           ← Per-machine modules (hostname, packages, machine-only config).
home/               ← Plain dotfiles. Edit directly, then rebuild.
claude/             ← Claude Code settings and instructions (symlinked into ~/.claude/).
setup.sh            ← First-time bootstrap for a new Mac.
SHORTCUTS.md        ← iCloud links for Shortcuts.app, which Nix can't install.
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

## Setting up a new Mac from scratch

### 1. Get GitHub access

1. Sign in to the Apple ID / iCloud and let the Mac finish its first-boot updates.
2. Install [1Password](https://1password.com/downloads), sign in, and enable the SSH agent (Settings → Developer → "Use the SSH agent"). The SSH key already lives in 1Password; no key on disk is needed.
3. Point SSH at the agent until Nix takes over `~/.ssh/config`:
   ```bash
   mkdir -p ~/.ssh && printf 'Host *\n\tIdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"\n' > ~/.ssh/config
   ssh -T git@github.com   # should say "successfully authenticated"
   ```
4. Install the Xcode Command Line Tools (this also provides `git`): `xcode-select --install`

### 2. (New machine only) Add it to the flake

Skip this step if the machine already has a file in `machines/`.

1. Create `machines/<name>.nix`, copying the closest existing machine. For a server, import `../os/server.nix` and keep only hardware-specific settings in the machine file (platform, network ports, `pmset`).
2. Register it in `flake.nix` under `darwinConfigurations`.
3. Optional: add `home/locals/zshrc-local-<name>` for machine-only aliases, and a `Host` entry in `user.nix` (`.ssh/config`).
4. **`git add` the new files.** Flakes only see files that git tracks, so an untracked machine file fails with "path does not exist".

### 3. Bootstrap

```bash
git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
bash setup.sh <machine-name>    # mac-arm-work, mac-arm-personal, mac-arm-server, mac-intel-server
```

Run this from a real terminal (Terminal.app or Ghostty), not through an agent: it prompts for your sudo password. It installs Nix, moves aside the `/etc` shell files nix-darwin takes over, builds and activates the machine config, then installs mise runtimes where they apply.

Afterwards, restart the terminal (or log out and back in so the key remapping takes effect). From then on, after any config change:
```bash
nix-rebuild
```

### 4. Finish by hand

Work through [Applications to install manually](#applications-to-install-manually) and [Manual configuration](#manual-configuration) below for this machine.

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
- **Full Disk Access for the terminal** — System Settings → Privacy & Security → Full Disk Access → add the terminal you run `nix-rebuild` from, then rebuild. Without it the rebuild can't write `com.apple.universalaccess`, so the Nix-managed App Shortcuts work but don't show up in System Settings.
- **Finder sidebar** — Favorites: Applications, Downloads, Pictures, Desktop, Documents. Locations: remove AirDrop and Macintosh HD. Stored in binary `.sfl4` bookmark files Nix can't write.
- **iCloud Desktop & Documents** — System Settings → Apple Account → iCloud → Drive → on.
- **Mail signature** — Mail → Settings → Signatures → "camen". Mail owns the signature files.
- **Contacts shortcuts** — System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts → Contacts: "Show Lists" and "Hide Lists" → `Cmd+B`. Contacts' preferences sit behind the Contacts privacy permission, which even Full Disk Access doesn't grant, so Nix can't write them.
- **Game Center** — System Settings → Game Center → off. It's an account sign-in, not a setting Nix can write.
- **Desktop wallpaper** — set to `sombrero_2025_45p.png`

### `mac-arm-work` only

- **AWS CLI** — `aws configure` or set up SSO in `~/.aws/config`
- **Podman** — `podman machine init && podman machine start`

### Servers (`mac-arm-server`, `mac-intel-server`)

Only one server runs the tunnel, apps, deploys, and jobs: the one named by `activeServer` in `os/server.nix` (exposed as `$ACTIVE_SERVER`). Every server still runs postgres and its own rsnapshot backups. To cut over, finish the steps below on the new machine, change `activeServer`, commit, and `nix-rebuild` on **both** machines, the old one first so it drops the tunnel.

- **Automatic login** — System Settings → Users & Groups → Automatically log in as `camen`, once. `os/server.nix` sets the user, but macOS only logs in automatically once this step has saved the password to `/etc/kcpassword`. The services are launchd *user* agents, so they only run while the user is logged in. Remote Login is on via `os/server.nix`; password logins are disabled there too, so only the key in `os/macos.nix` works.
- **Cloudflare tunnel** — `~/.cloudflared/config.yml` and its credentials JSON (not in the repo).
- **Failure-alert email** — Gmail app password in `~/.mail/password` (`chmod 600`).
- **App repos** — clone `one-offs`, `parallax`, `todo`, and `home-assistant` into `~/Projects/`, each with its `.env`. The deploy/serve agents fail until these exist.

### `mac-intel-server` only

- **GPU switching** — the AMD Radeon Pro 5500M causes GPU restart storms when active headless. Disable it when running as a server: `switch-gpu-off`. Re-enable before connecting a monitor: `switch-gpu-on`. (Aliases defined in `home/locals/zshrc-local-mac-intel-server`.)

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

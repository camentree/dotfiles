# Manual Setup

Steps and applications that need manual installation or configuration after
running `setup.sh`.

## Prerequisites

Before running `setup.sh`:

1. **Xcode Command Line Tools** — `xcode-select --install` (follow the dialog)
2. **Clone dotfiles** —
   `git clone git@github.com:camentree/dotfiles.git ~/Projects/dotfiles`

## First-time setup

```bash
cd ~/Projects/dotfiles/nix
bash setup.sh mac-arm-work
```

After setup completes, restart your terminal. For future config changes:

```bash
cd ~/Projects/dotfiles/nix
nix-rebuild mac-arm-work
```

## Applications to Install

- **1Password** — https://1password.com/downloads
  - Also install the Safari extension (1Password for Safari) from the App Store
- **Claude** — https://claude.ai/download
- **Google Chrome** — https://google.com/chrome
- **Ghostty** — https://ghostty.org
- **Notion** — https://notion.so/desktop
- **Podman Desktop** — https://podman-desktop.io
- **Rectangle** — https://rectangleapp.com
- **Slack** — https://slack.com/downloads/mac
- **Tadama** — App Store
- **Tuple** — https://tuple.app/downloads
- **Visual Studio Code** — https://code.visualstudio.com
- **Zoom** — https://zoom.us/download

## Post-setup

- **Base Python venv** —
  `mkdir -p ~/.venvs && uv venv --python 3.13 ~/.venvs/base3.13`

## Manual Settings

- **Rectangle** — Open and grant accessibility permissions, configure preferred
  shortcuts, set meta key to cmd+ctrl
- **1Password** — Sign in, enable Safari extension, unset `cmd + \` autofill
  shortcut
- **Slack** — Sign into workspaces
- **Claude Code** — Run `claude` in terminal to authenticate
- **GitHub CLI** — Run `gh auth login` to authenticate
- **AWS CLI** — Run `aws configure` or set up SSO in `~/.aws/config`
- **1Password SSH Agent** — 1Password → Settings → Developer → enable
  "SSH Agent". Set display to "key names".
- **SSH key** — In 1Password, create an SSH Key item (Ed25519) if one doesn't
  exist
- **Podman** — Run `podman machine init && podman machine start`
- **Mail** — Add keyboard shortcuts via System Settings > Keyboard > Keyboard
  Shortcuts > App Shortcuts > Mail.app:
  - "Mailbox Search" → `Cmd+\`
  - "Send" → `Ctrl+Cmd+Return`
- **macOS** — Set desktop background

## Server-specific (mac-intel-server)

- **Remote Login** — Enable SSH access: System Settings → General → Sharing →
  Remote Login

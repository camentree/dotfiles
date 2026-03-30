# Nix Setup Guide — Intel MacBook Pro Server

## What is Nix?

Nix is a **declarative package manager**. Instead of running `brew install X` and hoping
you remember what you installed, you describe your entire system in config files. Nix
reads those files and makes your system match them — every time, reproducibly.

Three pieces work together on your server:

| Component | What it does |
|-----------|-------------|
| **Nix** (the package manager) | Downloads and builds packages into `/nix/store/`. Every package gets its own unique path (like `/nix/store/abc123-git-2.44.0/`), so nothing ever conflicts. |
| **nix-darwin** | A macOS-specific layer that manages system config: packages available to all users, macOS defaults (dock, keyboard), launchd services, etc. Think of it as "NixOS, but for Mac." |
| **home-manager** | Manages your user-level config: dotfiles (.zshrc, .vimrc, .tmux.conf), user packages, shell setup. It symlinks everything into place from the nix store. |

## How Your Config is Structured

```
~/Documents/dotfiles/nix/
├── flake.nix             ← Entry point. Wires machines together.
├── macos.nix             ← macOS settings shared across ALL machines.
├── shell.nix             ← User config: zsh, git, tmux, vim, vscode, claude.
├── hosts/
│   └── server.nix        ← Server-only: nginx, postgres, always-on power.
├── dotfiles/             ← Raw config files. Edit directly, then `rebuild`.
├── claude/               ← Claude Code settings and instructions.
└── flake.lock            ← Auto-generated version pins.
```

## The Key Concept: Declarative vs Imperative

**Before (Homebrew/dotfiles — imperative):**
```bash
brew install git          # Run a command, hope it works
ln -s dotfiles/.zshrc ~   # Manually symlink
defaults write ...        # Run a defaults command
# Months later: "what did I install again?"
```

**Now (Nix — declarative):**
```nix
# darwin.nix — just list what you want
environment.systemPackages = with pkgs; [
  git
  tmux
  jq
];
```
Then run `darwin-rebuild switch` and Nix makes it so. Your config files ARE the source
of truth — if it's not in the config, it's not on the system.

## Common Tasks

### Add a new package

1. Open `~/Documents/dotfiles/nix/macos.nix` (for common packages) or
   `~/Documents/dotfiles/nix/hosts/server.nix` (for server-only packages)
2. Add the package name to the `environment.systemPackages` list
3. Rebuild:
   ```bash
   cd ~/Documents/dotfiles/nix && darwin-rebuild switch --flake .#server
   ```

**Finding package names:** Go to https://search.nixos.org/packages and search.

### Edit a dotfile

There are two kinds:

**Simple dotfiles** (managed inline in shell.nix):
- Git config, SSH config, zsh aliases/functions
- Edit directly in `shell.nix`, then rebuild

**Complex dotfiles** (raw files in dotfiles/):
- tmux.conf, vimrc, p10k.zsh, VSCode settings
- Edit the file in `~/Documents/dotfiles/nix/dotfiles/`, then rebuild

After any change:
```bash
cd ~/Documents/dotfiles/nix && darwin-rebuild switch --flake .#server
```

### Change a macOS default

Look in `macos.nix` under `system.defaults` (for nix-darwin native options) or
`system.activationScripts` (for raw `defaults write` commands).

Available native options: https://daiderd.com/nix-darwin/manual/index.html

### Rebuild after changes

This is the only command you need to remember:

```bash
cd ~/Documents/dotfiles/nix && darwin-rebuild switch --flake .#server
```

This will:
1. Evaluate your config
2. Download/build any new packages
3. Symlink dotfiles into place
4. Apply macOS defaults
5. Restart any affected services

**Shortcut:** Add an alias! It's already not in the config, so you could add to
the `initExtra` section in home.nix:
```nix
alias rebuild="cd ~/Documents/dotfiles/nix && darwin-rebuild switch --flake .#server"
```

### Update all packages

```bash
cd ~/Documents/dotfiles/nix
nix flake update          # Updates flake.lock to latest versions
darwin-rebuild switch --flake .#server
```

This is like `brew update && brew upgrade` but declarative — the new versions are
recorded in `flake.lock` so you can always see what changed (via git diff).

### Rollback to previous state

Every `darwin-rebuild switch` creates a new "generation." To go back:

```bash
# List generations
darwin-rebuild --list-generations

# Roll back to previous
sudo darwin-rebuild switch --rollback
```

This is one of Nix's superpowers — you can never brick your system. Every previous
state is preserved and instantly switchable.

### Search for available packages

```bash
nix search nixpkgs <name>
```

Or use the web search: https://search.nixos.org/packages

## How Dotfiles Work Under the Hood

When you write this in home.nix:
```nix
home.file.".vimrc".source = ./dotfiles/vimrc;
```

Nix does this:
1. Copies `dotfiles/vimrc` into `/nix/store/xxxx-home-manager-files/.vimrc`
2. Creates a symlink: `~/.vimrc → /nix/store/xxxx-home-manager-files/.vimrc`

So `~/.vimrc` is a symlink, not a regular file. If you `cat ~/.vimrc` it works
normally, but `ls -la ~/.vimrc` will show it pointing into the nix store.

**Don't edit symlinked files directly** — edit the source in `~/nix-config/` and rebuild.

## What Nix Does NOT Manage

These things are managed by their own tools, not Nix:

| Tool | Manages | How to use |
|------|---------|-----------|
| **uv** | Python versions and virtual environments | `uv venv --python 3.13 .venv` |
| **nvm** | Node.js versions | `nvm install --lts` |
| **mise** | Java, sbt, and other runtimes | `mise use --global java@temurin-17` |

Nix installs these tools, but they manage their own ecosystems.

## Nix Store Basics

All packages live in `/nix/store/`. Each package has a unique hash in its path:
```
/nix/store/abc123def-git-2.44.0/bin/git
/nix/store/xyz789ghi-tmux-3.4/bin/tmux
```

- Packages are **immutable** — once built, they never change
- Multiple versions can coexist (no conflicts)
- Unused packages can be cleaned up: `nix-collect-garbage -d`
- The store can get large over time; garbage collect periodically

## Quick Reference

| Task | Command |
|------|---------|
| Rebuild after config change | `cd ~/Documents/dotfiles/nix && darwin-rebuild switch --flake .#server` |
| Update all packages | `nix flake update && darwin-rebuild switch --flake .#server` |
| Search for a package | `nix search nixpkgs <name>` |
| Roll back | `sudo darwin-rebuild switch --rollback` |
| List generations | `darwin-rebuild --list-generations` |
| Garbage collect old packages | `nix-collect-garbage -d` |
| Check what's installed | Look at `macos.nix`, `shell.nix`, and `hosts/` — they ARE the list |

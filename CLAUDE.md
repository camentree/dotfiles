# Dotfiles

Declarative Mac config via Nix (nix-darwin + home-manager). This repo **is** the source of truth for the user's machines — packages, macOS defaults, dotfiles, and Claude Code settings.

## Layout

```
flake.nix           Entry point; lists machines.
user.nix            home-manager user config (git, tmux, symlinks).
os/macos.nix        Shared macOS settings + packages.
machines/*.nix      Per-machine: hostname + packages.
home/               Plain dotfiles — symlinked into $HOME as-is.
claude/             Claude Code global config — symlinked to ~/.claude/.
setup.sh            First-time bootstrap for a new Mac.
```

Full layout and user-facing docs: see `README.md`.

## Deploying changes

Nothing takes effect until you rebuild. Config edits are inert otherwise.

```bash
nix-rebuild <machine-name>          # e.g. nix-rebuild mac-arm-work
```

Available machines are defined in `flake.nix` → `darwinConfigurations`.

The `nix-rebuild` function is defined in `home/zshrc`; it runs `darwin-rebuild switch --flake ~/Projects/dotfiles#<machine>`.

### Where config lives — don't edit the symlinks

Most files in `$HOME` are symlinks into the Nix store. Never edit `~/.zshrc`, `~/.config/nvim/init.lua`, `~/.claude/settings.json`, etc. directly — edit the source under this repo and rebuild. `lazy-lock.json` is the one intentional exception (symlinked via activation script to the repo file so lazy.nvim can write to it).

### Two flavors of dotfile management

1. **Inline in `user.nix`** — for small configs Nix can render natively (git, ssh/config, tmux plugin list, the `.nix-paths.sh` bridge file).
2. **Plain files in `home/`** — for large or complex configs edited as regular files (zshrc, nvim init.lua, starship.toml, tmux.conf, vscode/, ghostty). `user.nix` maps each one to its destination via `home.file`.

When adding a new dotfile: drop the file in `home/`, then add a `home.file.".foo" = { source = ./home/foo; force = true; };` entry in `user.nix`.

### Adding a package

- All machines → `os/macos.nix` `environment.systemPackages`
- One machine → `machines/<name>.nix` `environment.systemPackages`
- Search names at <https://search.nixos.org/packages>

### Adding a machine

Add a new `.nix` file in `machines/`, then register it in `flake.nix` under `darwinConfigurations`.

## Testing changes

There's no CI and no unit tests — the feedback loop is `nix-rebuild`. It typechecks the flake, downloads/builds anything new, and applies everything. If it fails, it fails cleanly and leaves the previous generation untouched.

Quick sanity check without switching:
```bash
nix flake check
```

## Code style

- **Preserve comments.** Don't strip existing comments when editing, even during restructuring. Section-header comments (`# ===== Foo =====`) are intentional structure.
- **Custom theming, hex colors.** No pre-made themes (catppuccin etc.). Use hex (`#86c9c0`), keep Ghostty / Starship / nvim visually consistent.
- **Minimalism over config sprawl.** This repo should stay small and legible; avoid adding abstractions (helper functions, shared modules) until there's repeated pain.

## Gotchas

- **`force = true`** on a `home.file` entry tells home-manager to overwrite an existing real file. Needed the first time you're replacing a pre-Nix dotfile; safe to leave on thereafter.
- **`home-manager.backupFileExtension = "pre-nix-backup"`** (in `flake.nix`) — home-manager will rename conflicting files to `*.pre-nix-backup` instead of failing. If a rebuild complains about existing files, look for these.
- **Secrets** never go in the repo. Machine-specific secrets live in `~/.zshenv.local` (gitignored, sourced from `home/zshenv`).
- **Runtime versions** (Node, Java, sbt, Python venvs) are managed by mise/uv, not Nix. See the `[5/6]` step in `setup.sh`.
- **Claude Code `settings.local.json`** (both root `.claude/` and per-project) is gitignored-esque: it holds machine-local permission allowlists. `setup.sh` also writes one to `~/.claude/settings.local.json` on first run with the right `JAVA_HOME`.

## Do not

- Commit `.zshenv.local` or anything with real secrets.
- Hardcode absolute paths that aren't `$HOME`-relative. Use `./relative/paths` inside Nix files and `$HOME` / `$THIS_DIR` in shell scripts.
- Run `brew install` or ad-hoc `defaults write` — those changes get clobbered on the next rebuild. Add them to the Nix config instead.

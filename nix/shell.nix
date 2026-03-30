{ config, pkgs, lib, ... }:

{
  home.username = "camen";
  home.homeDirectory = "/Users/camen";
  home.stateVersion = "24.11";

  # ============================================================
  # Fonts
  # ============================================================
  home.packages = with pkgs; [
    meslo-lgs-nf
  ];

  # ============================================================
  # Git (using new settings-based API)
  # ============================================================
  programs.git = {
    enable = true;
    signing.format = null;
    settings = {
      user = {
        name = "Camen";
        email = "29082904+camentree@users.noreply.github.com";
      };
      core.excludesfile = "${config.home.homeDirectory}/.gitignore_global";
      pull.rebase = false;
      push.autoSetupRemote = true;
      alias = {
        cm = "commit";
        co = "checkout";
        st = "status";
        br = "branch";
      };
    };
  };

  # ============================================================
  # Vim
  # ============================================================
  home.file.".vimrc".source = ./dotfiles/vimrc;

  # ============================================================
  # Agent scripts (Claude Code + tmux + git worktrees)
  # ============================================================
  home.file."agent-status.sh".source = ./dotfiles/agent-status.sh;
  home.file."agent-windows.sh".source = ./dotfiles/agent-windows.sh;

  # ============================================================
  # Tmux — plugins managed by Nix (no TPM needed)
  # ============================================================
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/tmux.conf;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      yank
      pain-control
      copycat
      open
      battery
      cpu
      vim-tmux-navigator
      net-speed
    ];
  };

  # ============================================================
  # Powerlevel10k
  # ============================================================
  home.file.".p10k.zsh".source = ./dotfiles/p10k.zsh;

  # ============================================================
  # Gitignore global
  # ============================================================
  home.file.".gitignore_global" = {
    source = ./dotfiles/gitignore_global;
    force = true;
  };

  # ============================================================
  # Zsh
  # ============================================================
  programs.zsh = {
    enable = true;

    # .zshenv — sourced by ALL zsh invocations
    envExtra = ''
      # mise (manages node, java, sbt, etc.)
      if command -v mise &> /dev/null; then
        eval "$(mise activate zsh)"
      fi

      # Apple Shortcuts sets this variable which crashes JVM native socket binding
      unset DIRHELPER_USER_DIR_SUFFIX

      # Base python virtual environment
      export VIRTUAL_ENV="$HOME/.venvs/base3.13"
      export PATH="$VIRTUAL_ENV/bin:$PATH"

      # Machine-specific overrides and secrets (not tracked in git)
      [[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
    '';

    # oh-my-zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "history" ];
    };

    # .zshrc content (using initContent with mkBefore/mkAfter for ordering)
    initContent = lib.mkMerge [
      # Early init — must run before oh-my-zsh
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Main config — runs after oh-my-zsh
      ''
        # Powerlevel10k theme — must be sourced after oh-my-zsh
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        # Aliases
        alias pyc="rm **/*.pyc; rm -rf **/__pycache__"
        alias cov-clean="rm .coverage.*"
        alias git-open="open \`git config --get remote.origin.url\`"
        alias vd="deactivate"
        alias rebuild="cd ~/Documents/dotfiles/nix && sudo \$(which darwin-rebuild) switch --flake .#server"

        # Functions
        function loadenv () { set -o allexport; source "''${1:-.env}"; set +o allexport ; }
        function git-clean () { git branch | grep -v "master\|main\|*" | xargs git branch -D ; }
        function ls-ports () { lsof -PiTCP -sTCP:LISTEN ; }
        function touch2 () { mkdir -p "$(dirname "$1")" && touch "$1" ; }

        # Python virtual environment helpers (uv-based)
        function vn () {
          local python="''${1:-3.13}"
          uv venv --python "$python" ".venv"
          echo "Created .venv (python $python)"
          source .venv/bin/activate
        }
        function va () { source .venv/bin/activate ; }
        function vdd () {
          deactivate 2>/dev/null
          rm -rf .venv
          echo "Removed .venv"
        }

        # Key bindings
        bindkey "^X\\x7f" backward-kill-line
        bindkey "^X^_" redo

        # Add hostname to prompt
        PROMPT="%{$fg[green]%}%m%{$reset_color%} ''${PROMPT}"

        # Load p10k config
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # Remove . from word characters so Option+Delete stops at periods
        WORDCHARS=''${WORDCHARS//.}

        # Agent workflow (tmux + git worktrees)
        [[ -f ~/agent-windows.sh ]] && source ~/agent-windows.sh
      ''
    ];
  };

  # ============================================================
  # VSCode
  # ============================================================
  home.file."Library/Application Support/Code/User/settings.json" = {
    source = ./dotfiles/vscode/settings.json;
    force = true;
  };
  home.file."Library/Application Support/Code/User/keybindings.json" = {
    source = ./dotfiles/vscode/keybindings.json;
    force = true;
  };

  # ============================================================
  # iTerm2 plist
  # ============================================================
  home.file."com.googlecode.iterm2.plist".source = ./dotfiles/iterm2.plist;

  # ============================================================
  # Claude Code
  # ============================================================
  home.file.".claude/settings.json" = {
    source = ./claude/settings.json;
    force = true;
  };
  home.file.".claude/CLAUDE.md" = {
    source = ./claude/CLAUDE.md;
    force = true;
  };

  # ============================================================
  # SSH config (preserve what we already set up)
  # ============================================================
  home.file.".ssh/config" = {
    text = ''
      Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519

      Host *
        AddKeysToAgent yes
        UseKeychain yes
    '';
  };

  # ============================================================
  # Local env file template
  # ============================================================
  home.file.".zshenv.local" = {
    text = ''
      # Machine-specific environment variables and secrets
      # This file is gitignored and not tracked in dotfiles
    '';
    # Don't overwrite if it already exists with user secrets
    force = false;
  };
}

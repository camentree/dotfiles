{ config, pkgs, lib, ... }:

let
  dotfilesRepo = "${config.home.homeDirectory}/Projects/dotfiles";
  liveLink = relativePath: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesRepo}/${relativePath}";
    force = true;
  };
in
{
  home.username = "camen";
  home.homeDirectory = "/Users/camen";
  home.stateVersion = "24.11";

  # ============================================================
  # Packages (user-level)
  # ============================================================
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono  # font for terminal / editor
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];

  # ============================================================
  # Git
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
      push.default = "current";
      rerere.enabled = true;
      # /model and /effort write into claude/settings.json; strip them on the way
      # into the index so the file stays clean (see .gitattributes).
      filter.claude-settings.clean = "jq --indent 2 'del(.model, .effortLevel)'";
      alias = {
        cm = "commit";
        co = "checkout";
        st = "status";
        br = "branch";
      };
    };
  };

  # ============================================================
  # GitHub CLI — extensions are Nix-managed; `gh extension install` won't stick
  # ============================================================
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
    extensions = [
      (pkgs.stdenvNoCC.mkDerivation rec {
        pname = "gh-stack";
        version = "0.1.1";
        src = pkgs.fetchurl {
          url = "https://github.com/github/gh-stack/releases/download/v${version}/${
            {
              aarch64-darwin = "darwin-arm64";
              x86_64-darwin = "darwin-amd64";
            }.${pkgs.stdenv.hostPlatform.system}
          }";
          hash = {
            aarch64-darwin = "sha256-8Jqssu5y/bHUAe5PW5DgYpGahS/Dx7Zr8bGoUxBGF9g=";
            x86_64-darwin = "sha256-QHQPgmRcKMTh2kfGvQKmrEl9OCpFfBCTaUozaxdQr3E=";
          }.${pkgs.stdenv.hostPlatform.system};
        };
        dontUnpack = true;
        installPhase = "install -Dm755 $src $out/bin/gh-stack";
      })
    ];
  };

  # ============================================================
  # Tmux — plugins managed by Nix, config is a plain dotfile
  # ============================================================
  programs.tmux = {
    enable = true;
    extraConfig = builtins.readFile ./home/tmux.conf;
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
  # Dotfiles — plain files, live-symlinked into ~/ via liveLink.
  # Edit these directly; changes take effect without a rebuild.
  # A rebuild is only needed to add, rename, or remove a file.
  # ============================================================
  home.file = {
    ".zshrc"             = liveLink "home/zshrc";
    ".zshenv"            = liveLink "home/zshenv";
    ".vimrc"             = liveLink "home/vimrc";
    ".gitignore_global"  = liveLink "home/gitignore_global";
    ".prettierrc"        = liveLink "home/prettierrc";
    ".ipython/profile_default/startup/00-imports.py" = liveLink "home/ipython_startup_imports.py";

    # Starship prompt
    ".config/starship.toml" = liveLink "home/starship.toml";

    # Neovim (lazy-lock.json is live-linked too — lazy.nvim must be able to write it)
    ".config/nvim/init.lua"       = liveLink "home/nvim/init.lua";
    ".config/nvim/.stylua.toml"   = liveLink "home/nvim/.stylua.toml";
    ".config/nvim/lazy-lock.json" = liveLink "home/nvim/lazy-lock.json";

    # Ghostty terminal
    ".config/ghostty/config" = liveLink "home/ghostty";

    # VS Code
    "Library/Application Support/Code/User/settings.json" = liveLink "home/vscode/settings.json";
    "Library/Application Support/Code/User/keybindings.json" = liveLink "home/vscode/keybindings.json";

  } // (
    # settings.json is excluded here and symlinked via an activation script —
    # Claude Code's /effort et al. must be able to write it.
    # The ./claude path literal is used only to enumerate filenames; each entry
    # is then live-linked back to the working tree by relative path.
    let
      claudeRoot = toString ./claude;
      relativeTo = file: lib.removePrefix "${claudeRoot}/" (toString file);
    in builtins.listToAttrs (map (file: {
        name = ".claude/${relativeTo file}";
        value = liveLink "claude/${relativeTo file}";
      })
    (builtins.filter
        (file: relativeTo file != "settings.json")
        (lib.filesystem.listFilesRecursive ./claude)))
  ) // {

    # SSH
    ".ssh/config" = {
      text = ''
        Host github.com
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

        Host mac-intel-server
          HostName mac-intel-server.local
          User camen

        Host mac-arm-server
          HostName mac-arm-server.local
          User camen

        Host mac-intel-server-remote
          HostName ssh.smallworkshop.dev
          User camen
          ProxyCommand cloudflared access ssh --hostname=%h

        Host *
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
    };

  };

  # ============================================================
  # Activation scripts — for files that need to be writable
  # ============================================================
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ln -sfn $VERBOSE_ARG \
      ${dotfilesRepo}/claude/settings.json \
      ${config.home.homeDirectory}/.claude/settings.json
  '';
}

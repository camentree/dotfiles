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
      alias = {
        cm = "commit";
        co = "checkout";
        st = "status";
        br = "branch";
      };
    };
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

    # VSCode
    "Library/Application Support/Code/User/settings.json"    = liveLink "home/vscode/settings.json";
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
          RequestTTY yes
          RemoteCommand security unlock-keychain ~/Library/Keychains/login.keychain-db; exec $SHELL -l

        Host mac-intel-server-remote
          HostName ssh.smallworkshop.dev
          User camen
          ProxyCommand cloudflared access ssh --hostname=%h
          RequestTTY yes
          RemoteCommand security unlock-keychain ~/Library/Keychains/login.keychain-db; exec $SHELL -l

        Host *
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
    };

  };

  # ============================================================
  # Activation scripts — for files that need to be writable
  # ============================================================
  home.activation.sshAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.ssh
    $DRY_RUN_CMD chmod 700 ${config.home.homeDirectory}/.ssh
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKrlOuiKfCW1tb/8PHXms+N8hSSxO1Rfw3YAVPA8lRW' > ${config.home.homeDirectory}/.ssh/authorized_keys
    $DRY_RUN_CMD chmod 600 ${config.home.homeDirectory}/.ssh/authorized_keys
  '';

  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ln -sfn $VERBOSE_ARG \
      ${dotfilesRepo}/claude/settings.json \
      ${config.home.homeDirectory}/.claude/settings.json
  '';
}

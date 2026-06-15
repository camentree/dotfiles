# ============================================================
# Common config — shared across all machines
# ============================================================
{ pkgs, ... }:

{
  # ============================================================
  # Nix settings
  # ============================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # Shell
  # ============================================================
  programs.zsh.enable = true;

  # ============================================================
  # Users
  # ============================================================
  system.primaryUser = "camen";
  users.users.camen = {
    name = "camen";
    home = "/Users/camen";
  };

  # ============================================================
  # Packages — installed on every machine
  # ============================================================
  environment.systemPackages = with pkgs; [
    awscli2
    claude-code
    coursier
    curl
    fd
    gh
    git
    htop
    jq
    mise
    neovim
    nodejs_24
    nodePackages.prettier
    pandoc
    python3
    ripgrep
    ruff
    sqlite
    starship
    stylua
    tmux
    tree-sitter
    uv
    wget
  ];

  # ============================================================
  # macOS defaults
  # ============================================================
  system.defaults = {

    # Dock
    dock = {
      autohide = true;
      tilesize = 47;
      show-recents = false;
    };

    # Keyboard
    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
    };

    # Finder
    finder = {
      AppleShowAllExtensions = true;        # always show file extensions
      AppleShowAllFiles = false;             # don't show hidden files by default
      FXDefaultSearchScope = "SCcf";         # search current folder by default
      FXEnableExtensionChangeWarning = false; # don't warn when changing extensions
      FXPreferredViewStyle = "Nlsv";         # list view by default
      FXRemoveOldTrashItems = true;          # auto-remove trash after 30 days
      ShowPathbar = true;                    # show path breadcrumbs
      ShowStatusBar = true;                  # show status bar
      _FXSortFoldersFirst = true;            # folders on top when sorting by name
      _FXShowPosixPathInTitle = true;        # full path in window title
    };

    # Trackpad
    trackpad = {
      Clicking = true;                       # tap to click
      TrackpadRightClick = true;             # two-finger right click
      TrackpadThreeFingerDrag = false;
    };

    # Screen saver & lock
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 0;               # require password immediately
    };

    # Login window
    loginwindow = {
      GuestEnabled = false;                  # no guest account
    };

    # Screenshots
    screencapture = {
      location = "~/Desktop";
      type = "png";
    };
  };

  # ============================================================
  # macOS keyboard shortcuts and modifier keys
  # ============================================================
  system.activationScripts.postActivation.text = ''
    # Keyboard shortcuts: Cmd+B for sidebar toggle (global, Calendar, Notion)
    defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide Sidebar" "@b"
    defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Sidebar" "@b"
    defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Toggle Sidebar" "@b"
    defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Hide Calendar List" "@b"
    defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Show Calendar List" "@b"
    defaults write notion.id NSUserKeyEquivalents -dict-add "Show/Hide Sidebar" "@b"

    # Keyboard modifier keys: Caps Lock → Control, Left Control → Left Command, Left Command → Left Option
    defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771300</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer></dict>' \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771302</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771300</integer></dict>' \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771298</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771296</integer></dict>'

    # Mission Control + Spaces: Cmd+Option+Up, Cmd+Option+Left/Right
    # Modifier mask 1572864 = Command (0x100000) | Option (0x080000); key codes: 126=Up, 123=Left, 124=Right
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 '{enabled = 1; value = { parameters = (65535, 126, 1572864); type = "standard"; }; }'
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '{enabled = 1; value = { parameters = (65535, 123, 1572864); type = "standard"; }; }'
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '{enabled = 1; value = { parameters = (65535, 124, 1572864); type = "standard"; }; }'

    # Screen saver idle time (5 minutes)
    defaults -currentHost write com.apple.screensaver idleTime -int 300

    # Restart Finder to pick up changes
    killall Finder 2>/dev/null || true
  '';

  # ============================================================
  # Backwards compatibility
  # ============================================================
  system.stateVersion = 5;
}

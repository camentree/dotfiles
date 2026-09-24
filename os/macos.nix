# ============================================================
# Common config — shared across all machines
# ============================================================
{ config, pkgs, ... }:

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
    # Must live here, not in home-manager: a home.file ~/.ssh/authorized_keys is a
    # symlink into /nix/store, which is group-writable, so sshd's StrictModes refuses
    # to read it and every login fails with "Permission denied (publickey)". This
    # option writes /etc/ssh/nix_authorized_keys.d/camen, which sshd reads via the
    # AuthorizedKeysCommand nix-darwin already installs.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKrlOuiKfCW1tb/8PHXms+N8hSSxO1Rfw3YAVPA8lRW"
    ];
  };

  # ============================================================
  # Authentication
  # ============================================================
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
    reattach = true;
  };

  # ============================================================
  # Packages — installed on every machine
  # ============================================================
  environment.systemPackages = with pkgs; [
    _1password-cli
    awscli2
    blueutil
    coursier
    curl
    fd
    ffmpeg
    git
    htop
    jq
    lua-language-server
    neovim
    nodejs_24
    nodePackages.prettier
    pandoc
    pyright
    python3
    ripgrep
    ruff
    sqlite
    starship
    stylua
    tmux
    tree-sitter
    typescript-language-server
    uv
    vscode-langservers-extracted
    wget
    yarn
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
      persistent-apps = [];
      persistent-others = [];
    };

    NSGlobalDomain = {
      # Keyboard
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      # Appearance
      AppleInterfaceStyleSwitchesAutomatically = true;
      NSTableViewDefaultSizeMode = 2;        # medium sidebar icons
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
    # Activation runs as root with HOME=/var/root, so every user-domain write
    # below has to be re-targeted at the login user — nix-darwin wraps its own
    # `system.defaults` writes the same way. Without this they land in root's
    # preferences and silently do nothing.
    asPrimaryUser="launchctl asuser $(id -u -- ${config.system.primaryUser}) sudo --user=${config.system.primaryUser} --"

    # Keyboard shortcuts: Cmd+B for sidebar toggle (global, Notion)
    $asPrimaryUser defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide Sidebar" "@b"
    $asPrimaryUser defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Sidebar" "@b"
    $asPrimaryUser defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Toggle Sidebar" "@b"
    $asPrimaryUser defaults write notion.id NSUserKeyEquivalents -dict-add "Show/Hide Sidebar" "@b"

    # Keyboard shortcuts: Mail
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Get New Mail" "^r"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mark as Unread" "^u"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mark as Read" "^u"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Archive" "^a"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mailbox Search" '@$f'
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" '@\U21a9'

    # Keyboard shortcuts: Cmd+B for sidebar toggle (Calendar, Notes, Contacts)
    $asPrimaryUser defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Show Calendar List" "@b"
    $asPrimaryUser defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Hide Calendar List" "@b"
    $asPrimaryUser defaults write com.apple.Notes NSUserKeyEquivalents -dict-add "Show Folders" "@b"
    $asPrimaryUser defaults write com.apple.Notes NSUserKeyEquivalents -dict-add "Hide Folders" "@b"
    $asPrimaryUser defaults write com.apple.AddressBook NSUserKeyEquivalents -dict-add "Show Lists" "@b"
    $asPrimaryUser defaults write com.apple.AddressBook NSUserKeyEquivalents -dict-add "Hide Lists" "@b"

    # Tint window backgrounds with the wallpaper color
    $asPrimaryUser defaults write NSGlobalDomain AppleReduceDesktopTinting -bool false

    # Keyboard modifier keys: Caps Lock → Control, Left Control → Left Command, Left Command → Left Option
    # Takes effect at next login, not at rebuild.
    $asPrimaryUser defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771300</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771129</integer></dict>' \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771302</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771300</integer></dict>' \
      '<dict><key>HIDKeyboardModifierMappingDst</key><integer>30064771298</integer><key>HIDKeyboardModifierMappingSrc</key><integer>30064771296</integer></dict>'

    # Mission Control + Spaces: Cmd+Option+Up, Cmd+Option+Left/Right
    # Modifier mask 1572864 = Command (0x100000) | Option (0x080000); key codes: 126=Up, 123=Left, 124=Right
    $asPrimaryUser defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 32 '{enabled = 1; value = { parameters = (65535, 126, 1572864); type = "standard"; }; }'
    $asPrimaryUser defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 '{enabled = 1; value = { parameters = (65535, 123, 1572864); type = "standard"; }; }'
    $asPrimaryUser defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 '{enabled = 1; value = { parameters = (65535, 124, 1572864); type = "standard"; }; }'

    # Screen saver idle time (5 minutes)
    $asPrimaryUser defaults -currentHost write com.apple.screensaver idleTime -int 300

    # Restart Finder to pick up changes
    $asPrimaryUser killall Finder 2>/dev/null || true
  '';

  # ============================================================
  # Backwards compatibility
  # ============================================================
  system.stateVersion = 5;
}

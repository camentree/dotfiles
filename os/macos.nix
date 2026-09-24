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
      FXDefaultSearchScope = "SCev";         # search this Mac by default
      FXEnableExtensionChangeWarning = false; # don't warn when changing extensions
      FXPreferredViewStyle = "Nlsv";         # list view by default
      FXRemoveOldTrashItems = false;         # keep trash until emptied
      NewWindowTarget = "Home";              # new windows open the home folder
      ShowRemovableMediaOnDesktop = false;   # no external disks on the desktop
      ShowPathbar = true;                    # show path breadcrumbs
      ShowStatusBar = true;                  # show status bar
      _FXSortFoldersFirst = true;            # folders on top when sorting by name
      _FXShowPosixPathInTitle = true;        # full path in window title
    };

    # Calendar
    CustomUserPreferences."com.apple.iCal" = {
      "first day of week" = 2;
      "first minute of work hours" = 360;       # 6am
      "last minute of work hours" = 1320;       # 10pm
      "Default duration in minutes for new event" = 30;
      "scroll by weeks in week view" = 0;
      "Show heat map in Year View" = true;
      "TimeZone support enabled" = true;
      "WarnBeforeSendingInvitations" = false;
      "enableTravelAdvisoriesForAutomaticBehavior" = false;
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
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Get All New Mail" "^r"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mark as Unread" "^u"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mark as Read" "^u"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Archive" "^a"
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Mailbox Search" '@$f'
    $asPrimaryUser defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" '@\U21a9'

    # Keyboard shortcuts: Cmd+B for sidebar toggle (Calendar, Notes)
    # Contacts is set by hand (see README): its preferences sit behind the Contacts
    # privacy permission, which Full Disk Access doesn't cover, so `defaults write
    # com.apple.AddressBook` fails with "Could not write domain" and aborts activation.
    $asPrimaryUser defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Show Calendar List" "@b"
    $asPrimaryUser defaults write com.apple.iCal NSUserKeyEquivalents -dict-add "Hide Calendar List" "@b"
    $asPrimaryUser defaults write com.apple.Notes NSUserKeyEquivalents -dict-add "Show Folders" "@b"
    $asPrimaryUser defaults write com.apple.Notes NSUserKeyEquivalents -dict-add "Hide Folders" "@b"

    # System Settings only lists App Shortcuts for apps named here; the shortcuts
    # work without it. universalaccess needs Full Disk Access to write, so a
    # terminal without it shouldn't fail the rebuild.
    $asPrimaryUser defaults write com.apple.universalaccess com.apple.custommenu.apps -array \
      NSGlobalDomain notion.id com.apple.mail com.apple.iCal com.apple.Notes com.apple.AddressBook || true

    # Mail is sandboxed: `defaults write com.apple.mail` lands in ~/Library/Preferences,
    # which Mail ignores for its own settings, so write its container plists by path.
    # Needs Full Disk Access (see README), and Mail must have launched once.
    mailPrefs="${config.users.users.${config.system.primaryUser}.home}/Library/Containers/com.apple.mail/Data/Library/Preferences/com.apple.mail"
    mailGroupPrefs="${config.users.users.${config.system.primaryUser}.home}/Library/Group Containers/group.com.apple.mail/Library/Preferences/group.com.apple.mail"
    # SF Mono isn't in nixpkgs (Apple license) and macOS only ships it inside
    # Terminal.app, so copy it into the user's fonts for other apps to see.
    $asPrimaryUser cp /System/Applications/Utilities/Terminal.app/Contents/Resources/Fonts/SF-Mono-*.otf ${config.users.users.${config.system.primaryUser}.home}/Library/Fonts/

    $asPrimaryUser defaults write "$mailPrefs" NSFont -string SFMono-Regular || true
    $asPrimaryUser defaults write "$mailPrefs" NSFontSize -string 12 || true
    $asPrimaryUser defaults write "$mailPrefs" NSFixedPitchFont -string SFMono-Regular || true
    $asPrimaryUser defaults write "$mailPrefs" NSFixedPitchFontSize -string 11 || true
    $asPrimaryUser defaults write "$mailPrefs" ColorQuoterColorList "<data>$(cat ${./mail-quote-colors.b64})</data>" || true
    $asPrimaryUser defaults write "$mailPrefs" NumberOfSnippetLines -int 0 || true
    $asPrimaryUser defaults write "$mailPrefs" ConversationViewSortDescending -bool true || true
    $asPrimaryUser defaults write "$mailPrefs" HighlightCurrentThread -bool false || true
    $asPrimaryUser defaults write "$mailPrefs" ReplyQuotesOriginal -bool false || true
    $asPrimaryUser defaults write "$mailPrefs" SupressQuoteBarsInComposeWindows -bool true || true
    $asPrimaryUser defaults write "$mailPrefs" AddLinkPreviews -bool false || true
    $asPrimaryUser defaults write "$mailPrefs" PlayMailSounds -bool false || true
    $asPrimaryUser defaults write "$mailPrefs" NewMessagesSoundName -string "" || true
    $asPrimaryUser defaults write "$mailGroupPrefs" DisableAutomaticMessageSummarization -bool true || true
    $asPrimaryUser defaults write "$mailGroupPrefs" DisableFollowUp -bool true || true
    $asPrimaryUser defaults write "$mailGroupPrefs" MarkAsReadBehavior -int 3 || true

    # Finder: hide the sidebar Tags section, and clear the default color tags
    $asPrimaryUser defaults write com.apple.finder ShowRecentTags -bool false
    $asPrimaryUser defaults write com.apple.finder FavoriteTagNames -array ""
    $asPrimaryUser defaults write com.apple.finder WarnOnEmptyTrash -bool false

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

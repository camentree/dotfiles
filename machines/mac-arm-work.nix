# ============================================================
# Apple Silicon Mac — work laptop
# ============================================================
{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.variables.NIX_MACHINE = "mac-arm-work";

  # Work packages
  environment.systemPackages = with pkgs; [
    buf
    docker
    docker-compose
    imagemagick
    podman
    krunkit
    ngrok
    postgresql
    # nixpkgs builds snowflake-cli without boto3, so the AWS workload-identity
    # login abulafia uses crashes; add the connector's boto extra.
    (snowflake-cli.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ python3Packages.snowflake-connector-python.optional-dependencies.boto;
    }))
  ];

  launchd.user.agents.find-reviews = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.writeShellScriptBin "find-reviews" ''
          cd /Users/camen/Documents/notes
          exec /bin/zsh -lc "/Users/camen/.local/bin/claude -p /find-reviews --permission-mode acceptEdits --allowedTools 'Read' 'Edit' 'Write' 'Skill' 'Bash(gh:*)' 'Bash(jq:*)' 'Bash(osascript:*)' 'Bash(bash /Users/camen/.claude/scripts/chrome-tab-group.sh:*)'"
        ''}/bin/find-reviews"
      ];
      StartCalendarInterval = map (weekday: { Weekday = weekday; Hour = 8; Minute = 30; }) [ 1 2 3 4 5 ];
      StandardOutPath = "/tmp/find-reviews.stdout.log";
      StandardErrorPath = "/tmp/find-reviews.stderr.log";
    };
  };

  home-manager.users.camen = {
    # mise — version manager for node / java / sbt. Work machine only.
    # Writes ~/.config/mise/config.toml; shell activation lives in home/zshenv
    # (zsh here is a hand-managed dotfile, not home-manager's programs.zsh).
    programs.mise = {
      enable = true;
      enableZshIntegration = false;
      globalConfig = {
        tools = {
          java = "temurin-17.0.16+8";
          node = "lts";
          sbt = "1.12.5";
        };
        settings = {
          # Honor .nvmrc / .node-version (e.g. august-frontend pins Node there, not .tool-versions)
          idiomatic_version_file_enable_tools = [ "node" ];
        };
      };
    };
  };
}

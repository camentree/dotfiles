# ============================================================
# Apple Silicon Mac — work laptop
# ============================================================
{ pkgs, ... }:

let
  pgData = "/Users/camen/Library/Application Support/Postgresql/17";
  pgStart = pkgs.writeShellScript "postgres-start" ''
    set -e
    PGDATA="${pgData}"
    if [ ! -d "$PGDATA/base" ]; then
      mkdir -p "$PGDATA"
      ${pkgs.postgresql}/bin/initdb -D "$PGDATA" -U camen --encoding=UTF8
    fi
    exec ${pkgs.postgresql}/bin/postgres -D "$PGDATA"
  '';
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Work packages
  environment.systemPackages = with pkgs; [
    buf
    docker
    docker-compose
    imagemagick
    podman
    postgresql
    yarn
  ];

  # ============================================================
  # PostgreSQL — runs as a user launchd agent so it auto-starts
  # on login and restarts if it crashes. On first run, initdb
  # bootstraps the data dir; socket lives in /tmp by default.
  # ============================================================
  launchd.user.agents.postgresql = {
    serviceConfig = {
      ProgramArguments = [ "${pgStart}" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
    };
  };

  environment.shellAliases = {
    pg-stop = "launchctl bootout gui/$(id -u)/org.nixos.postgresql";
    pg-start = "launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.postgresql.plist";
    pg-log = "tail -f /tmp/postgresql.stderr.log";
  };
}

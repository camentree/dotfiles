# ============================================================
# Apple Silicon Mac — personal laptop
# ============================================================
{ pkgs, ... }:

let
  postgres = pkgs.postgresql.withPackages (p: [ p.pgvector ]);

  postgresLauncher = pkgs.writeShellScript "postgres-launch" ''
    PGDATA=/Users/camen/.postgres
    [ -f "$PGDATA/PG_VERSION" ] || ${postgres}/bin/initdb -D "$PGDATA"
    if [ -f "$PGDATA/postmaster.pid" ] && \
       ! ps -p "$(head -1 "$PGDATA/postmaster.pid")" -o comm= | grep -q postgres; then
      rm -f "$PGDATA/postmaster.pid"
    fi
    exec ${postgres}/bin/postgres -D "$PGDATA"
  '';
in

{
  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.variables.NIX_MACHINE = "mac-arm-personal";

  # Personal packages
  environment.systemPackages = with pkgs; [
    cloudflared
    postgres
  ];

  # Data dir lives at ~/.postgres; bootstrap runs initdb on first launch.
  # Launcher clears a stale postmaster.pid (e.g. after an unclean shutdown)
  # only when no live postgres owns it — guards against the PID-reuse case.
  launchd.user.agents.postgresql = {
    command = "${postgresLauncher}";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
    };
  };

  home-manager.users.camen = { config, ... }: {
    home.file.".zshrc.local" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/dotfiles/home/locals/zshrc-local-personal";
      force = true;
    };
  };
}

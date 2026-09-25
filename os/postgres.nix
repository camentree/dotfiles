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
  environment.systemPackages = [ postgres ];

  # Data dir lives at ~/.postgres; bootstrap runs initdb on first launch.
  # Launcher clears a stale postmaster.pid (e.g. after an unclean shutdown)
  # only when no live postgres owns it — guards against the PID-reuse case.
  launchd.user.agents.postgresql = {
    serviceConfig = {
      # Named launcher so Login Items shows "postgresql" rather than "sh".
      ProgramArguments = [ "${pkgs.writeShellScriptBin "postgresql" "exec ${postgresLauncher}"}/bin/postgresql" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/postgresql.stdout.log";
      StandardErrorPath = "/tmp/postgresql.stderr.log";
    };
  };
}

# ============================================================
# Home server — services shared by every server machine.
# Hardware-specific bits (platform, hostname, network ports, pmset) live in
# machines/<name>.nix, which imports this.
# ============================================================
{ config, pkgs, lib, ... }:

let
  # The one machine that actually serves. Every server builds the same config,
  # but only this one runs the tunnel, apps, deploys, and jobs. Otherwise two
  # machines would fight over the Cloudflare tunnel and run every parallax job
  # twice. To cut over: change this, commit, and `nix-rebuild` on both machines.
  activeServer = "mac-arm-server";

  hostName = config.networking.hostName;
  isActiveServer = hostName == activeServer;

  # paths
  homeDirectory = "/Users/camen";
  projectsDirectory = "${homeDirectory}/Projects";

  oneOffsRoot = "${projectsDirectory}/one-offs";
  parallaxRoot = "${projectsDirectory}/parallax";
  todoRoot = "${projectsDirectory}/todo";
  homeAssistantRoot = "${projectsDirectory}/home-assistant";

  # environments
  systemPath = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  baseEnvironment = {
    PATH = systemPath;
    HOME = homeDirectory;
    USER = "camen";
  };

  # Routines shell out to `claude`: npm-installed on older machines, native
  # installer (~/.local/bin) on newer ones. Without it on PATH every routine
  # fails with "claude: command not found".
  parallaxEnvironment = baseEnvironment // {
    PATH = "${homeDirectory}/.local/bin:${homeDirectory}/.npm-global/bin:${systemPath}";
  };

  todoEnvironment = baseEnvironment // {
    PATH = "${pkgs.nodejs_24}/bin:${systemPath}";
    NODE_ENV = "production";
    DATABASE_URL = "postgres://localhost/parallax";
    PORT = "8790";
    API_URL = "http://127.0.0.1:8787/api/";
  };

  uv = "/run/current-system/sw/bin/uv";

  # failure alerts
  emailAddress = "tree.camen@gmail.com";
  smtpPasswordPath = "${homeDirectory}/.mail/password";

  msmtprc = pkgs.writeText "msmtprc" ''
    defaults
    tls on
    tls_trust_file ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    logfile /tmp/msmtp.log
    timeout 20

    account gmail
    host smtp.gmail.com
    port 587
    auth on
    from ${emailAddress}
    user ${emailAddress}
    passwordeval "cat ${smtpPasswordPath}"

    account default : gmail
  '';

  emailAlert = pkgs.writeShellScriptBin "email-alert" ''
    subject="$1"
    body="$2"
    [ -r ${smtpPasswordPath} ] || exit 0
    printf 'To: %s\nFrom: ${hostName} <%s>\nSubject: [${hostName}] %s\n\n%s\n' \
      "${emailAddress}" "${emailAddress}" "$subject" "$body" \
      | ${pkgs.msmtp}/bin/msmtp -C ${msmtprc} -t || true
  '';

  # nix-darwin's `command` runs every agent as `/bin/sh -c ...`, so System
  # Settings → Login Items lists them all as "sh". Launching through a script
  # named after the agent makes Login Items show that name instead.
  namedProgram = name: command:
    [ "${pkgs.writeShellScriptBin name "exec ${command}"}/bin/${name}" ];

  monitoredCommand = name: alertAfterFailures: command:
    "${pkgs.writeShellScript "${name}-monitored" ''
      output=$(mktemp)
      trap 'rm -f "$output"' EXIT
      failureCountFile=/tmp/${name}.failures
      ${command} > "$output" 2>&1
      status=$?
      cat "$output"
      if [ "$status" -eq 0 ]; then
        rm -f "$failureCountFile"
      else
        failureCount=$(( $(cat "$failureCountFile" 2>/dev/null || echo 0) + 1 ))
        echo "$failureCount" > "$failureCountFile"
        if [ "$failureCount" -eq ${toString alertAfterFailures} ]; then
          ${emailAlert}/bin/email-alert "${name} failed" "exit $status after $failureCount attempts
$(tail -c 8000 "$output")"
        fi
      fi
      exit "$status"
    ''}";

  # applications
  appDeploy = repository: pkgs.writeShellScript "deploy-${repository}" ''
    script=${projectsDirectory}/${repository}/scripts/deploy
    if [ ! -x "$script" ]; then
      echo "${repository}: $script is missing or not executable"
      exit 1
    fi
    exec "$script"
  '';
  deployAgent = repository: environment: {
    serviceConfig = {
      ProgramArguments = namedProgram "deploy-${repository}"
        (monitoredCommand "deploy-${repository}" 3 "${appDeploy repository}");
      RunAtLoad = true;
      StartInterval = 120;
      WorkingDirectory = "${projectsDirectory}/${repository}";
      StandardOutPath = "/tmp/deploy-${repository}.stdout.log";
      StandardErrorPath = "/tmp/deploy-${repository}.stderr.log";
      EnvironmentVariables = environment;
    };
  };

  parallaxService = name: {
    serviceConfig = {
      ProgramArguments = namedProgram "parallax-${name}" "${uv} run parallax serve ${name}";
      RunAtLoad = true;
      KeepAlive = true;
      WorkingDirectory = parallaxRoot;
      StandardOutPath = "/tmp/parallax-${name}.stdout.log";
      StandardErrorPath = "/tmp/parallax-${name}.stderr.log";
      EnvironmentVariables = parallaxEnvironment;
    };
  };

  # One nginx for both sites; cloudflared routes each hostname to its port.
  nginxConf = pkgs.writeText "nginx.conf" ''
    daemon off;
    worker_processes 1;
    pid /tmp/nginx.pid;
    error_log /tmp/nginx.error.log warn;
    events { worker_connections 64; }
    http {
      include ${pkgs.nginx}/conf/mime.types;
      types { application/manifest+json webmanifest; }
      default_type application/octet-stream;
      access_log off;
      client_body_temp_path /tmp/nginx-client;
      proxy_temp_path /tmp/nginx-proxy;
      fastcgi_temp_path /tmp/nginx-fastcgi;
      uwsgi_temp_path /tmp/nginx-uwsgi;
      scgi_temp_path /tmp/nginx-scgi;

      server {
        listen 127.0.0.1:8788;
        location /api/ { proxy_pass http://127.0.0.1:8787; }
        location /webhook/ { proxy_pass http://127.0.0.1:8787; }
        location /mcp {
          proxy_pass http://127.0.0.1:8000;
          proxy_http_version 1.1;
          proxy_set_header Host $host;
          proxy_set_header Connection "";
          proxy_buffering off;
          proxy_cache off;
          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        }
      }

      server {
        listen 127.0.0.1:8789;
        # cloudflared speaks plain http to us, so an absolute redirect would
        # send the browser from https back to http.
        absolute_redirect off;
        root ${oneOffsRoot};

        location ~ /\. { return 404; }
        location ~ \.md$ { return 404; }

        location = / { try_files /index.html =404; }

        # ^~ stops the project regex below from matching "api" as a project.
        location ^~ /api/ {
          proxy_pass http://127.0.0.1:8787;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
        }

        location ~ ^/(?<project>[^/.]+)$ { return 301 /$project/; }

        # index.html candidates come first: a bare directory candidate would
        # make try_files internally redirect to the same URI and loop.
        location ~ ^/(?<project>[^/.]+)(?<rest>/.*)$ {
          try_files /$project/dist''${rest}index.html /$project''${rest}index.html
                    /$project/dist$rest /$project$rest
                    /$project/dist/index.html /$project/index.html =404;
        }

        location / { try_files $uri =404; }
      }
    }
  '';
in
{
  imports = [ ./postgres.nix ];

  config = lib.mkMerge [
    {
      # ===== server =====

      environment.variables.ACTIVE_SERVER = activeServer;
      environment.variables.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      environment.variables.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

      environment.systemPackages = with pkgs; [
        cloudflared
        emailAlert
        google-cloud-sdk
        msmtp
        nginx
        ntfy-sh
        playwright-driver.browsers
      ];

      services.openssh.enable = true;

      environment.etc."ssh/sshd_config.d/200-no-password.conf".text = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
      '';

      home-manager.users.camen = {
        home.file.".terminfo" = {
          source = "${pkgs.ghostty-bin.terminfo}/share/terminfo";
          recursive = true;
        };
      };

      # ===== macos defaults =====

      system.defaults.screensaver.askForPassword = lib.mkForce false;
      system.defaults.loginwindow.autoLoginUser = "camen";
      system.defaults.CustomUserPreferences = {
        "com.apple.bird" = {
          optimize-storage = false;
        };
      };
      system.defaults.CustomSystemPreferences = {
        "/Library/Preferences/com.apple.SoftwareUpdate" = {
          ConfigDataInstall = true;
          CriticalUpdateInstall = true;
        };
      };
      system.defaults.SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;

      power = {
        sleep.display = "never";
        sleep.computer = "never";
        sleep.harddisk = "never";
        restartAfterFreeze = true;
      };

    }

    # Only on the active server (see activeServer above).
    (lib.mkIf isActiveServer {
      # ===== shared services =====

      # Reads tunnel config from ~/.cloudflared/config.yml (kept outside the repo).
      launchd.user.agents.cloudflared = {
        serviceConfig = {
          ProgramArguments = namedProgram "cloudflared" "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${homeDirectory}/.cloudflared/config.yml run";
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/cloudflared.stdout.log";
          StandardErrorPath = "/tmp/cloudflared.stderr.log";
        };
      };

      launchd.user.agents.nginx = {
        serviceConfig = {
          ProgramArguments = namedProgram "nginx" "${pkgs.nginx}/bin/nginx -c ${nginxConf} -e /tmp/nginx.error.log";
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/nginx.stdout.log";
          StandardErrorPath = "/tmp/nginx.stderr.log";
        };
      };

      launchd.daemons.home-assistant = {
        serviceConfig = {
          # Runs the repo's script directly (not via bash) so Login Items shows its name.
          # Stays a root daemon: as a user agent, macOS's Local Network privacy blocked
          # the HomeKit bridge's Bonjour broadcasts. KeepAlive.PathState below replaces
          # the old `test -x` guard by only starting it once the script exists.
          ProgramArguments = [ "${homeAssistantRoot}/scripts/home-assistant" ];
          KeepAlive = {
            PathState = {
              "${homeAssistantRoot}/scripts/home-assistant" = true;
            };
            NetworkState = true;
          };
          RunAtLoad = true;
          StandardOutPath = "/tmp/home-assistant.stdout.log";
          StandardErrorPath = "/tmp/home-assistant.stderr.log";
          WorkingDirectory = homeAssistantRoot;
          EnvironmentVariables = baseEnvironment;
        };
      };

      # ===== applications =====

      launchd.user.agents.parallax-mcp = parallaxService "mcp";
      launchd.user.agents.parallax-http = parallaxService "http";
      launchd.user.agents.parallax-ntfy = parallaxService "ntfy";

      launchd.user.agents.todo = {
        serviceConfig = {
          ProgramArguments = namedProgram "todo" "npm start";
          RunAtLoad = true;
          KeepAlive = true;
          WorkingDirectory = todoRoot;
          StandardOutPath = "/tmp/todo.stdout.log";
          StandardErrorPath = "/tmp/todo.stderr.log";
          EnvironmentVariables = todoEnvironment;
        };
      };

      # ===== deploys =====

      launchd.user.agents.deploy-one-offs = deployAgent "one-offs" baseEnvironment;
      launchd.user.agents.deploy-parallax = deployAgent "parallax" parallaxEnvironment;
      launchd.user.agents.deploy-todo = deployAgent "todo" todoEnvironment;

      # ===== scheduled jobs =====

      # Which parallax jobs exist and when each is due lives in the parallax repo;
      # this agent only asks once a minute what is due now.
      launchd.user.agents.parallax-jobs = {
        serviceConfig = {
          ProgramArguments = namedProgram "parallax-jobs" "${uv} run --env-file .env -- parallax jobs --due";
          RunAtLoad = true;
          StartInterval = 60;
          WorkingDirectory = parallaxRoot;
          StandardOutPath = "/tmp/parallax-jobs.stdout.log";
          StandardErrorPath = "/tmp/parallax-jobs.stderr.log";
          EnvironmentVariables = parallaxEnvironment;
        };
      };
    })
  ];
}

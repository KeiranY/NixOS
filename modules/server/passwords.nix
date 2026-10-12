{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.sops) secrets;

  # Common curl options for local API calls
  curlOpts = ["-sf" "--retry" "30" "--retry-delay" "5" "--retry-connrefused"];

  # Generate a password-set script for an Arr service
  arrPasswordScript = {
    service,
    port,
  }: let
    secretName = "${service}_password";
    secretPath = secrets.${secretName}.path;
  in
    pkgs.writeShellScript "${service}-set-password" ''
           set -euo pipefail
           BASE="http://localhost:${toString port}"
           PASSWORD="$(cat ${secretPath})"

           # Wait for API to be ready
           ${pkgs.curl}/bin/curl ${toString curlOpts} "$BASE/api/v3/system/status" > /dev/null

           # Try login with default credentials (admin/admin or no auth)
           LOGIN_RESPONSE=$(${pkgs.curl}/bin/curl -s -X POST "$BASE/api/v3/auth/login" \
             -H "Content-Type: application/json" \
             -d '{"username": "admin", "password": "admin"}' || true)

           if echo "$LOGIN_RESPONSE" | ${pkgs.jq}/bin/jq -e '.token' > /dev/null 2>&1; then
             TOKEN="$LOGIN_RESPONSE"
           else
             # Try without auth
             TOKEN=""
           fi

           # Change password via API
           ${pkgs.curl}/bin/curl -s -X POST "$BASE/api/v3/users" \
             -H "Content-Type: application/json" \
      -H "X-Api-Key: ${secretName}" \
             -d "{
               \"username\": \"admin\",
               \"password\": \"$PASSWORD\",
               \"config\": {
                 \"theme\": \"auto\",
                 \"language\": \"en\",
                 \"ui\": {
                   \"enableColorImpairedMode\": false,
                   \"fontSize\": \"medium\"
                 }
               }
             }" || echo "Warning: Could not set ${service} password via API"
    '';
in {
  # Sops secrets for service passwords
  sops.secrets = {
    qbittorrent_password.owner = "qbittorrent";
    sonarr_password.owner = "sonarr";
    radarr_password.owner = "radarr";
    lidarr_password.owner = "lidarr";
    readarr_password.owner = "readarr";
    bazarr_password.owner = "bazarr";
    home_assistant_password.owner = "hass";
    # prowlarr runs as root, use root group
    prowlarr_password.owner = "root";
  };

  # qBittorrent — password set via API on first boot
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8081;
  };

  # Arr services — native auth method
  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8082;
    settings.auth = {
      required = "Local";
      method = "Forms";
    };
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8083;
    settings.auth = {
      required = "Local";
      method = "Forms";
    };
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8084;
    settings.auth = {
      required = "Local";
      method = "Forms";
    };
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8085;
    settings.auth = {
      required = "Local";
      method = "Forms";
    };
  };
  services.readarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8086;
    settings.auth = {
      required = "Local";
      method = "Forms";
    };
  };
  services.bazarr = {
    enable = true;
    openFirewall = true;
    listenPort = 8087;
  };

  # Home Assistant
  services.home-assistant = {
    enable = true;
    configDir = "/var/lib/home-assistant";
    config = {
      default_config = {};
      http = {server_port = 8080;};
      mqtt = {
        broker = "localhost";
        port = 1883;
      };
      recorder = {
        db_url = "sqlite:////var/lib/home-assistant/home-assistant_v2.db";
      };
      lovelace = {mode = "yaml";};
    };
  };

  # Systemd oneshots to set passwords via API (idempotent)
  systemd.services = {
    # Arr password setup
    sonarr-password = {
      wantedBy = ["multi-user.target"];
      after = ["sonarr.service" "network-online.target"];
      requires = ["sonarr.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = arrPasswordScript {
          service = "sonarr";
          port = 8082;
        };
        RemainAfterExit = true;
      };
    };
    radarr-password = {
      wantedBy = ["multi-user.target"];
      after = ["radarr.service" "network-online.target"];
      requires = ["radarr.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = arrPasswordScript {
          service = "radarr";
          port = 8083;
        };
        RemainAfterExit = true;
      };
    };
    lidarr-password = {
      wantedBy = ["multi-user.target"];
      after = ["lidarr.service" "network-online.target"];
      requires = ["lidarr.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = arrPasswordScript {
          service = "lidarr";
          port = 8084;
        };
        RemainAfterExit = true;
      };
    };
    prowlarr-password = {
      wantedBy = ["multi-user.target"];
      after = ["prowlarr.service" "network-online.target"];
      requires = ["prowlarr.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = arrPasswordScript {
          service = "prowlarr";
          port = 8085;
        };
        RemainAfterExit = true;
      };
    };
    readarr-password = {
      wantedBy = ["multi-user.target"];
      after = ["readarr.service" "network-online.target"];
      requires = ["readarr.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = arrPasswordScript {
          service = "readarr";
          port = 8086;
        };
        RemainAfterExit = true;
      };
    };

    # qBittorrent password setup
    qbittorrent-password = {
      wantedBy = ["multi-user.target"];
      after = ["qbittorrent.service" "network-online.target"];
      requires = ["qbittorrent.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "qbittorrent-set-password" ''
          set -euo pipefail
          BASE="http://localhost:8081"
          PASSWORD="$(cat ${secrets.qbittorrent_password.path})"
          USERNAME="admin"

          # Wait for API
          ${pkgs.curl}/bin/curl ${toString curlOpts} "$BASE/api/v2/app/webapiVersion" > /dev/null

          # Login
          ${pkgs.curl}/bin/curl -s -c /tmp/qbit-cookies.txt -X POST "$BASE/api/v2/auth/login" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "username=$USERNAME&password=$PASSWORD" || true
        '';
        RemainAfterExit = true;
      };
    };

    # Home Assistant password setup
    home-assistant-password = {
      wantedBy = ["multi-user.target"];
      after = ["home-assistant.service" "network-online.target"];
      requires = ["home-assistant.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "home-assistant-set-password" ''
          set -euo pipefail
          BASE="http://localhost:8080"
          PASSWORD="$(cat ${secrets.home_assistant_password.path})"

          # Wait for HA to be ready
          ${pkgs.curl}/bin/curl ${toString curlOpts} "$BASE/" > /dev/null

          # Check if onboarding is needed
          ONBOARDING=$(${pkgs.curl}/bin/curl -s "$BASE/api/onboarding" || true)
          if echo "$ONBOARDING" | ${pkgs.jq}/bin/jq -e '.done' > /dev/null 2>&1; then
            echo "Home Assistant onboarding already completed"
            exit 0
          fi

          # Create admin user via onboarding API
          ${pkgs.curl}/bin/curl -s -X POST "$BASE/api/onboarding/users" \
            -H "Content-Type: application/json" \
            -d "{
              \"name\": \"Admin\",
              \"username\": \"admin\",
              \"password\": \"$PASSWORD\",
              \"language\": \"en\"
            }" || echo "Warning: Could not set Home Assistant password via API"
        '';
        RemainAfterExit = true;
      };
    };
  };
}

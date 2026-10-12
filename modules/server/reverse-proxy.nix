{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.reverse-proxy;
in {
  options.services.reverse-proxy = {
    enable = lib.mkEnableOption "reverse-proxy";

    httpPort = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = "HTTP port for redirect to HTTPS";
    };

    sslPort = lib.mkOption {
      type = lib.types.int;
      default = 443;
      description = "HTTPS port for the reverse proxy";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Main domain for the reverse proxy (e.g., example.com)";
    };

    router = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Mapping of subdomains to target URLs";
    };

    allowedLogin = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "JavaScript function string for allowed login check. Receives req, returns boolean.";
    };

    noLogin = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "JavaScript function string for paths that don't require login. Receives req, returns boolean.";
    };

    sslKeyPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to SSL private key file";
    };

    sslCertPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to SSL certificate file";
    };

    auth0 = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          secret = lib.mkOption {
            type = lib.types.str;
            description = "Auth0 client secret (should be from sops-nix)";
          };
          baseURL = lib.mkOption {
            type = lib.types.str;
            description = "Auth0 base URL (e.g., https://example.com:443)";
          };
          clientID = lib.mkOption {
            type = lib.types.str;
            description = "Auth0 client ID";
          };
          issuerBaseURL = lib.mkOption {
            type = lib.types.str;
            description = "Auth0 issuer base URL (e.g., https://example.auth0.com)";
          };
        };
      });
      default = null;
      description = "Auth0 configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Generate config.js at runtime
    systemd.tmpfiles.rules = [
      "d /run/reverse-proxy 0755 root root -"
    ];

    systemd.services.reverse-proxy = {
      enable = true;
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [cfg.sslKeyPath cfg.sslCertPath];
      serviceConfig = {
        ExecStart = "${pkgs.reverse-proxy}/bin/reverse-proxy";
        WorkingDirectory = "/run/reverse-proxy";
        Environment = [
          "NODE_ENV=production"
          "CONFIG_PATH=/run/reverse-proxy/config.js"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      # Generate config.js before start
      serviceConfig.ExecStartPre = ''
                mkdir -p /run/reverse-proxy
                cat > /run/reverse-proxy/config.js <<'EOF'
        module.exports = {
          httpPort: ${lib.generators.toString cfg.httpPort},
          sslPort: ${lib.generators.toString cfg.sslPort},
          domain: ${lib.generators.toString cfg.domain},
          router: ${lib.generators.toJavaScript cfg.router},
          allowedLogin: ${
          if cfg.allowedLogin != null
          then cfg.allowedLogin
          else "() => true"
        },
          noLogin: ${
          if cfg.noLogin != null
          then cfg.noLogin
          else "() => false"
        },
          sslKeyPath: ${lib.generators.toString cfg.sslKeyPath},
          sslCertPath: ${lib.generators.toString cfg.sslCertPath},
          auth0Secret: ${lib.generators.toString (
          if cfg.auth0 != null
          then cfg.auth0.secret
          else ""
        )},
          auth0BaseURL: ${lib.generators.toString (
          if cfg.auth0 != null
          then cfg.auth0.baseURL
          else ""
        )},
          auth0ClientID: ${lib.generators.toString (
          if cfg.auth0 != null
          then cfg.auth0.clientID
          else ""
        )},
          auth0IssuerBaseURL: ${lib.generators.toString (
          if cfg.auth0 != null
          then cfg.auth0.issuerBaseURL
          else ""
        )},
        };
        EOF
      '';
    };

    # Firewall
    networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.sslPort];

    # Ensure package is available
    environment.systemPackages = [pkgs.reverse-proxy];
  };
}

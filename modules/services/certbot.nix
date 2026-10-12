{ config, pkgs, lib, ... }:
let
  cfg = config.services.certbot;
in {
  options.services.certbot = {
    enable = lib.mkEnableOption "Certbot ACME client for TLS certificates";
    email = lib.mkOption {
      type = lib.types.str;
      default = "admin@example.com";
      description = "Email for Let's Encrypt registration";
    };
    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Domains to request certificates for";
    };
    webrootPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/www/certbot";
      description = "Webroot path for HTTP-01 challenge";
    };
    staging = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Let's Encrypt staging environment (for testing)";
    };
    renewTimer = lib.mkOption {
      type = lib.types.str;
      default = "0 */12 * * *";
      description = "Systemd timer schedule for renewal (cron format)";
    };
    preHook = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Command to run before renewal (e.g., stop nginx)";
    };
    postHook = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Command to run after renewal (e.g., start nginx)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create webroot directory
    systemd.tmpfiles.rules = [
      "d ${cfg.webrootPath} 0755 root root - -"
    ];

    # Certbot service for initial cert request and renewals
    systemd.services.certbot = {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.certbot}/bin/certbot certonly --webroot \
            --webroot-path ${cfg.webrootPath} \
            --email ${cfg.email} \
            --agree-tos --no-eff-email \
            ${lib.optionalString cfg.staging "--staging"} \
            ${lib.concatStringsSep " " (lib.map (d: "-d ${d}") cfg.domains)}
        '';
      } // lib.optionalAttrs (cfg.preHook != null) { serviceConfig.ExecStartPre = cfg.preHook; }
      // lib.optionalAttrs (cfg.postHook != null) { serviceConfig.ExecStartPost = cfg.postHook; };
    };

    # Systemd timer for automatic renewal
    systemd.timers.certbot-renew = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.renewTimer;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
    systemd.services.certbot-renew = {
      wantedBy = [ "timers.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          ${pkgs.certbot}/bin/certbot renew --webroot \
            --webroot-path ${cfg.webrootPath} \
            --quiet \
            ${lib.optionalString cfg.staging "--staging"} \
            ${lib.optionalString (cfg.preHook != null) "--pre-hook '${cfg.preHook}' "} \
            ${lib.optionalString (cfg.postHook != null) "--post-hook '${cfg.postHook}' "}
        '';
      };
    };

    # Nginx snippet for ACME challenge
    nginx = lib.mkIf (config.nginx ? enable && config.nginx.enable) {
      httpConfig = ''
        location /.well-known/acme-challenge/ {
          root ${cfg.webrootPath};
          default_type "text/plain";
        }
      '';
    };
  };
}
{ config, pkgs, lib, ... }:
let
  cfg = config.services.nextcloud;
in {
  options.services.nextcloud = {
    enable = lib.mkEnableOption "Nextcloud file sync and share";
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "nextcloud.local";
      description = "Nextcloud hostname (for trusted_domains)";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8080;
      description = "Nextcloud web UI port";
    };
    dbUser = lib.mkOption {
      type = lib.types.str;
      default = "nextcloud";
      description = "Database user";
    };
    dbName = lib.mkOption {
      type = lib.types.str;
      default = "nextcloud";
      description = "Database name";
    };
    dbPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Database password (from sops)";
    };
    adminUser = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "Admin username";
    };
    adminPassword = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Admin password (from sops)";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/nextcloud/data";
      description = "Nextcloud data directory";
    };
    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/etc/nextcloud";
      description = "Nextcloud config directory";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      authentication = lib.mkIf (cfg.dbPassword != null) ''
        local ${cfg.dbUser} trust
        host ${cfg.dbName} ${cfg.dbUser} 127.0.0.1/32 md5
      '' ''
        local all all peer
      '';
      ensureDatabases = [ cfg.dbName ];
      ensureUsers = [
        { name = cfg.dbUser; password = cfg.dbPassword; ensureDatabases = [ cfg.dbName ]; }
      ];
    };

    services.nextcloud = {
      enable = true;
      hostName = cfg.hostName;
      configDir = cfg.configDir;
      dataDir = cfg.dataDir;
      phpOptions = "memory_limit = 512M";
      settings = {
        trusted_domains = [ cfg.hostName "localhost" ];
        dbtype = "pgsql";
        dbname = cfg.dbName;
        dbuser = cfg.dbUser;
        dbpassword = cfg.dbPassword;
        dbhost = "localhost";
        default_phone_region = "GB";
        memcache.local = "\\OC\\Memcache\\APCu";
        memcache.distributed = "\\OC\\Memcache\\Redis";
        redis = [ { host = "localhost"; port = 6379; } ];
        maintenance_window_start = 1;
        loglevel = 2;
        overwrite.cli.url = "https://${cfg.hostName}";
        overwriteprotocol = "https";
        trusted_proxies = [ "127.0.0.1" ];
      };
    };

    services.redis = {
      enable = true;
      settings = {
        databases = 1;
        maxmemory = "256mb";
        maxmemory-policy = "allkeys-lru";
      };
    };

    # Systemd service for Nextcloud cron
    systemd.services.nextcloud-cron = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "nextcloud";
        ExecStart = "${pkgs.php83}/bin/php -f ${cfg.configDir}/cron.php";
        Restart = "always";
        RestartSec = "15m";
      };
      timerConfig = {
        OnCalendar = "*/15 * * * *";
        Persistent = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
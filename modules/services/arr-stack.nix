{ config, pkgs, lib, ... }:
let
  cfg = config.services.arrStack;
in {
  options.services.arrStack = {
    enable = lib.mkEnableOption "ARR stack (Sonarr, Radarr, Lidarr, Prowlarr, Readarr, Bazarr) + qBittorrent";
    networkInterface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "Network interface for VPN routing (if using VPN)";
    };
    vpnEnabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Route ARR stack traffic through VPN";
    };
    ports = {
      sonarr = lib.mkOption { type = lib.types.int; default = 8989; };
      radarr = lib.mkOption { type = lib.types.int; default = 7878; };
      lidarr = lib.mkOption { type = lib.types.int; default = 8686; };
      prowlarr = lib.mkOption { type = lib.types.int; default = 9696; };
      readarr = lib.mkOption { type = lib.types.int; default = 8787; };
      bazarr = lib.mkOption { type = lib.types.int; default = 6767; };
      qbittorrent = lib.mkOption { type = lib.types.int; default = 8081; };
      flaresolverr = lib.mkOption { type = lib.types.int; default = 8191; };
    };
    configBaseDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/arr-stack";
      description = "Base directory for ARR stack configs";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create system user for ARR stack
    users.users.arrstack = {
      isSystemUser = true;
      group = "arrstack";
      home = cfg.configBaseDir;
      description = "ARR stack service user";
    };
    users.groups.arrstack = {};

    # Base config directory
    systemd.tmpfiles.rules = [
      "d ${cfg.configBaseDir} 0755 arrstack arrstack - -"
    ];

    # Sonarr
    systemd.services.sonarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/sonarr";
        ExecStart = "${pkgs.sonarr}/bin/Sonarr -nobrowser -data=${cfg.configBaseDir}/sonarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Radarr
    systemd.services.radarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/radarr";
        ExecStart = "${pkgs.radarr}/bin/Radarr -nobrowser -data=${cfg.configBaseDir}/radarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Lidarr
    systemd.services.lidarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/lidarr";
        ExecStart = "${pkgs.lidarr}/bin/Lidarr -nobrowser -data=${cfg.configBaseDir}/lidarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Prowlarr
    systemd.services.prowlarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/prowlarr";
        ExecStart = "${pkgs.prowlarr}/bin/Prowlarr -nobrowser -data=${cfg.configBaseDir}/prowlarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Readarr
    systemd.services.readarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/readarr";
        ExecStart = "${pkgs.readarr}/bin/Readarr -nobrowser -data=${cfg.configBaseDir}/readarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Bazarr
    systemd.services.bazarr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/bazarr";
        ExecStart = "${pkgs.python311}/bin/python -m bazarr --config ${cfg.configBaseDir}/bazarr";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # qBittorrent-nox
    systemd.services.qbittorrent = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent-nox --webui-port=${toString cfg.ports.qbittorrent} --profile=${cfg.configBaseDir}/qbittorrent";
        Restart = "on-failure";
        RestartSec = 10;
        Environment = [ "HOME=${cfg.configBaseDir}/qbittorrent" ];
      };
    };

    # FlareSolverr (for Cloudflare bypass)
    systemd.services.flaresolverr = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "arrstack";
        Group = "arrstack";
        WorkingDirectory = "${cfg.configBaseDir}/flaresolverr";
        ExecStart = "${pkgs.flaresolverr}/bin/flaresolverr --port ${toString cfg.ports.flaresolverr}";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      cfg.ports.sonarr
      cfg.ports.radarr
      cfg.ports.lidarr
      cfg.ports.prowlarr
      cfg.ports.readarr
      cfg.ports.bazarr
      cfg.ports.qbittorrent
      cfg.ports.flaresolverr
    ];
  };
}
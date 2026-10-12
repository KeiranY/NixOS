{ config, pkgs, lib, ... }:
let
  cfg = config.services.jellyfin;
in {
  options.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";
    port = lib.mkOption {
      type = lib.types.int;
      default = 8096;
      description = "Jellyfin web UI port";
    };
    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/etc/jellyfin";
      description = "Jellyfin configuration directory";
    };
    cacheDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/cache/jellyfin";
      description = "Jellyfin cache directory";
    };
    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/jellyfin";
      description = "Jellyfin data directory";
    };
    mediaDirs = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Media library directories to mount";
    };
    hwAccel = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = "Hardware acceleration (auto, vaapi, nvenc, quicksync, none)";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.jellyfin = {
      isSystemUser = true;
      group = "jellyfin";
      home = cfg.configDir;
      description = "Jellyfin service user";
    };
    users.groups.jellyfin = {};

    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0755 jellyfin jellyfin - -"
      "d ${cfg.cacheDir} 0755 jellyfin jellyfin - -"
      "d ${cfg.dataDir} 0755 jellyfin jellyfin - -"
    ] ++ lib.map (d: "d ${d} 0755 jellyfin jellyfin - -") cfg.mediaDirs;

    # Jellyfin service
    systemd.services.jellyfin = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "jellyfin";
        Group = "jellyfin";
        WorkingDirectory = cfg.configDir;
        ExecStart = "${pkgs.jellyfin}/bin/jellyfin --config ${cfg.configDir} --cache ${cfg.cacheDir} --data ${cfg.dataDir}";
        Restart = "on-failure";
        RestartSec = 10;
        Environment = [
          "HOME=${cfg.configDir}"
          "JELLYFIN_CONFIG_DIR=${cfg.configDir}"
          "JELLYFIN_CACHE_DIR=${cfg.cacheDir}"
          "JELLYFIN_DATA_DIR=${cfg.dataDir}"
        ] ++ lib.optional (cfg.hwAccel == "vaapi") "LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri"
        ++ lib.optional (cfg.hwAccel == "vaapi") "LIBVA_DRIVER_NAME=iHD";
        SupplementaryGroups = [ "video" "render" ];
      };
    };

    # Hardware acceleration
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
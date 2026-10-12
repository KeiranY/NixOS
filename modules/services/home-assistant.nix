{ config, pkgs, lib, ... }:
let
  cfg = config.services.homeAssistant;
in {
  options.services.homeAssistant = {
    enable = lib.mkEnableOption "Home Assistant home automation hub";
    port = lib.mkOption {
      type = lib.types.int;
      default = 8123;
      description = "Home Assistant web UI port";
    };
    configDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/home-assistant";
      description = "Home Assistant configuration directory";
    };
    mqttHost = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
      description = "MQTT broker hostname";
    };
    mqttPort = lib.mkOption {
      type = lib.types.int;
      default = 1883;
      description = "MQTT broker port";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.homeassistant = {
      isSystemUser = true;
      group = "homeassistant";
      home = cfg.configDir;
      description = "Home Assistant service user";
    };

    users.groups.homeassistant = {};

    systemd.services.home-assistant = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "mosquitto.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = "homeassistant";
        Group = "homeassistant";
        WorkingDirectory = cfg.configDir;
        ExecStart = "${pkgs.python311Packages.homeassistant}/bin/hass --config ${cfg.configDir}";
        Restart = "on-failure";
        RestartSec = 10;
        Environment = [
          "HOME=${cfg.configDir}"
          "PYTHONPATH=${cfg.configDir}"
        ];
      };
    };

    # Create config directory with proper permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0755 homeassistant homeassistant - -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
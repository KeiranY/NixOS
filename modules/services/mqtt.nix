{ config, pkgs, lib, ... }:
let
  cfg = config.services.mqtt;
in {
  options.services.mqtt = {
    enable = lib.mkEnableOption "MQTT broker (Mosquitto) for home automation";
    port = lib.mkOption {
      type = lib.types.int;
      default = 1883;
      description = "MQTT listener port";
    };
    websocketPort = lib.mkOption {
      type = lib.types.int;
      default = 9001;
      description = "MQTT over WebSocket listener port";
    };
    allowAnonymous = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow anonymous connections (not recommended)";
    };
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to password file (generated from sops secret)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.mosquitto = {
      enable = true;
      extraConfig = ''
        listener ${toString cfg.port}
        protocol mqtt
        allow_anonymous ${if cfg.allowAnonymous then "true" else "false"}
        ${lib.optionalString (cfg.passwordFile != null) "password_file ${cfg.passwordFile}"}

        listener ${toString cfg.websocketPort}
        protocol websockets
        allow_anonymous ${if cfg.allowAnonymous then "true" else "false"}
        ${lib.optionalString (cfg.passwordFile != null) "password_file ${cfg.passwordFile}"}

        persistence true
        persistence_location /var/lib/mosquitto/
        log_dest file /var/log/mosquitto/mosquitto.log
        log_type all
        connection_messages true
      '';
    };

    networking.firewall.allowedTCPPorts = [ cfg.port cfg.websocketPort ];
  };
}
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Ensure hass user/group exist for sops secret ownership
  users.users.hass = {};
  users.groups.hass = {};

  # Sops secret for Home Assistant admin password
  sops.secrets."home_assistant_password" = {
    owner = "hass";
    group = "hass";
    mode = "0440";
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

  # Oneshot service: runs on EVERY boot to set password for user kcy
  systemd.services.home-assistant-set-password = {
    description = "Set Home Assistant password for user kcy";
    after = ["home-assistant.service"];
    wants = ["home-assistant.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "hass";
      Group = "hass";
      ExecStart = "${pkgs.home-assistant}/bin/hass --script auth --config '${config.services.home-assistant.configDir}' change_password kcy \"$(cat ${config.sops.secrets."home_assistant_password".path})\"";
    };
  };

  # Open firewall port for Home Assistant
  networking.firewall.allowedTCPPorts = [8080];
}

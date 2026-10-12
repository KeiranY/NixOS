{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [./multimedia.nix ./home-assistant.nix];

  # MQTT broker
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };

  # Download clients & utilities
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8081;
    serverConfig = {
      Preferences = {
        WebUI = {
          LocalHostAuth = false;
          BypassAuthenticationSubnet = "0.0.0.0/0";
        };
      };
    };
  };
  services.flaresolverr = {
    enable = true;
    openFirewall = true;
    port = 8088;
  };

  # ELK stack (disabled for now)
  # nixpkgs.config.permittedInsecurePackages = ["elasticsearch-7.17.27"];
  # services.elasticsearch = {
  #   enable = true;
  #   package = pkgs.elasticsearch;
  # };
  # services.logstash.enable = true;
  # services.filebeat.enable = true;

  # Open firewall ports (non-multimedia)
  # qBittorrent (8081) and FlareSolverr (8088) use openFirewall = true
  # Home Assistant (8080) and Mosquitto (1883) need manual firewall
  networking.firewall.allowedTCPPorts = [
    8080 # Home Assistant
    1883 # MQTT
  ];
}

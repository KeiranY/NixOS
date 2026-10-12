{
  config,
  pkgs,
  lib,
  ...
}: {
  # Home Assistant
  services.home-assistant = {
    enable = true;
    configDir = "/var/lib/home-assistant";
  };

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

  # ARR stack
  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.lidarr.enable = true;
  services.prowlarr.enable = true;
  services.readarr.enable = true;
  services.bazarr.enable = true;
  services.qbittorrent.enable = true;
  services.flaresolverr.enable = true;

  # ELK stack
  nixpkgs.config.permittedInsecurePackages = ["elasticsearch-7.17.27"];
  services.elasticsearch = {
    # enable = true;
    package = pkgs.elasticsearch;
  };

  # services.logstash.enable = true;
  # services.filebeat.enable = true;

  # Open firewall ports for ARR services and Home Assistant
  networking.firewall.allowedTCPPorts = [
    8123 # Home Assistant
    1883 # MQTT
    8989 # Sonarr
    7878 # Radarr
    8686 # Lidarr
    9696 # Prowlarr
    8787 # Readarr
    6767 # Bazarr
    8081 # qBittorrent
    8191 # FlareSolverr
    9200 # Elasticsearch
    5044 # Logstash
  ];
}

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
    config.http.server_port = 8080;
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
  services.sonarr = {
    enable = true;
    openFirewall = true;
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
  services.readarr = {
    enable = true;
    openFirewall = true;
  };
  services.bazarr = {
    enable = true;
    openFirewall = true;
  };
  services.qbittorrent = {
    enable = true;
    openFirewall = true;
  };
  services.flaresolverr.enable = true;

  # ELK stack (disabled for now)
  # nixpkgs.config.permittedInsecurePackages = ["elasticsearch-7.17.27"];
  # services.elasticsearch = {
  #   enable = true;
  #   package = pkgs.elasticsearch;
  # };
  # services.logstash.enable = true;
  # services.filebeat.enable = true;

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [
    8080 # Home Assistant
    1883 # MQTT
    8081 # qBittorrent
    8082 # Sonarr
    8083 # Radarr
    8084 # Lidarr
    8085 # Prowlarr
    8086 # Readarr
    8087 # Bazarr
    8088 # FlareSolverr
  ];
}

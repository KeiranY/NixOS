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
    settings.server.port = 8082;
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8083;
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8084;
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8085;
  };
  services.readarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8086;
  };
  services.bazarr = {
    enable = true;
    openFirewall = true;
    listenPort = 8087;
  };
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

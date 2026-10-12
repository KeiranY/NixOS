{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.sops) secrets;

  # Common curl options for local API calls
  curlOpts = ["-sf" "--retry" "30" "--retry-delay" "5" "--retry-connrefused"];
in {
  # Sops secrets for service passwords (kept for future use if auth is re-enabled)
  sops.secrets = {
    qbittorrent_password.owner = "qbittorrent";
    sonarr_password.owner = "sonarr";
    radarr_password.owner = "radarr";
    lidarr_password.owner = "lidarr";
    readarr_password.owner = "readarr";
    bazarr_password.owner = "bazarr";
    home_assistant_password.owner = "hass";
    # prowlarr runs as root, use root group
    prowlarr_password.owner = "root";
  };

  # Arr services — authentication disabled
  services.sonarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8082;
    settings.auth = {
      required = "None";
      method = "None";
    };
  };
  services.radarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8083;
    settings.auth = {
      required = "None";
      method = "None";
    };
  };
  services.lidarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8084;
    settings.auth = {
      required = "None";
      method = "None";
    };
  };
  services.prowlarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8085;
    settings.auth = {
      required = "None";
      method = "None";
    };
  };
  services.readarr = {
    enable = true;
    openFirewall = true;
    settings.server.port = 8086;
    settings.auth = {
      required = "None";
      method = "None";
    };
  };
  services.bazarr = {
    enable = true;
    openFirewall = true;
    listenPort = 8087;
  };
  services.flaresolverr = {
    enable = true;
    port = 8088;
  };
}

{
  config,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/laptop.nix
    ../../modules/server/ssh.nix
    ../../modules/server/fail2ban.nix
    ../../modules/server/laptop-hardware.nix
    ../../modules/server/services.nix
    ../../modules/server/home-assistant.nix
    ../../modules/server/reverse-proxy.nix
  ];

  networking.hostName = hostname;
  system.stateVersion = "26.05";

  # UEFI + systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Secrets shared by all hosts (wifi PSK). See secrets/common.yaml.
  sops.defaultSopsFile = ../../secrets/common.yaml;
  # Host-specific secrets
  sops.secrets = {
    "jellyfin/admin_password".sopsFile = ../../secrets/nix-server.yaml;
    "jellyfin/cosmo_password".sopsFile = ../../secrets/nix-server.yaml;
    "jellyfin/bazarr_apikey".sopsFile = ../../secrets/nix-server.yaml;
    "home_assistant_password".sopsFile = ../../secrets/nix-server.yaml;
    # Reverse proxy Auth0 secret
    "auth0_secret".sopsFile = ../../secrets/nix-server.yaml;
  };

  # MOTD with vulnerability monitoring
  motd.enable = true;
  flakeClone.enable = true;

  # Reverse proxy configuration
  services.reverse-proxy = {
    enable = true;
    domain = "keirany.com";
    httpPort = 80;
    sslPort = 443;
    router = {
      "home.keirany.com" = "http://127.0.0.1:8123";
      "radarr.keirany.com" = "http://127.0.0.1:7878";
    };
    allowedLogin = "req => req.oidc.user.email === 'kayceewye@gmail.com'";
    noLogin = "() => false";
    sslKeyPath = "/var/lib/acme/keirany.com/key.pem";
    sslCertPath = "/var/lib/acme/keirany.com/fullchain.pem";
    auth0 = {
      secretPath = config.sops.secrets.auth0_secret.path;
      baseURL = "https://keirany.com:443";
      clientID = "E2S4dvDNBv8OR0js7rDkAAmDOTIJAwAV";
      issuerBaseURL = "https://dev-t6ks-b1e.eu.auth0.com";
    };
  };
}

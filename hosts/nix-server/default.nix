{hostname, ...}: {
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
  };

  # MOTD with vulnerability monitoring
  motd.enable = true;
  flakeClone.enable = true;

  # Reverse proxy configuration (enable and configure as needed)
  # services.reverse-proxy = {
  #   enable = true;
  #   domain = "example.com";
  #   httpPort = 80;
  #   sslPort = 443;
  #   router = {
  #     "app.example.com" = "http://127.0.0.1:8080";
  #     "api.example.com" = "http://127.0.0.1:3000";
  #   };
  #   allowedLogin = "req => req.oidc.user.email.endsWith('@example.com')";
  #   noLogin = "req => req.hostname === 'public.example.com'";
  #   sslKeyPath = "/etc/letsencrypt/live/example.com/privkey.pem";
  #   sslCertPath = "/etc/letsencrypt/live/example.com/fullchain.pem";
  #   auth0 = {
  #     secret = config.sops.secrets.reverse-proxy.auth0.secret;
  #     baseURL = "https://example.com:443";
  #     clientID = "your-auth0-client-id";
  #     issuerBaseURL = "https://your-tenant.auth0.com";
  #   };
  # };

  # Add reverse-proxy auth0 secret to sops.secrets:
  # sops.secrets = {
  #   "reverse-proxy/auth0/secret".sopsFile = ../../secrets/nix-server.yaml;
  # };
}

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
}

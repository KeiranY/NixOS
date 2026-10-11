{ hostname, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hardware/laptop.nix
  ];

  networking.hostName = hostname;
  system.stateVersion = "26.05";

  # UEFI + systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Secrets shared by all hosts (wifi PSK). See secrets/common.yaml.
  sops.defaultSopsFile = ../../secrets/common.yaml;
  # Host-specific secrets go in secrets/nix-laptop.yaml, e.g.:
  # sops.secrets."something".sopsFile = ../../secrets/nix-laptop.yaml;

  # MOTD with vulnerability monitoring
  motd.enable = true;
}

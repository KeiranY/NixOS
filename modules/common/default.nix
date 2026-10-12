# Imported by EVERY host. Keep this host-agnostic.
{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ./nix-settings.nix
    ./locale.nix
    ./secrets.nix
    ./network.nix
    ./git.nix
    ./github.nix
    ./mdns.nix
    ./smartd.nix
    ./fstrim.nix
    ./static-ip.nix
    ./motd.nix
    ./flake-clone.nix
  ];

  nixpkgs.config.allowUnfree = true;
}

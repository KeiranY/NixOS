# Imported by EVERY host. Keep this host-agnostic.
{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ./nix-settings.nix
    ./locale.nix
    ./sops.nix
    ./network.nix
    ./git.nix
    ./gh.nix
  ];

  nixpkgs.config.allowUnfree = true;
}

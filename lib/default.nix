# Shared library used by every host in flake.nix.
#
# `mkHost` assembles a NixOS system from the common module set, the shared
# user, the per-host directory (default.nix + hardware-configuration.nix),
# and any host-specific modules passed in via `extraModules`.
{inputs}: let
  inherit (inputs.nixpkgs) lib;
in {
  mkHost = {
    hostname,
    system ? "x86_64-linux",
    extraModules ? [],
    pkgs ? null,
  }:
    lib.nixosSystem {
      inherit system;
      # Make the flake inputs and the hostname available to every module.
      specialArgs = {inherit inputs hostname;};
      modules =
        [
          ../modules/common
          ../users/kcy
          (../hosts + "/${hostname}")
        ]
        ++ extraModules
        ++ (
          if pkgs != null
          then [
            ({config, ...}: {
              nixpkgs.overlays = [pkgs];
            })
          ]
          else []
        );
    };
}

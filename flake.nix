{
  description = "NixOS fleet: nix-laptop (GNOME desktop) and nix-server (headless, SSH).";

  inputs = {
    # Current stable. Bump deliberately and run `nix flake update` when ready.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Uncomment once you know the exact laptop model, to pull in hardware quirks:
    # nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      lib = import ./lib { inherit inputs; };
      systems = [ "x86_64-linux" ];
    in
    {
      nixosConfigurations = {
        nix-laptop = lib.mkHost {
          hostname = "nix-laptop";
          extraModules = [ ./modules/desktop ];
        };

        nix-server = lib.mkHost {
          hostname = "nix-server";
          extraModules = [ ./modules/server ];
        };
      };

      formatter = nixpkgs.lib.genAttrs systems
        (system: nixpkgs.legacyPackages.${system}.alejandra);

      # `nix develop` gives you the tooling needed to edit secrets from any
      # machine that has Nix (sops + age + a formatter).
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [ sops age ssh-to-age alejandra gh openssh ];
            shellHook = ''
              # Keep commits working on a fresh machine that has no git identity.
              export GIT_AUTHOR_NAME="''${GIT_AUTHOR_NAME:-KeiranY}"
              export GIT_AUTHOR_EMAIL="''${GIT_AUTHOR_EMAIL:-kcyoung1997@hotmail.co.uk}"
              export GIT_COMMITTER_NAME="''${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
              export GIT_COMMITTER_EMAIL="''${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"
            '';
          };
        });
    };
}

{ pkgs, ... }:
{
  users.users.kcy = {
    isNormalUser = true;
    description = "kcy";
    shell = pkgs.bash;
    extraGroups = [ "wheel" ];

    # CHANGE THIS after first login with `passwd`. To avoid a plaintext
    # password entirely, delete this line and set
    # `hashedPasswordFile = config.sops.secrets."kcy_password".path;` instead.
    initialPassword = "changeme";

    openssh.authorizedKeys.keys = [
      # Replace with your own public key(s), e.g. the contents of ~/.ssh/id_ed25519.pub
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtOX/2bahK0V54raPwYQLInQUyfHWJhOZ1J6mj2J5ye keiran@DESKTOP-FA16C1M"
    ];
  };

  # Home Manager runs as a NixOS module and shares the system nixpkgs.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.kcy = import ./home.nix;
  };
}

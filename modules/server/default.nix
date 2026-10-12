# Server modules - import individually as needed
{...}: {
  imports = [
    ./ssh.nix
    ./fail2ban.nix
    ./laptop-hardware.nix
    ./services.nix
    ./reverse-proxy.nix
    ./acme.nix
  ];
}

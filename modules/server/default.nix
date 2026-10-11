# Headless server bundle: SSH access only, no graphical stack.
{ ... }:
{
  imports = [
    ./ssh.nix
  ];

  networking.firewall.enable = true;
}

{ config, pkgs, lib, ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      workstation = true;
      addresses = true;
      hinfo = true;
    };
    extraConfig = ''
      [server]
      disallow-other-stacks=no
    '';
  };

  networking.firewall.allowedTCPPorts = [ 5353 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];
}
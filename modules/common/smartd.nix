{ config, pkgs, lib, ... }:
{
  services.smartd = {
    enable = true;
    pollInterval = "30m";
    extraConfig = ''
      DEVICESCAN -d removable -n standby -a -m kcy
    '';
  };
}
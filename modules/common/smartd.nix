{ config, pkgs, lib, ... }:
{
  services.smartd = {
    enable = true;
    pollInterval = "30m";
    extraOptions = "-d removable -n standby -a -m kcy";
    devices = [
      { device = "-a"; }
    ];
  };
}
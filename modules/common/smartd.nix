{ config, pkgs, lib, ... }:
{
  services.smartd = {
    enable = true;
    extraOptions = "-i 1800 -d removable -n standby -a -m kcy";
    devices = [
      { device = "-a"; }
    ];
  };
}
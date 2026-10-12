{ config, pkgs, lib, ... }:
{
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
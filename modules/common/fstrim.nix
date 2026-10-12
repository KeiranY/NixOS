{ config, pkgs, lib, ... }:
{
  services.fstrim = {
    enable = true;
    cronSchedule = "weekly";
  };
}
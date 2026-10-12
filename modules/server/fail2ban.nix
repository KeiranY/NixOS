{ config, pkgs, lib, ... }:
{
  services.fail2ban = {
    enable = true;
    bantime = "1h";
  };
}
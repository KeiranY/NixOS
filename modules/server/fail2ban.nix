{ config, pkgs, lib, ... }:
{
  services.fail2ban = {
    enable = true;
    jails.sshd = {
      enabled = true;
      maxretry = 3;
      bantime = "1h";
      findtime = "10m";
    };
  };
}
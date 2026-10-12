{ config, pkgs, lib, ... }:
{
  # Disable sleep/suspend on lid close for server
  systemd.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    handleLidSwitch = "ignore";
    handleLidSwitchDocked = "ignore";
  };

  # Also disable suspend/hibernate targets
  systemd.targets = {
    sleep.target.masked = true;
    suspend.target.masked = true;
    hibernate.target.masked = true;
    hybrid-sleep.target.masked = true;
  };
}
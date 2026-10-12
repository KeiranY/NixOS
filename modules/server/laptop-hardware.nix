{ config, pkgs, lib, ... }:
{
  # Disable sleep/suspend on lid close for server
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    handleSuspendKey = "ignore";
  };

  # Also disable suspend/hibernate targets
  systemd.targets = {
    sleep.target.masked = true;
    suspend.target.masked = true;
    hibernate.target.masked = true;
    hybrid-sleep.target.masked = true;
  };
}
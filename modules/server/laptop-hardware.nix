{ config, pkgs, lib, ... }:
{
  # Disable sleep/suspend on lid close for server
  services.logind.settings.login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleSuspendKey = "ignore";
    HandlePowerKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  # Also disable suspend/hibernate targets
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
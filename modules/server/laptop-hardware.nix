{ config, pkgs, lib, ... }:
{
  # Disable sleep/suspend on lid close for server
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
    suspendKey = "ignore";
    powerKey = "ignore";
    hibernateKey = "ignore";
  };

  # Also disable suspend/hibernate targets
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
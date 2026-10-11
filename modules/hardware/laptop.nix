# Hardware support for a physical laptop.
{ ... }:
{
  # Power / thermals / input.
  services.upower.enable = true;
  services.thermald.enable = true;
  services.libinput.enable = true;
  powerManagement.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}

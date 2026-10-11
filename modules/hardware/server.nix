# Hardware support for the server.
#
# Currently identical to laptop.nix because this "server" is temporarily a
# laptop. When it moves onto real server hardware, replace the contents here
# (e.g. drop bluetooth/power management, add storage/RAID specifics).
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

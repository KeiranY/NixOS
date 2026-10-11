{ pkgs, ... }:
{
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Trim some default GNOME apps; add anything you want back via
  # home-manager.users.kcy.home.packages (see the block below).
  environment.gnome.excludePackages = with pkgs; [
    cheese
    gnome-connections
    gnome-tour
  ];

  # User-level GNOME tweaks, applied via Home Manager.
  home-manager.users.kcy = {
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
      };
    };

    home.packages = with pkgs; [
      firefox
    ];
  };
}

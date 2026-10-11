# Base Home Manager config for kcy, applied on every host. Desktop-only
# additions live in modules/desktop/gnome.nix.
{ pkgs, ... }:
{
  home.username = "kcy";
  home.homeDirectory = "/home/kcy";
  home.stateVersion = "26.05";

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    jq
    htop
  ];
}

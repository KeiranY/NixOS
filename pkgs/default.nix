{
  system ? "x86_64-linux",
  pkgs ? import <nixpkgs> {inherit system;},
}: self: super: {
  reverse-proxy = super.callPackage ./reverse-proxy {inherit (super) nodePackages;};
}

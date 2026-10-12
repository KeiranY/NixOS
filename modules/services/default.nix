# Service modules - only custom modules without nixpkgs equivalents
{...}: {
  imports = [
    ./reverse-proxy.nix
  ];
}

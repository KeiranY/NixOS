# Service modules - import individually as needed
{ ... }:
{
  imports = [
    ./mqtt.nix
    ./home-assistant.nix
    ./nextcloud.nix
    ./arr-stack.nix
    ./certbot.nix
    ./reverse-proxy.nix
    ./elk.nix
  ];
}
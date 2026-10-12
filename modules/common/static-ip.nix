{ config, pkgs, lib, ... }:
{
  # Static IP configuration - override per host in hosts/<host>/default.nix
  # Example:
  # networking.interfaces.eth0 = {
  #   ipv4.addresses = [{ address = "192.168.1.10"; prefixLength = 24; }];
  #   ipv4.routes = [{ address = "0.0.0.0"; prefixLength = 0; via = "192.168.1.1"; }];
  # };
  # networking.nameservers = [ "192.168.1.1" "1.1.1.1" ];

  # For WiFi static IP, use NetworkManager:
  # networking.networkmanager.ensureProfiles.profiles."static-wifi" = {
  #   connection = { id = "static-wifi"; type = "wifi"; autoconnect = true; };
  #   wifi = { ssid = "The Subwoofer"; };
  #   wifi-security = { key-mgmt = "wpa-psk"; psk = config.sops.secrets."wifi_psk".value; };
  #   ipv4.method = "manual";
  #   ipv4.addresses = [{ address = "192.168.1.10"; prefixLength = 24; }];
  #   ipv4.gateway = "192.168.1.1";
  #   ipv4.dns = [ "192.168.1.1" "1.1.1.1" ];
  # };
}
{ config, ... }:
{
  networking.networkmanager.enable = true;

  # Let the primary user manage network connections.
  users.users.kcy.extraGroups = [ "networkmanager" ];

  # The PSK is pulled from the sops-encrypted secret at activation, so no
  # plaintext wifi password is ever committed.
  sops.secrets."wifi_psk" = { };

  sops.templates."wifi.env".content = ''
    WIFI_PSK=${config.sops.placeholder."wifi_psk"}
  '';

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.templates."wifi.env".path ];

    profiles."the-subwoofer" = {
      connection = {
        id = "The Subwoofer";
        type = "wifi";
        autoconnect = true;
      };
      wifi = {
        ssid = "The Subwoofer";
        mode = "infrastructure";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$WIFI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };
}

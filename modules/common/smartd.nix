{
  config,
  pkgs,
  lib,
  ...
}: let
  smartdNotify = pkgs.writeShellScript "smartd-notify" ''
    #!/usr/bin/env bash
    # smartd -M exec script: writes alerts to /etc/motd.d/smartd-alerts
    # smartd passes the alert message as $1
    ALERT=''${1:-"smartd alert (no message provided)"}
    OUT_FILE="/etc/motd.d/smartd-alerts"
    mkdir -p "$(dirname "$OUT_FILE")"
    echo "⚠ $ALERT" >> "$OUT_FILE"
    # Keep only last 50 alerts
    tail -50 "$OUT_FILE" > "$OUT_FILE.tmp" && mv "$OUT_FILE.tmp" "$OUT_FILE"
  '';
in {
  services.smartd = {
    enable = true;
    extraOptions = [
      "-i 1800"
      "-d removable"
      "-n standby"

      "-M exec ${smartdNotify}"
    ];
    devices = [
      {device = "/dev/sda";}
    ];
  };
}

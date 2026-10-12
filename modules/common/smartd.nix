{
  config,
  pkgs,
  lib,
  ...
}: let
  smartctlCheck = pkgs.writeShellScript "smartctl-check" ''
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="/run/current-system/sw/bin:${pkgs.coreutils}/bin:${pkgs.smartmontools}/bin:$PATH"
    OUT_FILE="/etc/motd.d/smartd-alerts"
    mkdir -p "$(dirname "$OUT_FILE")"
    {
      echo "💾 Disk Health (smartctl — $(date -u +"%Y-%m-%d %H:%M UTC"))"
      echo ""
      if command -v smartctl >/dev/null 2>&1; then
        for disk in /dev/sda /dev/nvme0n1; do
          if [[ -b "$disk" ]]; then
            echo "=== $disk ==="
            ${pkgs.smartmontools}/bin/smartctl -H "$disk" 2>/dev/null || echo "smartctl failed for $disk"
            echo ""
          fi
        done
      else
        echo "smartctl not installed"
      fi
    } > "$OUT_FILE.tmp"
    cat "$OUT_FILE.tmp" >> "$OUT_FILE"
    tail -100 "$OUT_FILE" > "$OUT_FILE.trim" && mv "$OUT_FILE.trim" "$OUT_FILE"
  '';
in {
  services.smartd = {
    enable = true;
    extraOptions = ["-i 1800"];
    devices = [
      {device = "/dev/sda";}
    ];
  };

  systemd.timers.smartctl-motd = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 06:00:00";
      Persistent = true;
    };
  };
  systemd.services.smartctl-motd = {
    wantedBy = ["timers.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${smartctlCheck}";
    };
  };
}

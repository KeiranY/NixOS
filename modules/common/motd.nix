{ config, pkgs, lib, hostname, ... }:
let
  cfg = config.motd;
  motdGenerate = pkgs.writeShellScriptBin "motd-generate" ''
    #!/usr/bin/env bash
    set -euo pipefail
    OUT_DIR="/etc/motd.d"
    mkdir -p "$OUT_DIR"
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M UTC")
    HOST=$(hostname)

    # Box drawing chars
    if [[ "${cfg.useAscii}" == "true" ]]; then
      TL="+"; TR="+"; BL="+"; BR="+"; H="-"; V="|"; T="+"; B="+"; L="+"; R="+"; TL2="+"; TR2="+"
    else
      TL="┌"; TR="┐"; BL="└"; BR="┘"; H="─"; V="│"; T="┬"; B="┴"; L="├"; R="┤"; TL2="├"; TR2="┤"
    fi

    # --- Vulnix section ---
    VULN_FILE="$OUT_DIR/vuln"
    if command -v vulnix >/dev/null; then
      vulnix --system --json 2>/dev/null | jq -r '
        .[] | select(.affected) |
        "\(.package.name)-\(.package.version) → \(.fixedVersion // "unfixed") [\(.cves // [] | join(", "))]"
      ' > "$VULN_FILE.tmp" 2>/dev/null || echo "vulnix scan failed" > "$VULN_FILE.tmp"
      mv "$VULN_FILE.tmp" "$VULN_FILE"
    else
      echo "vulnix not installed" > "$VULN_FILE"
    fi

    # --- Flake updates section ---
    UPDATE_FILE="$OUT_DIR/updates"
    FLAKE_PATH="${cfg.flakePath}"
    if [[ -d "$FLAKE_PATH/.git" ]]; then
      cd "$FLAKE_PATH"
      nix flake update --dry-run 2>&1 |
        awk '/would be updated|updating/ {print}' |
        head -20 > "$UPDATE_FILE.tmp" 2>/dev/null || echo "flake update check failed" > "$UPDATE_FILE.tmp"
      mv "$UPDATE_FILE.tmp" "$UPDATE_FILE"
    else
      echo "flake not found at $FLAKE_PATH" > "$UPDATE_FILE"
    fi

    # --- Combined summary ---
    SUMMARY_FILE="$OUT_DIR/summary"
    {
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" \
        "$TL" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$TR"
      printf "%s                            %s — MOTD                                 %s\n" "$V" "$HOST" "$V"
      printf "%s                         Generated: %s                      %s\n" "$V" "$TIMESTAMP" "$V"
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" \
        "$TL2" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$TR2"
      printf "%s  ⚠ VULNERABILITIES (vulnix — %s)                                    %s\n" "$V" "$(date -u +"%Y-%m-%d")" "$V"
      printf "%s  %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s  %s\n" "$V" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$V"
      if [[ -s "$VULN_FILE" ]] && ! grep -q "failed\|not installed" "$VULN_FILE"; then
        while IFS= read -r line; do
          printf "%s  %s  %s\n" "$V" "$line" "$V"
        done < "$VULN_FILE"
        VULN_COUNT=$(wc -l < "$VULN_FILE")
        UNFIXED=$(grep -c "unfixed" "$VULN_FILE" || true)
        printf "%s                                                                              %s\n" "$V" "$V"
        printf "%s  %d vulnerable packages  •  %d unfixed  •  Run: nixos-rebuild switch          %s\n" "$V" "$VULN_COUNT" "$UNFIXED" "$V"
      else
        printf "%s  ✅ No known vulnerabilities (vulnix)                                        %s\n" "$V" "$V"
      fi
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" \
        "$TL2" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$TR2"
      printf "%s  📦 PENDING UPDATES (nix flake update --dry-run — %s)                %s\n" "$V" "$(date -u +"%Y-%m-%d")" "$V"
      printf "%s  %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s  %s\n" "$V" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$V"
      if [[ -s "$UPDATE_FILE" ]] && ! grep -q "failed\|not found" "$UPDATE_FILE"; then
        while IFS= read -r line; do
          printf "%s  %s  %s\n" "$V" "$line" "$V"
        done < "$UPDATE_FILE"
        SEC_COUNT=$(grep -c "security" "$UPDATE_FILE" || true)
        printf "%s                                                                              %s\n" "$V" "$V"
        printf "%s  %d security updates available  •  Run: nix flake update && rebuild          %s\n" "$V" "$SEC_COUNT" "$V"
      else
        printf "%s  ✅ Flake inputs up to date                                                  %s\n" "$V" "$V"
      fi
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" \
        "$TL2" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$TR2"
      printf "%s  💡 RECOMMENDATIONS                                                            %s\n" "$V" "$V"
      printf "%s  %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s  %s\n" "$V" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$V"
      printf "%s  [1] Rebuild now:  sudo nixos-rebuild switch --flake .#%s            %s\n" "$V" "$HOST" "$V"
      printf "%s  [2] Update flake: nix flake update (pulls security fixes)                   %s\n" "$V" "$V"
      if [[ -s "$VULN_FILE" ]] && grep -q "unfixed" "$VULN_FILE"; then
        printf "%s  [3] Review unfixed CVEs — monitor for backport                              %s\n" "$V" "$V"
      fi
      printf "%s                                                                              %s\n" "$V" "$V"
      LAST_REBUILD=$(nixos-version 2>/dev/null | head -1 || echo "unknown")
      UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
      LOAD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo "? ? ?")
      printf "%s  Last rebuild: %s  •  Uptime: %s  •  Load: %s    %s\n" "$V" "$LAST_REBUILD" "$UPTIME" "$LOAD" "$V"
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n" \
        "$BL" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$H" "$BR"
    } > "$SUMMARY_FILE.tmp"
    mv "$SUMMARY_FILE.tmp" "$SUMMARY_FILE"
  '';
in {
  options.motd = {
    enable = lib.mkEnableOption "MOTD with vulnerability + update monitoring";
    flakePath = lib.mkOption {
      type = lib.types.path;
      default = "/etc/nixos";
      description = "Path to flake for nix flake update --dry-run";
    };
    flakeRepo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/KeiranY/NixOS.git";
      description = "Repository to clone for flake updates check";
    };
    flakeBranch = lib.mkOption {
      type = lib.types.str;
      default = "master";
      description = "Branch to clone";
    };
    useAscii = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use ASCII box drawing instead of Unicode";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.vulnix pkgs.jq pkgs.coreutils pkgs.gawk pkgs.git motdGenerate ];

    environment.etc."motd.d".source = pkgs.runCommand "motd-d" {} ''
      mkdir -p $out
      touch $out/.keep
    '';

    systemd.timers.motd-update = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily *-*-* 06:00:00";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
    systemd.services.motd-update = {
      wantedBy = [ "timers.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${motdGenerate}/bin/motd-generate";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
    };

    systemd.services.motd-update-boot = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${motdGenerate}/bin/motd-generate";
        After = [ "network-online.target" ];
      };
    };
  };
}
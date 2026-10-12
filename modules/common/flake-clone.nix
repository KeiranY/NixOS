{ config, pkgs, lib, hostname, ... }:
let
  cfg = config.flakeClone;
  cloneScript = pkgs.writeShellScript "flake-clone" ''
    if [[ ! -d /etc/nixos/.git ]]; then
      ${pkgs.git}/bin/git clone --branch "${cfg.flakeBranch}" "${cfg.flakeRepo}" /etc/nixos
    fi
  '';
in {
  options.flakeClone = {
    enable = lib.mkEnableOption "Auto-clone flake repo to /etc/nixos on first boot";
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
  };

  config = lib.mkIf cfg.enable {
    systemd.services.flake-clone = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = [ "-${pkgs.coreutils}/bin/mkdir -p /etc/nixos" ];
        ExecStart = "${cloneScript}";
        ConditionPathExists = "!/etc/nixos/.git";
      };
    };
  };
}
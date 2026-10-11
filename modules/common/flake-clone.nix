{ config, pkgs, lib, hostname, ... }:
let
  cfg = config.motd;
in {
  config = lib.mkIf cfg.enable {
    systemd.services.flake-clone = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = [ "-${pkgs.coreutils}/bin/mkdir -p /etc/nixos" ];
        ExecStart = ''
          if [[ ! -d /etc/nixos/.git ]]; then
            ${pkgs.git}/bin/git clone --branch "${cfg.flakeBranch}" "${cfg.flakeRepo}" /etc/nixos
          fi
        '';
        Before = [ "motd-update-boot.service" ];
        ConditionPathExists = "!/etc/nixos/.git";
      };
    };
  };
}
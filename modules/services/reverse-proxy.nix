{ config, pkgs, lib, ... }:
let
  cfg = config.services.reverseProxy;
  cloneScript = pkgs.writeShellScript "reverse-proxy-clone" ''
    if [[ ! -d ${cfg.installDir}/.git ]]; then
      ${pkgs.git}/bin/git clone --branch ${cfg.branch} ${cfg.repo} ${cfg.installDir}
    else
      cd ${cfg.installDir} && ${pkgs.git}/bin/git pull origin ${cfg.branch}
    fi
  '';
  buildScript = pkgs.writeShellScript "reverse-proxy-build" ''
    # Auto-detect build system
    if [[ -f go.mod ]]; then
      ${pkgs.go}/bin/go build -o reverse-proxy .
    elif [[ -f Cargo.toml ]]; then
      ${pkgs.rust}/bin/cargo build --release
      cp target/release/reverse-proxy ${cfg.installDir}/reverse-proxy
    elif [[ -f package.json ]]; then
      ${pkgs.nodejs}/bin/npm ci && ${pkgs.nodejs}/bin/npm run build
    elif [[ -f Makefile ]]; then
      make
    fi
  '';
in {
  options.services.reverseProxy = {
    enable = lib.mkEnableOption "Custom reverse proxy (from https://github.com/KeiranY/reverse-proxy)";
    repo = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/KeiranY/reverse-proxy";
      description = "Repository URL for the reverse proxy";
    };
    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to deploy";
    };
    installDir = lib.mkOption {
      type = lib.types.path;
      default = "/opt/reverse-proxy";
      description = "Installation directory";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8080;
      description = "Reverse proxy listening port";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to config file (can be generated from sops)";
    };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables for the proxy";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create install directory
    systemd.tmpfiles.rules = [
      "d ${cfg.installDir} 0755 root root - -"
    ];

    # Clone/update service
    systemd.services.reverse-proxy-clone = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${cloneScript}";
      };
    };

    # Build service (assuming it's a Go/Rust/Node project with a build step)
    systemd.services.reverse-proxy-build = {
      wantedBy = [ "multi-user.target" ];
      after = [ "reverse-proxy-clone.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = cfg.installDir;
        ExecStart = "${buildScript}";
      };
    };

    # Main reverse proxy service
    systemd.services.reverse-proxy = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "reverse-proxy-build.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = cfg.installDir;
        ExecStart = "${cfg.installDir}/reverse-proxy";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "PORT=${toString cfg.port}"
        ] ++ lib.mapAttrsToList (k: v: "${k}=${v}") cfg.environment
        ++ lib.optionalAttrs (cfg.configFile != null) { CONFIG_FILE = cfg.configFile; };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
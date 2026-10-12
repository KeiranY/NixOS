{ config, pkgs, lib, ... }:
let
  cfg = config.services.elk;
in {
  options.services.elk = {
    enable = lib.mkEnableOption "ELK stack (Elasticsearch, Logstash, Kibana) for centralized logging";
    elasticsearch = {
      enable = lib.mkOption { type = lib.types.bool; default = true; };
      port = lib.mkOption { type = lib.types.int; default = 9200; };
      heapSize = lib.mkOption { type = lib.types.str; default = "1g"; };
      dataDir = lib.mkOption { type = lib.types.path; default = "/var/lib/elasticsearch"; };
    };
    logstash = {
      enable = lib.mkOption { type = lib.types.bool; default = true; };
      port = lib.mkOption { type = lib.types.int; default = 5044; };
      httpPort = lib.mkOption { type = lib.types.int; default = 9600; };
      heapSize = lib.mkOption { type = lib.types.str; default = "512m"; };
      configDir = lib.mkOption { type = lib.types.path; default = "/etc/logstash"; };
    };
    kibana = {
      enable = lib.mkOption { type = lib.types.bool; default = true; };
      port = lib.mkOption { type = lib.types.int; default = 5601; };
      host = lib.mkOption { type = lib.types.str; default = "0.0.0.0"; };
      elasticsearchUrl = lib.mkOption { type = lib.types.str; default = "http://localhost:9200"; };
    };
    filebeat = {
      enable = lib.mkOption { type = lib.types.bool; default = true; };
      configDir = lib.mkOption { type = lib.types.path; default = "/etc/filebeat"; };
      logPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "/var/log/syslog"
          "/var/log/auth.log"
          "/var/log/kern.log"
          "/var/log/nginx/*.log"
          "/var/log/journal/*"
        ];
        description = "Log file paths to ship";
      };
      elasticsearchUrl = lib.mkOption { type = lib.types.str; default = "http://localhost:9200"; };
    };
  };

  config = lib.mkIf cfg.enable {
    # Elasticsearch
    config = lib.mkIf cfg.elasticsearch.enable {
      services.elasticsearch = {
        enable = true;
        package = pkgs.elasticsearch;
        settings = {
          network.host = "0.0.0.0";
          http.port = cfg.elasticsearch.port;
          cluster.name = "nixos-elk";
          node.name = "${config.networking.hostName}-es";
          path.data = cfg.elasticsearch.dataDir;
          path.logs = "/var/log/elasticsearch";
          discovery.type = "single-node";
          xpack.security.enabled = false;
        };
        jvmOptions = [
          "-Xms${cfg.elasticsearch.heapSize}"
          "-Xmx${cfg.elasticsearch.heapSize}"
        ];
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.elasticsearch.dataDir} 0750 elasticsearch elasticsearch - -"
        "d /var/log/elasticsearch 0750 elasticsearch elasticsearch - -"
      ];

      networking.firewall.allowedTCPPorts = [ cfg.elasticsearch.port ];
    };

    # Logstash
    config = lib.mkIf cfg.logstash.enable {
      users.users.logstash = {
        isSystemUser = true;
        group = "logstash";
        home = cfg.logstash.configDir;
      };
      users.groups.logstash = {};

      systemd.tmpfiles.rules = [
        "d ${cfg.logstash.configDir} 0755 logstash logstash - -"
        "d /var/log/logstash 0755 logstash logstash - -"
      ];

      # Logstash pipeline config
      environment.etc."logstash/pipelines.yml".text = ''
        - pipeline.id: main
          path.config: "${cfg.logstash.configDir}/pipelines/main.conf"
      '';

      environment.etc."logstash/pipelines/main.conf".text = ''
        input {
          beats {
            port => ${toString cfg.logstash.port}
          }
          syslog {
            port => 514
          }
        }
        filter {
          if [fields][service] {
            mutate { add_field => { "service" => "%{[fields][service]}" } }
          }
          if [message] =~ /^%{TIMESTAMP_ISO8601}/ {
            date { match => ["message", "ISO8601"] }
          }
        }
        output {
          elasticsearch {
            hosts => ["http://localhost:${toString cfg.elasticsearch.port}"]
            index => "logs-%{+YYYY.MM.dd}"
          }
          stdout { codec => rubydebug }
        }
      '';

      systemd.services.logstash = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "elasticsearch.service" ];
        serviceConfig = {
          Type = "simple";
          User = "logstash";
          Group = "logstash";
          ExecStart = "${pkgs.logstash}/bin/logstash --path.settings ${cfg.logstash.configDir}";
          Restart = "on-failure";
          RestartSec = 10;
          Environment = [
            "LS_JAVA_OPTS=-Xms${cfg.logstash.heapSize} -Xmx${cfg.logstash.heapSize}"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.logstash.port cfg.logstash.httpPort ];
    };

    # Kibana
    config = lib.mkIf cfg.kibana.enable {
      services.kibana = {
        enable = true;
        package = pkgs.kibana;
        settings = {
          server.port = cfg.kibana.port;
          server.host = cfg.kibana.host;
          elasticsearch.hosts = [ cfg.kibana.elasticsearchUrl ];
          kibana.index = ".kibana";
        };
      };

      networking.firewall.allowedTCPPorts = [ cfg.kibana.port ];
    };

    # Filebeat
    config = lib.mkIf cfg.filebeat.enable {
      users.users.filebeat = {
        isSystemUser = true;
        group = "filebeat";
        home = cfg.filebeat.configDir;
      };
      users.groups.filebeat = {};

      systemd.tmpfiles.rules = [
        "d ${cfg.filebeat.configDir} 0755 filebeat filebeat - -"
        "d /var/log/filebeat 0755 filebeat filebeat - -"
      ];

      environment.etc."filebeat/filebeat.yml".text = ''
        filebeat.inputs:
        - type: log
          enabled: true
          paths:
${lib.concatStringsSep "\n" (lib.map (p: "            - ${p}") cfg.filebeat.logPaths)}
          fields:
            service: system
          fields_under_root: true
        - type: log
          enabled: true
          paths:
            - /var/log/nginx/access.log
            - /var/log/nginx/error.log
          fields:
            service: nginx
          fields_under_root: true
        - type: log
          enabled: true
          paths:
            - /var/log/ssh/sshd.log
          fields:
            service: ssh
          fields_under_root: true

        filebeat.config.modules:
          path: ${cfg.filebeat.configDir}/modules.d/*.yml
          reload.enabled: true

        output.elasticsearch:
          hosts: ["${cfg.filebeat.elasticsearchUrl}"]
          index: "filebeat-%{+YYYY.MM.dd}"

        processors:
          - add_host_metadata: ~
          - add_cloud_metadata: ~
          - add_docker_metadata: ~

        logging.level: info
        logging.to_files: true
        logging.files:
          path: /var/log/filebeat
          name: filebeat
          keepfiles: 7
          permissions: 0644
      '';

      systemd.services.filebeat = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "elasticsearch.service" ];
        serviceConfig = {
          Type = "simple";
          User = "filebeat";
          Group = "filebeat";
          ExecStart = "${pkgs.filebeat}/bin/filebeat -c ${cfg.filebeat.configDir}/filebeat.yml -path.home ${cfg.filebeat.configDir} -path.config ${cfg.filebeat.configDir} -path.data ${cfg.filebeat.configDir}/data -path.logs /var/log/filebeat";
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };
  };
}
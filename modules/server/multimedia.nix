{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Helper: generate Arr service configs with common pattern
  mkArrService = {
    name,
    port,
    extraSettings ? {},
  }: {
    enable = true;
    openFirewall = true;
    settings = {server.port = port;} // extraSettings;
  };

  # Helper: services that need media group (prowlarr doesn't access media files directly)
  mediaServices = ["jellyfin" "sonarr" "radarr" "lidarr" "readarr" "bazarr"];
in {
  # Import declarative-jellyfin module
  imports = [inputs.declarative-jellyfin.nixosModules.default];

  # Media group for shared media access
  users.groups.media = {gid = 1000;};

  # Add all media services to media group
  users.users = lib.genAttrs mediaServices (name: {extraGroups = ["media"];});

  # Media directory structure (declarative via systemd-tmpfiles)
  systemd.tmpfiles.rules = [
    "d /data/media 0775 root media - -"
    "d /data/media/movies 0775 root media - -"
    "d /data/media/shows 0775 root media - -"
    "d /data/media/music 0775 root media - -"
    "d /data/media/books 0775 root media - -"
    "d /data/media/downloads 0775 root media - -"
  ];

  # Jellyfin Media Server (declarative)
  services.declarative-jellyfin = {
    enable = true;
    openFirewall = true;

    # Hardware acceleration (Intel Quick Sync / QSV)
    encoding = {
      enableHardwareEncoding = true;
      hardwareAccelerationType = "qsv";
      hardwareDecodingCodecs = [
        "h264"
        "hevc"
        "mpeg2video"
        "vc1"
        "vp8"
        "vp9"
        "av1"
      ];
    };

    # Users
    users = {
      kcy = {
        mutable = false;
        permissions.isAdministrator = true;
        hashedPasswordFile = config.sops.secrets."jellyfin/admin_password".path;
      };
      cosmo = {
        mutable = false;
        permissions.isAdministrator = false;
        hashedPasswordFile = config.sops.secrets."jellyfin/cosmo_password".path;
      };
    };

    # Libraries
    libraries = {
      Movies = {
        enabled = true;
        contentType = "movies";
        pathInfos = ["/data/media/movies"];
        subtitleFetcherOrder = ["Bazarr+ Subtitles" "subbuzz"];
        saveSubtitlesWithMedia = true;
        allowEmbeddedSubtitles = "AllowAll";
      };
      Shows = {
        enabled = true;
        contentType = "tvshows";
        pathInfos = ["/data/media/shows"];
        subtitleFetcherOrder = ["Bazarr+ Subtitles" "subbuzz"];
        saveSubtitlesWithMedia = true;
        allowEmbeddedSubtitles = "AllowAll";
      };
      Music = {
        enabled = true;
        contentType = "music";
        pathInfos = ["/data/media/music"];
      };
      Books = {
        enabled = true;
        contentType = "books";
        pathInfos = ["/data/media/books"];
      };
    };

    # Plugin repositories
    plugins = {
      "Bazarr+ Subtitles" = {
        enable = true;
        url = "https://LavX.github.io/jellyfin-plugin-bazarr-plus/manifest.json";
        hash = "sha256-<pinned-hash>";
      };
      SubBuzz = {
        enable = true;
        url = "https://raw.githubusercontent.com/josdion/subbuzz/main/repo/jellyfin_10.11.json";
        hash = "sha256-<pinned-hash>";
      };
    };

    # API keys for external services
    apikeys = {
      Bazarr = {keyPath = config.sops.secrets."jellyfin/bazarr_apikey".path;};
    };

    # System settings
    system = {
      libraryScanFanoutConcurrency = 4;
      libraryMetadataRefreshConcurrency = 4;
    };
  };

  # ARR stack (DRY via helper)
  services.sonarr = mkArrService {
    name = "sonarr";
    port = 8082;
  };
  services.radarr = mkArrService {
    name = "radarr";
    port = 8083;
  };
  services.lidarr = mkArrService {
    name = "lidarr";
    port = 8084;
  };
  services.readarr = mkArrService {
    name = "readarr";
    port = 8086;
  };
  services.prowlarr = mkArrService {
    name = "prowlarr";
    port = 8085;
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
    listenPort = 8087;
  };

  # Bazarr -> Jellyfin integration (via Dynaconf env vars, since settings option not in 26.05)
  # Create environment file with secrets for Bazarr
  systemd.services.bazarr-env = {
    description = "Generate Bazarr environment file with Jellyfin secrets";
    wantedBy = ["bazarr.service"];
    before = ["bazarr.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/mkdir -p /run/bazarr && printf \"DYNACONF_jellyfin__enable=true\\nDYNACONF_jellyfin__url=http://localhost:8096\\nDYNACONF_jellyfin__apikey=$(cat ${config.sops.secrets.\"jellyfin/bazarr_apikey\".path})\\nDYNACONF_jellyfin__refresh_method=Immediate\\nDYNACONF_jellyfin__movie_library=Movies\\nDYNACONF_jellyfin__series_library=Shows\\nDYNACONF_jellyfin__update_movie_library=true\\nDYNACONF_jellyfin__update_series_library=true\\n\" > /run/bazarr/env'";
      User = "root";
    };
  };

  systemd.services.bazarr = {
    serviceConfig = {
      EnvironmentFile = "/run/bazarr/env";
      EnvironmentFileIgnoreMissing = false;
    };
    after = ["bazarr-env.service"];
    wants = ["bazarr-env.service"];
  };

  # Open firewall ports NOT covered by openFirewall:
  # - Jellyfin HTTPS (8920) - not exposed by declarative-jellyfin's openFirewall
  # - Jellyfin discovery UDP (1900, 7359)
  # - Jellyfin default port (8096) - openFirewall should open it but be explicit
  networking.firewall.allowedTCPPorts = [8920]; # Jellyfin HTTPS
  networking.firewall.allowedUDPPorts = [1900 7359]; # Jellyfin discovery
}

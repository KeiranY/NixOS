{
  config,
  pkgs,
  lib,
  ...
}: let
  domain = "keirany.com";
in {
  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "porkbun";
      environmentFile = config.sops.templates."acme_env".path;
      credentialFiles = {
        "PORKBUN_API_KEY_FILE" = "/run/secrets/porkbun_papi_key";
        "PORKBUN_SECRET_API_KEY_FILE" = "/run/secrets/porkbun_secret_api_key";
      };
    };
    certs = {
      "${domain}" = {
        domain = domain;
        extraDomainNames = ["*.${domain}"];
      };
    };
  };

  sops.templates."acme_env" = {
    content = ''
      ACME_EMAIL=${config.sops.placeholder."acme_email"}
      PORKBUN_PAPI_KEY=${config.sops.placeholder."porkbun_papi_key"}
      PORKBUN_SECRET_API_KEY=${config.sops.placeholder."porkbun_secret_api_key"}
    '';
    mode = "0400";
    owner = "root";
    group = "root";
  };

  sops.secrets = {
    "acme_email" = {
      sopsFile = ../../secrets/nix-server.yaml;
      mode = "0400";
      owner = "root";
      group = "root";
    };
    "porkbun_papi_key" = {
      sopsFile = ../../secrets/nix-server.yaml;
      mode = "0400";
      owner = "root";
      group = "root";
    };
    "porkbun_secret_api_key" = {
      sopsFile = ../../secrets/nix-server.yaml;
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };
}

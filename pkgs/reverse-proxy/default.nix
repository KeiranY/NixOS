{pkgs}:
pkgs.buildNpmPackage {
  pname = "reverse-proxy";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "KeiranY";
    repo = "reverse-proxy";
    rev = "master";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
}

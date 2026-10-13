{pkgs}:
pkgs.buildNpmPackage {
  pname = "reverse-proxy";
  version = "1.0.0";
  src = ./.;
  packageLock = ./package-lock.json;
}

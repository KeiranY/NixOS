{pkgs}:
pkgs.buildNpmPackage {
  pname = "reverse-proxy";
  version = "1.0.0";
  src = ./.;
  packageLock = ./package-lock.json;
  npmDepsHash = "sha256-q0tBC+T7d5FjW5b7aGPZnaDZkqtGeNMVn/MLbVBrQsk=";
}

{pkgs}:
pkgs.buildNpmPackage {
  pname = "reverse-proxy";
  version = "1.0.0";
  src = ./.;
  packageLock = ./package-lock.json;
  npmDepsHash = "sha256-q0tBC+T7d5FjW5b7aGPZnaDZkqtGeNMVn/MLbVBrQsk=";
  dontNpmBuild = true;
  postInstall = ''
        mkdir -p $out/bin
        cat > $out/bin/reverse-proxy <<'EOF'
    #!/usr/bin/env sh
    exec ${pkgs.nodejs}/bin/node $out/index.js "$@"
    EOF
        chmod +x $out/bin/reverse-proxy
  '';
}

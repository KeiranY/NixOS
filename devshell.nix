{ pkgs, ... }:
pkgs.mkShell {
  name = "nixos-fleet-dev";
  packages = with pkgs; [
    sops
    age
    ssh-to-age
    alejandra
    gh
    openssh
    nil
  ];
  shellHook = ''
    # Keep commits working on a fresh machine that has no git identity.
    export GIT_AUTHOR_NAME="''${GIT_AUTHOR_NAME:-KeiranY}"
    export GIT_AUTHOR_EMAIL="''${GIT_AUTHOR_EMAIL:-kcyoung1997@hotmail.co.uk}"
    export GIT_COMMITTER_NAME="''${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
    export GIT_COMMITTER_EMAIL="''${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"
  '';
}
{ pkgs ? import <nixpkgs> { }, ... }:
pkgs.mkShell {
  name = "nixos-fleet-dev";
  packages = with pkgs; [
    # NixOS rebuild and deployment
    nixos-rebuild
    # Nix tooling
    nix-tree
    nix-output-monitor
    nixfmt
    # Secret management
    sops
    age
    ssh-to-age
    # LSP and formatting
    alejandra
    nil
    # Version control
    gh
    git
    # Utilities
    jq
    curl
    ripgrep
    fd
    htop
    tmux
    direnv
    nix-direnv
    openssh
  ];
  shellHook = ''
    # Keep commits working on a fresh machine that has no git identity.
    export GIT_AUTHOR_NAME="''${GIT_AUTHOR_NAME:-KeiranY}"
    export GIT_AUTHOR_EMAIL="''${GIT_AUTHOR_EMAIL:-kcyoung1997@hotmail.co.uk}"
    export GIT_COMMITTER_NAME="''${GIT_COMMITTER_NAME:-$GIT_AUTHOR_NAME}"
    export GIT_COMMITTER_EMAIL="''${GIT_COMMITTER_EMAIL:-$GIT_AUTHOR_EMAIL}"
    git config core.hooksPath .githooks
  '';
}

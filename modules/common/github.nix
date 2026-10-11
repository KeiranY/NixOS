# GitHub CLI, pre-authenticated from a sops-managed token.
#
# The token lives as the `gh_token` key in secrets/common.yaml. It is exposed
# to interactive shells as GH_TOKEN, and gh doubles as git's credential helper
# for GitHub over HTTPS (so `git push` works with no prompt).
{ pkgs, config, ... }:
{
  environment.systemPackages = [ pkgs.gh ];

  sops.secrets."gh_token" = {
    owner = "kcy";
    group = "users";
    mode = "0440";
  };

  programs.git.config.credential."https://github.com".helper =
    "!${pkgs.gh}/bin/gh auth git-credential";

  programs.bash.interactiveShellInit = ''
    if [ -r ${config.sops.secrets."gh_token".path} ]; then
      export GH_TOKEN="$(cat ${config.sops.secrets."gh_token".path})"
    fi
  '';
}

{ ... }:
{
  programs.git = {
    enable = true;
    config = {
      user.name = "KeiranY";
      user.email = "kcyoung1997@hotmail.co.uk";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Trust GitHub's host key so `git push` over SSH doesn't prompt.
  programs.ssh.knownHosts.github = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };
}

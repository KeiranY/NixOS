{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      # Key-only authentication; no passwords over the network.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}

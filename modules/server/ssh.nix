{
  config,
  pkgs,
  lib,
  ...
}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    ports = [22 9922];
    settings = {
      # Key-only authentication; no passwords over the network.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      # Additional hardening
      PubkeyAuthentication = true;
      AuthenticationMethods = "publickey";
      PermitEmptyPasswords = false;
      ChallengeResponseAuthentication = false;
      UsePAM = true;
      MaxAuthTries = 3;
      MaxSessions = 4;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
      LoginGraceTime = 30;
      PermitUserEnvironment = false;
      AllowAgentForwarding = false;
      AllowTcpForwarding = false;
      X11Forwarding = false;
      PrintMotd = false;
      PrintLastLog = true;
      TCPKeepAlive = false;
      Compression = "no";
    };
  };
}

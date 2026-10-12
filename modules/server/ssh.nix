{ config, pkgs, lib, ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
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
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256,hmac-sha2-512,umac-128@openssh.com";
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "diffie-hellman-group14-sha256"
      ];
      HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256";
    };
  };

  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    jails = {
      sshd = {
        enabled = true;
        filter = "sshd";
        settings = ''
          port = ssh
          logpath = /var/log/auth.log
          maxretry = 3
          bantime = 1h
          findtime = 10m
        '';
      };
    };
  };
}
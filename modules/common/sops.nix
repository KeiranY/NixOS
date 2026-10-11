# Common sops-nix wiring. Each host sets `sops.defaultSopsFile` to its own
# encrypted secrets file; individual secrets are declared where they are used
{ ... }:
{
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}

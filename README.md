# NixOS fleet

One flake manages two machines that share a common configuration library:

- **nix-laptop** — personal laptop running GNOME.
- **nix-server** — headless, SSH-only (currently running on laptop hardware, on wifi).

`nixpkgs` is pinned to stable `nixos-26.05`; `flake.lock` makes every host build
the exact same revision.

## Layout

```
flake.nix                 inputs + nixosConfigurations.<host>
lib/default.nix           mkHost helper shared by all hosts
modules/common/           imported by every host (nix, locale, sops, network)
modules/desktop/          GNOME (nix-laptop only)
modules/server/           hardened sshd (nix-server only)
modules/hardware/         laptop.nix / server.nix (identical for now)
users/kcy/                the kcy account + Home Manager config
hosts/<host>/             per-host wiring + hardware-configuration.nix
secrets/                  sops-encrypted secrets (committed)
keys/                     age private keys (gitignored — never committed)
```

## First-time setup

### 1. Tooling (WSL2 + Nix)

```bash
wsl --install -d Ubuntu            # from Windows, then reboot
# inside Ubuntu: enable systemd in /etc/wsl.conf ([boot] systemd=true), wsl --shutdown
curl -fsSL https://install.determinate.systems/nix | sh -s -- install   # flakes on by default
```

Work on a clone inside the Linux filesystem (building on `/mnt/c` is slow):

```bash
git clone <remote> ~/src/NixOS && cd ~/src/NixOS
nix develop          # provides sops, age, ssh-to-age, gh, openssh
```

### 1b. GitHub access (push)

GitHub no longer accepts account passwords over HTTPS. Pick one:

```bash
# Option A — SSH (recommended; works from the installed hosts too)
git remote set-url origin git@github.com:KeiranY/NixOS.git
ssh-keygen -t ed25519 -C "kcyoung1997@hotmail.co.uk"   # only if you have no key
cat ~/.ssh/id_ed25519.pub                               # add at https://github.com/settings/keys
ssh -T git@github.com                                   # expect "Hi KeiranY!"
git push

# Option B — GitHub CLI (HTTPS token stored in the credential helper)
gh auth login          # GitHub.com -> HTTPS -> authenticate in browser/device
gh auth setup-git
git push
```

### 2. Encrypt secrets

`secrets/common.yaml` holds the wifi PSK used by both hosts.

```bash
mkdir -p ~/.config/sops/age
cp keys/kcy.key ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt
$EDITOR secrets/common.yaml                          # set the real wifi_psk
sops --encrypt --in-place secrets/common.yaml        # .sops.yaml picks the recipients
sops --decrypt secrets/common.yaml                   # verify
```

Commit the encrypted file. Plaintext and `keys/` must never be committed.

### 3. Install a host

On the machine, boot the NixOS 26.05 ISO, partition UEFI + ext4, mount at `/mnt`
(with the ESP at `/mnt/boot`), then:

```bash
mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
git clone <remote> /root/nixos-config && cd /root/nixos-config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/<host>/hardware-configuration.nix
install -D -m600 /path/to/keys/<host>.key /mnt/var/lib/sops-nix/key.txt   # transfer via USB
git add -A
nixos-install --flake /root/nixos-config#<host>
```

First login uses password `changeme` — change it immediately with `passwd`.

## Day-to-day

```bash
# on the machine
sudo nixos-rebuild switch --flake .#nix-laptop

# remote deploy to the server
nixos-rebuild switch --flake .#nix-server --target-host kcy@nix-server --use-remote-sudo

# update all inputs together
nix flake update
```

## Notes

- Git identity is configured for all hosts in `modules/common/git.nix`
  (`programs.git`), and exported by the devShell so commits work before a host
  is installed.
- `hosts/<host>/hardware-configuration.nix` files are placeholders — replace each
  with the output of `nixos-generate-config` from that machine.
- `nixos-hardware` is commented out in `flake.nix`; enable it once the laptop model
  is known.
- When nix-server moves to real server hardware: edit `modules/hardware/server.nix`,
  optionally drop the wifi profile from `modules/common/network.nix`, and remove the
  server key from `secrets/common.yaml` recipients (`sops updatekeys`).
- Back up `keys/*.key` somewhere safe. `kcy.key` can decrypt every secret; losing it
  (with no other recipient) means the secrets are unrecoverable.

# os-setup

One repo, two targets. Dotfiles stay here and get symlinked into place, so editing
a file in this repo is the change.

| | macOS (ZuMac) | Ubuntu VPS |
|---|---|---|
| Tool | nix-darwin + home-manager | home-manager standalone |
| Config | `configuration.nix`, `home.nix` | `home-vps.nix` |
| Fresh machine | `./bootstrap.sh` | `git clone … ~/.os-setup && bash ~/.os-setup/ubuntu/vps/bootstrap.sh` |
| Apply changes | `sudo darwin-rebuild switch --flake ~/.os-setup#ZuMac` (`./rebuild.sh`, `zu rebuild`) | `nix run home-manager/release-26.05 -- switch --flake ~/.os-setup#vps` (`./ubuntu/vps/rebuild.sh`, `zu rebuild`) |
| System layer | nix-darwin modules, homebrew | `ubuntu/vps/system.sh` (sshd, ufw, fail2ban, apt) |

The VPS keeps its Ubuntu kernel, cloud-init and apt. Nix only manages the
userspace: the CLI tools, zsh, git, starship, and the symlinked dotfiles. Anything
that needs `/etc` or systemd stays in `ubuntu/vps/system.sh`, which is idempotent
and safe to re-run.

`ubuntu/vps/check.sh` asserts the box still matches the config. `ubuntu/gnome`,
`ubuntu/wsl` and `manjaro` are the old apt scripts, kept for desktop installs.

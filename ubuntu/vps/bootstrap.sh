#!/usr/bin/env bash
# Takes a fresh Ubuntu VPS (Hetzner, root-only, 24.04 x86_64) from nothing to a
# built Home Manager config. Run once, then use ./rebuild.sh (`zu rebuild`) for
# every later change.
#
#   git clone <this repo> ~/.os-setup && bash ~/.os-setup/ubuntu/vps/bootstrap.sh
#
# Ubuntu keeps its kernel, cloud-init and apt; Nix only manages the userspace
# config in home-vps.nix. The system bits home-manager cannot touch (sshd, ufw,
# apt, fail2ban) are in system.sh below.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

echo "==> Step 1: apt prerequisites"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get -y -qq install curl git ca-certificates

echo "==> Step 2: Determinate Nix"
if command -v nix >/dev/null 2>&1; then
  echo "    nix already installed, skipping"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install linux --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

echo "==> Step 3: symlink this repo to ~/.os-setup"
# home-vps.nix resolves its mkOutOfStoreSymlink paths through ~/.os-setup, so this
# has to exist before the first switch or the build will fail to find them.
# Skipped when the repo is already at ~/.os-setup, since ln cannot link a dir onto itself.
[ "$DIR" = "$HOME/.os-setup" ] || ln -sfn "$DIR" ~/.os-setup

echo "==> Step 4: personalize the configured username"
REAL_USER="$(whoami)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*vpsUser = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n1)"
if [ -z "$FLAKE_USER" ]; then
  echo "    Could not find the single \"vpsUser = \" line in flake.nix."
  echo "    Edit flake.nix yourself before continuing."
  exit 1
elif [ "$FLAKE_USER" != "$REAL_USER" ]; then
  echo "    flake.nix is configured for user \"$FLAKE_USER\", but you are \"$REAL_USER\"."
  read -r -p "    Rewrite flake.nix's \"vpsUser = \" line to \"$REAL_USER\"? [y/N] " REPLY
  if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
    # GNU sed: no '' argument after -i, unlike the mac bootstrap.sh.
    sed -i -E "s/^([[:space:]]*vpsUser = \")[^\"]+(\";.*)/\1${REAL_USER}\2/" "$DIR/flake.nix"
    echo "    Updated. Review the change with: git diff flake.nix"
  else
    echo "    Skipped. Edit the single \"vpsUser = \" line in flake.nix yourself before continuing."
    exit 1
  fi
else
  echo "    flake.nix already matches \"$REAL_USER\", nothing to do."
fi

echo "==> Step 5: system layer (sshd, ufw, fail2ban, unattended-upgrades)"
bash "$DIR/ubuntu/vps/system.sh"

echo "==> Step 6: first home-manager switch (pinned to home-manager release-26.05)"
# home-manager isn't installed yet on a fresh box, so run it straight from the
# flake this once. After this, rebuild.sh works normally.
nix run home-manager/release-26.05 -- switch --flake ~/.os-setup#vps

echo "==> Step 7: make zsh the login shell"
# home-manager on generic Linux does not touch /etc/shells or the user's shell,
# so do it here. The shell lives in the Nix profile, not /usr/bin.
ZSH_BIN="$HOME/.nix-profile/bin/zsh"
if [ ! -x "$ZSH_BIN" ]; then
  echo "    $ZSH_BIN missing - did the switch in step 6 succeed?"
  exit 1
fi
grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" >> /etc/shells
chsh -s "$ZSH_BIN" "$REAL_USER"

echo "==> Done. Use ./rebuild.sh (or \`zu rebuild\`) for future changes."
echo "    Reboot when convenient: apt may have a new kernel (check /var/run/reboot-required)."

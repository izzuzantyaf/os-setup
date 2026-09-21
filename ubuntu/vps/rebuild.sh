#!/usr/bin/env bash
# Applies home-vps.nix to this VPS. Run after any change to flake.nix,
# home-vps.nix or the dotfiles this repo symlinks in.
#   ./rebuild.sh            apply the locked config
#   ./rebuild.sh --update   bump flake inputs first, then apply
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
[ "$DIR" = "$HOME/.os-setup" ] || ln -sfn "$DIR" ~/.os-setup

if [ "${1:-}" = "--update" ]; then
  echo "==> Updating flake inputs..."
  nix flake update --flake ~/.os-setup
fi

echo "==> Switching home-manager config (vps)..."
exec nix run home-manager/release-26.05 -- switch --flake ~/.os-setup#vps

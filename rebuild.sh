#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.os-setup

echo "==> Rebuilding system configuration (requires sudo)..."
sudo darwin-rebuild switch --flake ~/.os-setup#ZuMac

echo "==> Checking and installing Mac App Store applications..."
apps=(
  "Tailscale:1475387142"
  "Bitwarden:1352778147"
  "WhatsApp:310633997"
  "Obsidian Web Clipper:6720708363"
  "MonitorControl Lite:1595464182"
  "CapCut:1500855883"
  "Speedtest by Ookla:1153157709"
  "Canva:897446215"
  "Telegram:747648890"
  "Hand Mirror:1502839586"
  "Amazon Kindle:302584613"
)

# Locate mas CLI
MAS_BIN="/opt/homebrew/bin/mas"
if [ ! -f "$MAS_BIN" ]; then
  MAS_BIN="/usr/local/bin/mas"
fi
if [ ! -f "$MAS_BIN" ]; then
  MAS_BIN=$(command -v mas || true)
fi

if [ -n "$MAS_BIN" ] && [ -x "$MAS_BIN" ]; then
  for app in "${apps[@]}"; do
    app_name=$(echo "$app" | cut -d: -f1)
    app_id=$(echo "$app" | cut -d: -f2)
    echo "Checking $app_name ($app_id)..."
    "$MAS_BIN" install "$app_id"
  done
else
  echo "Warning: mas CLI not found. Make sure Homebrew has finished installing it."
fi
